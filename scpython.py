#!/usr/bin/env python3
#  ASM-lite v2.2  –  Generador de código máquina ARM-like
#  ▸ Añadido soporte para SMUL / UMUL (multiply-long)     – v2.0
#  ▸ Añadido soporte para FADD / FMUL (punto flotante)   – v2.2

import re, sys, traceback

# ──────────────────────────────────────────────────────────────
# 1.  Expresiones regulares para tokenizar
# ──────────────────────────────────────────────────────────────
TOKEN_SPEC = {
    "LABEL":     r"[A-Za-z_][A-Za-z0-9_]*:",
    "REG":       r"R(?:1[0-5]|[0-9])",
    "POINTER":   r"[A-Za-z_][A-Za-z0-9_]*",
    "IMM":       r"#(?:0x[0-9a-fA-F]+|[0-9]+)",
    "COMMA":     r",",
    "S_COLON":   r";",
    "L_BRACKET": r"\[",
    "R_BRACKET": r"\]",
    "SPACE":     r"\s+",
    "COMMENT":   r"//.*",
    "UNKNOWN":   r".",
}

def reg_val(r: str) -> int:
    v = int(r[1:])
    if not (0 <= v <= 15):
        raise ValueError(f"Registro fuera de rango (0–15): {r}")
    return v

def imm_val(s: str, m: int = 255) -> int:
    v = int(s[1:], 0)
    if not (0 <= v <= m):
        raise ValueError(f"Inmediato fuera de rango (0–{m}): {s}")
    return v

