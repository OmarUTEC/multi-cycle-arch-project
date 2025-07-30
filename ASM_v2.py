import re
import sys
import traceback

TOKEN_SPEC = {
    "LABEL": r"[A-Za-z_][A-Za-z0-9_]*:",
    "REG": r"R(?:1[0-5]|[0-9])",
    "POINTER": r"[A-Za-z_][A-Za-z0-9_]*",
    "IMM": r"#(?:0x[0-9a-fA-F]+|[0-9]+)",
    "COMMA": r",",
    "S_COLON": r";",
    "L_BRACKET": r"\[",
    "R_BRACKET": r"\]",
    "SPACE": r"\s+",
    "COMMENT": r"//.*",
    "UNKNOWN": r"."
}

def reg_val(r):
    val = int(r[1:])
    if not (0 <= val <= 15):
        raise ValueError(f"Registro fuera de rango (0-15): {r}")
    return val

def imm_val(s, m=255):
    val = int(s[1:], 0)
    if not (0 <= val <= m):
        raise ValueError(f"Inmediato fuera de rango (0-{m}): {s}")
    return val

class ARM_Assembler:
    def __init__(self):
        pattern = "|".join(f"(?P<{name}>{regex})" for name, regex in TOKEN_SPEC.items())
        self.regex = re.compile(pattern, re.IGNORECASE)

        #################################
        #                               #
        # You can change encodings HERE #
        #                               #
        #################################

        self.dp_instr = {
            "AND": 0b0000,
            "SUB": 0b0010,
            "ADD": 0b0100,
            "ORR": 0b1100,
            "MOV": 0b1101,
            "LSL": 0b1101,
            "LSR": 0b1101,
            "MUL": 0b1001,
            "SMUL": 0b1101,  # SMUL
            "UMUL": 0b1111,  # UMUL
            "DIV": 0b0001,   # DIV
        }
        self.mem_instr = {
            "STR": 0b00,
            "LDR": 0b01,
            "STRB": 0b10,
            "LDRB": 0b11,
        }
        self.b_instr = {"B": 0b0}
        self.conds = {
            "EQ": 0b0000,
            "NE": 0b0001,
            "CS": 0b0010,
            "HS": 0b0010,
            "CC": 0b0011,
            "LO": 0b0011,
            "MI": 0b0100,
            "PL": 0b0101,
            "VS": 0b0110,
            "VC": 0b0111,
            "HI": 0b1000,
            "LS": 0b1001,
            "GE": 0b1010,
            "LT": 0b1011,
            "GT": 0b1100,
            "LE": 0b1101,
            "AL": 0b1110,
        }

        #
        # Use this section to implement you own encodings with their respective "VALUE", these will have OP type of 11
        #
        self.spc_instr = {
            "ADDLNG": 0,  # Special instruction example
        }

        self.labels = {}
        self.valid_ops = (
            list(self.dp_instr.keys())
            + list(self.mem_instr.keys())
            + list(self.b_instr.keys())
            + list(self.spc_instr.keys())
        )

    # Only for tokenization purposes
    def tokenize_instruction(self, instr: str):
        tokens = []
        for match in self.regex.finditer(instr):
            kind = match.lastgroup
            value = match.group()

            # Filtrar espacios y comentarios
            if kind in ["SPACE", "COMMENT"]:
                continue

            if kind == "POINTER":
                possible_instr, cond, S = self.decode_mnemonic(value)
                if possible_instr in self.valid_ops and cond in self.conds:
                    kind = "OP"
            tokens.append((kind, value))
        return tokens

    def decode_mnemonic(self, instr: str):
        instr = instr.upper()
        flags = instr.endswith("S")
        if flags:
            instr = instr[:-1]
        cond = "AL"
        for suffix in self.conds:
            if instr.endswith(suffix):
                cond = suffix
                instr = instr[: -len(suffix)]
                break
        return instr, cond, flags
    
    #
    # MAIN INSTRUCTION ENCODER
    #
    def assemble_instruction(self, tokens: list[tuple[str, str]], pc) -> int:
        if not tokens:
            return -1
            
        it = iter(tokens)
        
        # Buscar la instrucción (OP)
        op_token = None
        for token in tokens:
            if token[0] == "OP":
                op_token = token
                break
        
        if op_token is None:
            return -1  # No hay instrucción válida
            
        instr, cond, S = self.decode_mnemonic(op_token[1])
        
        regs = [reg_val(v) for (k, v) in tokens if k == "REG"]
        imms = [imm_val(v, 4095) for (k, v) in tokens if k == "IMM"]  # Aumentado el rango
        
        # OP == DP
        if instr in self.dp_instr:
            # Custom DP exceptions
            if instr == "MOV":
                S = 0
                Rn = 0
                cmd = self.dp_instr[instr]

                if len(regs) == 1 and len(imms) == 1:
                    # MOV Rd, #imm
                    Rd = regs[0]
                    operand2 = imms[0]
                    I = 1
                elif len(regs) == 2 and len(imms) == 0:
                    # MOV Rd, Rm
                    Rd, Rm = regs
                    I = 0
                    operand2 = Rm
                else:
                    raise RuntimeError(
                        f"Invalid MOV format: should be MOV Rd, Rm or MOV Rd, #imm"
                    )

                return (
                    (self.conds[cond] << 28)
                    | (0b00 << 26)
                    | (I << 25)
                    | (cmd << 21)
                    | (S << 20)
                    | (Rn << 16)
                    | (Rd << 12)
                    | operand2
                )

            # MUL, SMUL, UMUL, DIV - todas usan el formato DP estándar
            if instr in ["MUL", "SMUL", "UMUL", "DIV"]:
                if len(regs) != 3:
                    raise RuntimeError(
                        f"{instr} format invalid. Should be: {instr} Rd, Rm, Rs"
                    )
                Rd, Rm, Rs = regs
                cmd = self.dp_instr[instr]
                
                # Formato estándar de procesamiento de datos
                # Similar a ADD pero con el código de operación específico
                return (
                    (self.conds[cond] << 28)
                    | (0b00 << 26)        # DP instruction
                    | (0 << 25)           # I=0 (register operand)
                    | (cmd << 21)         # Command (opcode)
                    | (S << 20)           # S flag
                    | (Rm << 16)          # Rn field = Rm
                    | (Rd << 12)          # Rd field
                    | Rs                  # operand2 = Rs
                )

            if instr in ["LSL", "LSR"]:
                if len(regs) != 2 or not imms:
                    raise RuntimeError(
                        f"{instr} format invalid. Should be: {instr} Rd, Rm, #imm"
                    )
                Rd, Rm = regs
                shift_imm = imms[0]
                shift_type = 0b00 if instr == "LSL" else 0b01
                shift = (shift_imm << 7) | (shift_type << 5) | Rm
                cmd = self.dp_instr[instr]
                return (
                    (self.conds[cond] << 28)
                    | (0b00 << 26)
                    | (0 << 25)
                    | (cmd << 21)
                    | (S << 20)
                    | (0 << 16)
                    | (Rd << 12)
                    | shift
                )

            # General purpose encoding (add, sub, etc)
            if len(regs) == 3:
                Rd, Rn, Rm = regs
                I = 0
                operand2 = Rm
            elif len(regs) == 2 and imms:
                Rd, Rn = regs
                I = 1
                operand2 = imms[0]              
            else:
                raise RuntimeError("Invalid DP format")
            cmd = self.dp_instr[instr]

            return (
                (self.conds[cond] << 28)
                | (0b00 << 26)
                | (I << 25)
                | (cmd << 21)
                | (S << 20)
                | (Rn << 16)
                | (Rd << 12)
                | operand2
            )

        # OP == MEM
        if instr in self.mem_instr:
            if len(regs) < 2:
                raise RuntimeError("Invalid MEM format: need at least 2 registers")
                
            Rd, Rn = regs[:2]
            code = self.mem_instr[instr]
            L = code & 1
            B = (code >> 1) & 1
            
            if len(regs) == 3:
                # is reg reg reg
                I = 1
                operand2 = regs[2]
            elif len(regs) == 2 and len(imms) == 1:
                # is reg reg imm
                I = 0
                operand2 = imms[0]
            else: 
                raise RuntimeError("Invalid MEM type format")
            
            # always offset not post nor pre index
            return (
                (self.conds[cond] << 28)
                | (0b01 << 26)
                | (I << 25)
                | (1 << 24)
                | (1 << 23)
                | (B << 22)
                | (L << 20)                
                | (Rn << 16)
                | (Rd << 12)
                | operand2
            )

        # OP == B
        if instr in self.b_instr:
            label_tok = next((v for (k, v) in tokens if k == "POINTER"), None)
            if label_tok is None:
                raise RuntimeError("Falta label en B")
            if label_tok not in self.labels:
                raise RuntimeError(f"Label no definido: {label_tok}")
            offset = self.labels[label_tok] - (pc + 2)
            return (self.conds[cond] << 28) | (0b101 << 25) | (offset & 0xFFFFFF)

        #
        # Implement your own special encodings here with OP == SPC
        #
        if instr in self.spc_instr:
            # Example of fictional function with 4 registers input
            if len(regs) != 4:
                raise RuntimeError(f"{instr} requires 4 registers")

            # Make sure register numbers are between 0-15
            RdLo, RdHi, RmLo, RmHi = regs  # They are already ints

            # Simple example codification
            return (
                (self.conds[cond] << 28)
                | (0b11 << 26)
                | (self.spc_instr[instr] << 20)
                | (RdLo << 16)
                | (RdHi << 12)
                | (RmLo << 8)
                | (RmHi << 4)
            )
        
        raise RuntimeError(f"Instruction not implemented: {instr}")

    def assemble_program(self, program: str) -> tuple[list[int], list[str]]:
        lines = program.strip().splitlines()
        lines = [(n+1, l) for n, l in enumerate(lines)]
        lines = [(n, l.split('//', 1)[0].strip()) for n, l in lines]
        lines = [(n, l) for n, l in lines if l != ""]

        extract = []
        token_lines = []
        pc = 0  
        
        for i, line in lines:
            tokens = self.tokenize_instruction(line)
            if not tokens:
                continue

            if tokens[0][0] == "LABEL":
                label_name = tokens[0][1][:-1]
                self.labels[label_name] = pc
                # ¿Hay una instrucción en esta línea?
                if len(tokens) > 1:
                    instr_tokens = tokens[1:]
                    extract.append(line)
                    token_lines.append((i, pc, instr_tokens))
                    pc += 1
            else:
                extract.append(line)
                token_lines.append((i, pc, tokens))
                pc += 1

        result = []
        for i, (line_num, pc_val, tokens) in enumerate(token_lines):
            try:
                # CHECK SYNTAX
                kinds = [k for k, _ in tokens]
                if "UNKNOWN" in kinds:
                    raise RuntimeError("Bad instruction formation.")
                
                instr_code = self.assemble_instruction(tokens, pc_val)
                if instr_code == -1:
                    continue  # Skip empty lines
                result.append(instr_code)
            except Exception as e:
                print(f"\nERROR: {e}")
                print(f"AT LINE: {line_num} | WITH: {extract[i]}")
                print("FAILURE.")
                sys.exit(1)
        
        return result, extract


#
# main entrypoint, reads asm and writes to file
#
if __name__ == "__main__":
    print("ARMv7 - Simple assembler. (Arch - CS2201) - 2025 - v2.0")
    if len(sys.argv) < 2:
        print("Execute as: python asm.py <input file> [<output file>]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "memfile.mem"

    assembler = ARM_Assembler()
    
    try:
        with open(input_file, "r") as infile:
            source_code = infile.read()
    except FileNotFoundError:
        print(f"Error: No se pudo encontrar el archivo '{input_file}'")
        sys.exit(1)

    try:
        instrs, extract = assembler.assemble_program(source_code)

        print("\n== Instructions ==")
        for i, instr in enumerate(instrs):
            if i < len(extract):
                text = extract[i].lstrip().ljust(18)
                print(f"{i:02d} {text} : 0x{instr:08X}")

        with open(output_file, "w") as f:
            for instr in instrs:
                f.write(f"{instr:08X}\n")

        print(f"\nSUCCESS: Hex memory written to {output_file}")
    except Exception as e:
        print(f"\nERROR GENERAL: {e}")
        traceback.print_exc()
        sys.exit(1)