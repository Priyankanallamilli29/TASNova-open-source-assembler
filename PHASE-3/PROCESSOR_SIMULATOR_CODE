`timescale 1ns/1ps
 
module processor_simulator;

  // Clock and reset
  logic clk = 0, rst = 1;

  // Instruction memory to hold 256 instructions (40-bit wide)
  logic [39:0] instruction_mem [0:255];

  // Register file output: 256 registers, each 32-bit wide
  logic [31:0] regfile_out [0:255];

  // Program counter (PC) to keep track of current instruction index
  logic [7:0] pc = 0;

  // Used register tracking to log only modified registers at end
  logic [7:0] used_registers [0:255];
  integer used_count = 0;

  // Decoded instruction fields
  logic [5:0] opcode;              // Instruction opcode
  logic [1:0] mode;                // Instruction mode (determines operand format)
  logic [7:0] op1_addr, op2_addr;  // Register addresses
  logic [15:0] op1_imm, op2_imm;   // Immediate values
  logic [7:0] dest_addr, dest_addr2;        // Destination register addresses
  logic [31:0] dest_data, dest_data2;       // Data to write into registers
  logic write_en, write_en2;      // Write enable signals for 2-port register file
  logic [39:0] current_instr;     // Currently executing instruction
  string instr_str;               // Decoded instruction name
  string decoded_text;            // Instruction log line

  // Clock generation (10 ns period)
  always #5 clk = ~clk;

  // Logging queue to store output logs
  string log_lines[$];

  // Push log message into queue and display
  task log_step(string msg);
    log_lines.push_back(msg);
    $display("%s", msg);
  endtask

  // Register File Module Instance
  register_file u_regfile (
    .clk(clk),
    .rst(rst),
    .write_en(write_en),
    .write_en2(write_en2),
    .addr1(dest_addr),
    .addr2(dest_addr2),
    .data1(dest_data),
    .data2(dest_data2),
    .regfile_out(regfile_out)
  );

  // ALU Module Instance
  alu_top u_alu (
    .clk(clk),
    .rst(rst),
    .opcode(opcode),
    .mode(mode),
    .op1_addr(op1_addr),
    .op2_addr(op2_addr),
    .op1_imm(op1_imm),
    .op2_imm(op2_imm),
    .regfile_in(regfile_out),
    .dest_addr(dest_addr),
    .dest_data(dest_data),
    .write_en(write_en),
    .dest_addr2(dest_addr2),
    .dest_data2(dest_data2),
    .write_en2(write_en2)
  );

  // Track used registers to log them later
  function void track_reg(input logic [7:0] r);
    for (int i = 0; i < used_count; i++)
      if (used_registers[i] == r) return;
    used_registers[used_count++] = r;
  endfunction

  // Decode a 40-bit instruction into its fields
  task decode_instruction(input logic [39:0] instr);
    opcode = instr[39:34];
    mode   = instr[33:32];

    case (mode)
      2'b00: begin  // Reg–Reg
        op1_addr = instr[31:24];
        op2_addr = instr[23:16];
        track_reg(op1_addr);
        track_reg(op2_addr);
      end
      2'b01: begin  // Reg–Imm
        op1_addr = instr[31:24];
        op2_imm  = instr[23:8];
        track_reg(op1_addr);
      end
      2'b10: begin  // Imm–Reg
        op1_imm  = instr[31:16];
        op2_addr = instr[15:8];
        track_reg(op2_addr);
      end
      2'b11: begin  // Imm–Imm
        op1_imm  = instr[31:16];
        op2_imm  = instr[15:0];
      end
    endcase
  endtask

  // Check if a register was used before being initialized
  function bit check_uninitialized(input logic [7:0] addr);
    return (^regfile_out[addr] === 1'bx); // Check for undefined values
  endfunction

  // Main execution block
  initial begin
    integer logfile;

    // Load instructions from file
    $readmemh("output.txt", instruction_mem);
    #10 rst = 0; // Deassert reset

    // Loop over all valid instructions
    while (instruction_mem[pc] !== 40'dx) begin
      current_instr = instruction_mem[pc];
      decode_instruction(current_instr);

      // Error checking for uninitialized registers
      if (mode == 2'b00 || mode == 2'b10) begin
        if (mode == 2'b00 && check_uninitialized(op1_addr)) begin
          log_step($sformatf("Error: Uninitialized register R%0d.", op1_addr));
          $finish;
        end
        if ((mode == 2'b00 || mode == 2'b10) && check_uninitialized(op2_addr)) begin
          log_step($sformatf("Error: Uninitialized register R%0d.", op2_addr));
          $finish;
        end
      end

      #1; // Small delay for data stabilization

      // Instruction name decoding
      case (opcode)
        6'b000001: instr_str = "ADD";
        6'b000010: instr_str = "SUB";
        6'b000011: instr_str = "MUL";
        6'b000100: instr_str = "DIV";
        6'b000101: instr_str = "MOD";
        6'b000110: instr_str = "INC";
        6'b000111: instr_str = "DEC";
        6'b001000: instr_str = "AND";
        6'b001001: instr_str = "OR";
        6'b001010: instr_str = "XOR";
        6'b001011: instr_str = "NOT";
        6'b001100: instr_str = "NAND";
        6'b001101: instr_str = "NOR";
        6'b001110: instr_str = "XNOR";
        6'b001111: instr_str = "SHL";
        6'b010000: instr_str = "SHR";
        6'b010001: instr_str = "SAR";
        6'b010010: instr_str = "EQ";
        6'b010011: instr_str = "NE";
        6'b010100: instr_str = "GT";
        6'b010101: instr_str = "LT";
        6'b010110: instr_str = "GE";
        6'b010111: instr_str = "LE";
        6'b011000: instr_str = "ZERO";
        6'b011001: instr_str = "NEG";
        6'b011010: instr_str = "ROR";
        6'b011011: instr_str = "ROL";
        6'b011100: instr_str = "MAX";
        6'b011110: instr_str = "MIN";
        6'b011111: instr_str = "MOV";
        6'b100000: instr_str = "SWAP";
        6'b100011: instr_str = "REV";
        default:   instr_str = "OP";
      endcase

      // Decode logging based on opcode and mode
      case (opcode)
        6'b011111: begin  // MOV
          decoded_text = $sformatf("Instruction %0d: MOV R%0d #%0d", pc, op1_addr, op2_imm);
          log_step(decoded_text);
          log_step($sformatf("MOV: R%0d <- %0d", op1_addr, op2_imm));
        end
        6'b100000: begin  // SWAP
          decoded_text = $sformatf("Instruction %0d: SWAP R%0d R%0d", pc, op1_addr, op2_addr);
          log_step(decoded_text);
          log_step($sformatf("SWAP: R%0d <-> R%0d", op1_addr, op2_addr));
        end
        default: begin
          // General format based on mode
          case (mode)
            2'b00: decoded_text = $sformatf("Instruction %0d: %s R%0d R%0d", pc, instr_str, op1_addr, op2_addr);
            2'b01: decoded_text = $sformatf("Instruction %0d: %s R%0d #%0d", pc, instr_str, op1_addr, op2_imm);
            2'b10: decoded_text = $sformatf("Instruction %0d: %s #%0d R%0d", pc, instr_str, op1_imm, op2_addr);
            2'b11: decoded_text = $sformatf("Instruction %0d: %s #%0d #%0d", pc, instr_str, op1_imm, op2_imm);
          endcase

          log_step(decoded_text);

          // Additional detailed log (example calculation)
          if (mode == 2'b00)
            log_step($sformatf("%s: R%0d <- %0d %s %0d = %0d",
              instr_str, op1_addr, regfile_out[op1_addr], instr_str, regfile_out[op2_addr], dest_data));
          else if (mode == 2'b01)
            log_step($sformatf("%s: R%0d <- %0d %s %0d = %0d",
              instr_str, op1_addr, regfile_out[op1_addr], instr_str, op2_imm, dest_data));
          else if (mode == 2'b10)
            log_step($sformatf("%s: R%0d <- %0d %s %0d = %0d",
              instr_str, op2_addr, op1_imm, instr_str, regfile_out[op2_addr], dest_data));
          else
            log_step($sformatf("%s: IMM %0d %s %0d = %0d", instr_str, op1_imm, instr_str, op2_imm, dest_data));
        end
      endcase

      #10;
      pc++;  // Move to next instruction
    end

    // Open log file for writing
    logfile = $fopen("execution_log.txt", "w");
    if (!logfile) begin
      $display("Cannot open log file.");
      $finish;
    end

    // Write final register values
    $fdisplay(logfile, "Final Register Values:");
    for (int i = 0; i < used_count; i++) begin
      $fdisplay(logfile, "R%0d = %0d", used_registers[i], regfile_out[used_registers[i]]);
    end
    $fdisplay(logfile, "----------------------------------------");

    // Write log lines collected during simulation
    foreach (log_lines[i]) begin
      $fdisplay(logfile, "%s", log_lines[i]);
    end

    $fclose(logfile);
    $finish;
  end

endmodule