# ──────────────────────────────────────────────────────────────
# 2.  Clase ensamblador
# ──────────────────────────────────────────────────────────────
class ARM_Assembler:
    def __init__(self) -> None:
        self.regex = re.compile(
            "|".join(f"(?P<{n}>{p})" for n, p in TOKEN_SPEC.items()),
            re.IGNORECASE,
        )

        # 2.1 Instrucciones DP estándar
        #     (cmd ⇒ campo bits[24:21])
        self.dp_instr = {
            "AND": 0b0000,
            "SUB": 0b0010,
            "ADD": 0b0100,
            "ORR": 0b1100,
            "MOV": 0b1101,
            "LSL": 0b1101,
            "LSR": 0b1101,
            "MUL": 0b0111,
            "DIV": 0b0001,
            # ───── NUEVO soporte FP ─────
            "FADD": 0b1000,
            "FMUL": 0b1000,
        }

        # 2.2 Campo cmd para multiply-long
        self.mul_long_cmd = {
            "SMUL": 0b110,   # signed   multiply long
            "UMUL": 0b101,   # unsigned multiply long
        }

        # 2.3 Memoria, saltos, condiciones
        self.mem_instr = {"STR": 0b00, "LDR": 0b01, "STRB": 0b10, "LDRB": 0b11}
        self.b_instr   = {"B": 0b0}
        self.conds = {
            "EQ": 0b0000, "NE": 0b0001, "CS": 0b0010, "HS": 0b0010,
            "CC": 0b0011, "LO": 0b0011, "MI": 0b0100, "PL": 0b0101,
            "VS": 0b0110, "VC": 0b0111, "HI": 0b1000, "LS": 0b1001,
            "GE": 0b1010, "LT": 0b1011, "GT": 0b1100, "LE": 0b1101,
            "AL": 0b1110,
        }

        # 2.4 Instrucciones especiales (vacío por ahora)
        self.spc_instr = {}

        self.labels: dict[str, int] = {}

        self.valid_ops = (
            list(self.dp_instr.keys())
            + list(self.mem_instr.keys())
            + list(self.b_instr.keys())
            + list(self.mul_long_cmd.keys())
            + list(self.spc_instr.keys())
        )

    # ────────────────────── 2.5 Tokenización
    def tokenize_instruction(self, instr: str):
        tokens = []
        for m in self.regex.finditer(instr):
            kind, value = m.lastgroup, m.group()
            if kind in ["SPACE", "COMMENT"]:
                continue
            # Identificar posibles mnemónicos
            if kind == "POINTER":
                maybe, cond, _ = self.decode_mnemonic(value)
                if maybe in self.valid_ops and cond in self.conds:
                    kind = "OP"
            tokens.append((kind, value))
        return tokens

    # ────────────────────── 2.6 Sufijos condicionales y 'S'
    def decode_mnemonic(self, instr: str):
        instr = instr.upper()
        S = instr.endswith("S")
        if S:
            instr = instr[:-1]

        cond = "AL"
        for suf in self.conds:
            if instr.endswith(suf):
                cond = suf
                instr = instr[:-len(suf)]
                break
        return instr, cond, S

    # ────────────────────── 2.7 Codificador
    def assemble_instruction(self, tokens, pc) -> int:
        if not tokens:
            return -1

        # token OP
        op_tok = next((t for t in tokens if t[0] == "OP"), None)
        if not op_tok:
            return -1

        instr, cond, Sflag = self.decode_mnemonic(op_tok[1])
        regs = [reg_val(v) for k, v in tokens if k == "REG"]
        imms = [imm_val(v, 4095) for k, v in tokens if k == "IMM"]

        # ──────────────────── SMUL / UMUL (multiply-long) ────────────────────
        if instr in self.mul_long_cmd:
            if len(regs) != 4:
                raise RuntimeError(f"{instr} requiere 4 registros: {instr} Rd,Rn,Rm,Ra")
            Rd, Rn, Rm, Ra = regs
            cmd_bits = self.mul_long_cmd[instr]

            return (
                (self.conds[cond] << 28) |   # 31-28 cond
                (0b00          << 26)   |   # 27-26 op = 00
                (0b00          << 24)   |   # 25-24 00
                (cmd_bits      << 21)   |   # 23-21 cmd
                (Sflag         << 20)   |   # 20    S
                (Rd            << 16)   |   # 19-16 RdLo
                (Ra            << 12)   |   # 15-12 RdHi
                (Rm            <<  8)   |   # 11-8  Rm
                (0b1001        <<  4)   |   # 7-4   patrón 1001
                (Rn)                       # 3-0   Rn
            )

        # ──────────────────── Data-Processing (incluye FADD/FMUL) ────────────
        if instr in self.dp_instr:
            cmd = self.dp_instr[instr]

            # ─── FP FADD / FMUL: caso especial antes de genérico
            if instr in ("FADD", "FMUL"):
                if len(regs) != 3:
                    raise RuntimeError(f"{instr} Rd,Rn,Rm")
                Rd, Rn, Rm = regs
                I = 0                    # siempre reg-reg
                operand2 = Rm | (1 << 4) if instr == "FMUL" else Rm  # bit 4
                return (
                    (self.conds[cond] << 28) | (0b00 << 26) |
                    (I << 25) | (cmd << 21) | (Sflag << 20) |
                    (Rn << 16) | (Rd << 12) | operand2
                )
            # ─── MOV reg|#imm ─────────────────────────────────────────────
            if instr == "MOV":
                Sflag = 0
                if len(regs) == 1 and len(imms) == 1:          # MOV Rd,#imm12
                    Rd, operand2 = regs[0], imms[0]
                    I, Rn        = 1, 0
                elif len(regs) == 2 and not imms:              # MOV Rd,Rm   ← AQUÍ
                    Rd, Rm       = regs        # solo dos registros
                    I, Rn        = 0, 0        # I=0, Rn se codifica en cero
                    operand2     = Rm          # Operand2 = Rm
                else:
                    raise RuntimeError("MOV formato inválido")

                return (
                    (self.conds[cond] << 28) | (0b00 << 26) |
                    (I << 25) | (cmd << 21) | (Sflag << 20) |
                    (Rn << 16) | (Rd << 12) | operand2
                )




            # ─── MUL / DIV (Rd,Rm,Rs)
            if instr in ("MUL", "DIV"):
                if len(regs) != 3:
                    raise RuntimeError(f"{instr} Rd,Rm,Rs")
                Rd, Rm, Rs = regs
                return (
                    (self.conds[cond] << 28) | (0b00 << 26) |
                    (0 << 25) | (cmd << 21) | (Sflag << 20) |
                    (Rm << 16) | (Rd << 12) | Rs
                )

            # ─── LSL / LSR  (Rd,Rm,#shift)
            if instr in ("LSL", "LSR"):
                if len(regs) != 2 or not imms:
                    raise RuntimeError(f"{instr} Rd,Rm,#imm")
                Rd, Rm = regs
                shift_imm = imms[0]
                shift_type = 0b00 if instr == "LSL" else 0b01
                operand2 = (shift_imm << 7) | (shift_type << 5) | Rm
                return (
                    (self.conds[cond] << 28) | (0b00 << 26) |
                    (0 << 25) | (cmd << 21) | (Sflag << 20) |
                    (0 << 16) | (Rd << 12) | operand2
                )

            # ─── Resto de DP (ADD, SUB, ORR, AND…)
            if len(regs) == 3:                                # reg,reg,reg
                Rd, Rn, Rm = regs
                I, operand2 = 0, Rm
            elif len(regs) == 2 and imms:                     # reg,reg,#imm
                Rd, Rn = regs
                I, operand2 = 1, imms[0]
            else:
                raise RuntimeError("Formato DP inválido")

            return (
                (self.conds[cond] << 28) | (0b00 << 26) |
                (I << 25) | (cmd << 21) | (Sflag << 20) |
                (Rn << 16) | (Rd << 12) | operand2
            )

        # ──────────────────── Memoria (LDR/STR) ─────────────────────────────
        if instr in self.mem_instr:
            if len(regs) < 2:
                raise RuntimeError("MEM necesita ≥2 registros")
            Rd, Rn = regs[:2]
            code = self.mem_instr[instr]
            L, B = code & 1, (code >> 1) & 1

            if len(regs) == 3:                                # reg,reg,reg
                I, operand2 = 1, regs[2]
            elif len(regs) == 2 and imms:                     # reg,reg,#imm
                I, operand2 = 0, imms[0]
            else:
                raise RuntimeError("MEM formato inválido")

            return (
                (self.conds[cond] << 28) | (0b01 << 26) |
                (I << 25) | (1 << 24) | (1 << 23) |
                (B << 22) | (L << 20) |
                (Rn << 16) | (Rd << 12) | operand2
            )

        # ──────────────────── Saltos (B) ────────────────────────────────────
        if instr in self.b_instr:
            label_tok = next((v for k, v in tokens if k == "POINTER"), None)
            if label_tok not in self.labels:
                raise RuntimeError(f"Label indefinido: {label_tok}")
            offset = self.labels[label_tok] - (pc + 2)
            return (self.conds[cond] << 28) | (0b101 << 25) | (offset & 0xFFFFFF)

        # ──────────────────── Especiales opcionales ────────────────────────
        if instr in self.spc_instr:
            raise RuntimeError("Instrucción especial no implementada")

        raise RuntimeError(f"Instrucción no reconocida: {instr}")

    # ────────────────────── 2.8  Ensamblar programa completo ───────────────
    def assemble_program(self, text: str):
        # eliminar comentarios/espacios y numerar
        lines = [(n + 1, l.split("//", 1)[0].strip()) for n, l in enumerate(text.splitlines())]
        lines = [(n, l) for n, l in lines if l]

        token_lines, src_clean, pc = [], [], 0

        # Primer pase (etiquetas)
        for ln, line in lines:
            toks = self.tokenize_instruction(line)
            if not toks:
                continue
            if toks[0][0] == "LABEL":
                self.labels[toks[0][1][:-1]] = pc
                toks = toks[1:]
            if toks:
                token_lines.append((ln, pc, toks))
                src_clean.append(line)
                pc += 1

        # Segundo pase (codificación)
        machine = []
        for idx, (ln, pc_val, toks) in enumerate(token_lines):
            try:
                code = self.assemble_instruction(toks, pc_val)
                if code != -1:
                    machine.append(code)
            except Exception as e:
                print(f"\nERROR: {e}\nEN LÍNEA {ln}: {src_clean[idx]}\n")
                sys.exit(1)

        return machine, src_clean

# ──────────────────────────────────────────────────────────────
# 3.  main
# ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("ARM-lite Assembler – v2.2 (SMUL/UMUL + FADD/FMUL)")
    if len(sys.argv) < 2:
        print("Uso: python asm.py <archivo.asm> [salida.mem]")
        sys.exit(1)

    infile  = sys.argv[1]
    outfile = sys.argv[2] if len(sys.argv) > 2 else "memfile.mem"

    try:
        source = open(infile, "r").read()
    except FileNotFoundError:
        print(f"Archivo no encontrado: {infile}")
        sys.exit(1)

    asm = ARM_Assembler()
    try:
        codes, src_lines = asm.assemble_program(source)

        print("\n== Instrucciones ==")
        for i, code in enumerate(codes):
            print(f"{i:02d} {src_lines[i].lstrip():24}: 0x{code:08X}")

        with open(outfile, "w") as f:
            f.writelines(f"{c:08X}\n" for c in codes)

        print(f"\nHecho: memoria hexadecimal escrita en '{outfile}'")
    except Exception as exc:
        print(f"\nERROR GENERAL: {exc}")
        traceback.print_exc()
        sys.exit(1)
