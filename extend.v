module extend (
    input  wire [23:0] Instr,
    input  wire [1:0]  ImmSrc,
    input  wire        IsMovt,
    input  wire        IsMovm,

    output reg  [31:0] ExtImm
);
    always @(*) begin
        case (ImmSrc)
            2'b00: ExtImm = {24'b0, Instr[7:0]}; // 8-bit immediate
            2'b01: ExtImm = {20'b0, Instr[11:0]}; // 12-bit immediate
            2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; // Branch offset
            
            2'b11: ExtImm = IsMovm ? {12'b0, Instr[7:0], 12'b0} :      // MOVM
                            IsMovt ? {4'b0, Instr[11:0], 20'b0} :      // MOVT
                                     {20'b0, Instr[11:0]};           // MOV
                                     
            default: ExtImm = 32'b0;
        endcase
    end
endmodule