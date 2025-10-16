`timescale 1ns/1ps

module alu_top (
    input  logic        clk,
    input  logic        rst,

    // Operation control inputs
    input  logic [5:0]  opcode,     // 6-bit ALU operation selector
    input  logic [1:0]  mode,       // 2-bit operand mode selector

    // Operand input sources (addresses or immediate values)
    input  logic [7:0]  op1_addr,   // Address of operand1 (if register)
    input  logic [7:0]  op2_addr,   // Address of operand2 (if register)
    input  logic [15:0] op1_imm,    // Immediate value for operand1
    input  logic [15:0] op2_imm,    // Immediate value for operand2

    // Read-only access to register file
    input   var logic [31:0] regfile_in [0:255], // Register bank input

    // Outputs for writing back result(s)
    output logic [7:0]  dest_addr,   // Destination register address
    output logic [31:0] dest_data,   // Result to be written to dest_addr
    output logic        write_en,    // Enable signal for write to dest_addr

    output logic [7:0]  dest_addr2,  // Second destination register (for SWAP)
    output logic [31:0] dest_data2,  // Second result data
    output logic        write_en2    // Enable for dest_addr2
);

  // Internal operands and result
  logic [31:0] op1, op2, result;

  // Operand selection based on 2-bit mode
  // 00: Register–Register
  // 01: Register–Immediate
  // 10: Immediate–Register
  // 11: Immediate–Immediate
  always_comb begin
    case (mode)
      2'b00: begin
        op1 = regfile_in[op1_addr];
        op2 = regfile_in[op2_addr];
      end
      2'b01: begin
        op1 = regfile_in[op1_addr];
        op2 = {{16{op2_imm[15]}}, op2_imm}; // Sign-extend immediate
      end
      2'b10: begin
        op1 = {{16{op1_imm[15]}}, op1_imm}; // Sign-extend immediate
        op2 = regfile_in[op2_addr];
      end
      2'b11: begin
        op1 = {{16{op1_imm[15]}}, op1_imm};
        op2 = {{16{op2_imm[15]}}, op2_imm};
      end
      default: begin
        op1 = 32'd0;
        op2 = 32'd0;
      end
    endcase
  end

  // ALU operation logic: 32 total operations
  always_comb begin
    result = 32'd0;
    case (opcode)
      6'b000001: result = op1 + op2;                 // ADD
      6'b000010: result = op1 - op2;                 // SUB
      6'b000011: result = op1 * op2;                 // MUL
      6'b000100: result = (op2 != 0) ? op1 / op2 : 32'd0; // DIV (safe)
      6'b000101: result = (op2 != 0) ? op1 % op2 : 32'd0; // MOD (safe)
      6'b000110: result = op1 + 1;                   // INC
      6'b000111: result = op1 - 1;                   // DEC
      6'b001000: result = op1 & op2;                 // AND
      6'b001001: result = op1 | op2;                 // OR
      6'b001010: result = op1 ^ op2;                 // XOR
      6'b001011: result = ~op1;                      // NOT (unary)
      6'b001100: result = ~(op1 & op2);              // NAND
      6'b001101: result = ~(op1 | op2);              // NOR
      6'b001110: result = ~(op1 ^ op2);              // XNOR
      6'b001111: result = op1 << op2[4:0];           // SHL (logical left shift)
      6'b010000: result = op1 >> op2[4:0];           // SHR (logical right shift)
      6'b010001: result = $signed(op1) >>> op2[4:0]; // SAR (arithmetic right shift)
      6'b010010: result = (op1 == op2);              // EQ (equality)
      6'b010011: result = (op1 != op2);              // NE (not equal)
      6'b010100: result = (op1 > op2);               // GT
      6'b010101: result = (op1 < op2);               // LT
      6'b010110: result = (op1 >= op2);              // GE
      6'b010111: result = (op1 <= op2);              // LE
      6'b011000: result = (op1 == 0);                // ZERO check
      6'b011001: result = -op1;                      // NEG (2's complement)
      6'b011010: result = (op1 >> op2[4:0]) | (op1 << (32 - op2[4:0])); // ROR
      6'b011011: result = (op1 << op2[4:0]) | (op1 >> (32 - op2[4:0])); // ROL
      6'b011100: result = op1;                       // Pass-through
      6'b011101: result = (op1 > op2) ? op1 : op2;   // MAX
      6'b011110: result = (op1 < op2) ? op1 : op2;   // MIN
      6'b011111: result = op2;                       // MOV (copy op2 to op1)

      6'b100000: ; // SWAP (handled separately in writeback)
      6'b100001: result = (op1 >> op2[4:0]) | (op1 << (32 - op2[4:0])); // ROR duplicate
      6'b100010: result = (op1 << op2[4:0]) | (op1 >> (32 - op2[4:0])); // ROL duplicate
      6'b100011: begin                                // REV (bit reversal)
        for (int i = 0; i < 32; i++)
          result[i] = op1[31 - i];
      end

      default: result = 32'd0; // Default to 0 for unknown opcodes
    endcase
  end

  // Writeback logic to determine where and what to write
  always_comb begin
    // Default output states
    dest_addr  = 8'd0;
    dest_data  = 32'd0;
    write_en   = 1'b0;
    dest_addr2 = 8'd0;
    dest_data2 = 32'd0;
    write_en2  = 1'b0;

    case (opcode)
      6'b011111: begin // MOV
        dest_addr = op1_addr;
        dest_data = result;
        write_en  = 1;
      end

      6'b100000: begin // SWAP (special: writes to two registers)
        dest_addr  = op1_addr;
        dest_data  = op2;
        write_en   = 1;

        dest_addr2 = op2_addr;
        dest_data2 = op1;
        write_en2  = 1;
      end

      default: begin
        // General case: write result back only if not IMM–IMM mode
        if (mode != 2'b11) begin
          dest_addr = op1_addr;
          dest_data = result;
          write_en  = 1;
        end
      end
    endcase
  end

endmodule
