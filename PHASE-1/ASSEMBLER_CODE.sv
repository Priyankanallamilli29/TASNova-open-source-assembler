`timescale 1ns/1ps

module assembler;

  // Define instruction structure with mnemonic and opcode
  typedef struct {
    string mnemonic;
    string opcode;
  } instr_t;

  instr_t instr_map[32];  // Instruction table
  integer infile, outfile;  // File handlers

  // Initialize the instruction set mapping (mnemonic to binary opcode)
  function void init_instr_map();
    instr_map[0]  = '{ "ADD",   "000001" };
    instr_map[1]  = '{ "SUB",   "000010" };
    instr_map[2]  = '{ "MUL",   "000011" };
    instr_map[3]  = '{ "DIV",   "000100" };
    instr_map[4]  = '{ "MOD",   "000101" };
    instr_map[5]  = '{ "INC",   "000110" };
    instr_map[6]  = '{ "DEC",   "000111" };
    instr_map[7]  = '{ "AND",   "001000" };
    instr_map[8]  = '{ "OR",    "001001" };
    instr_map[9]  = '{ "XOR",   "001010" };
    instr_map[10] = '{ "NOT",   "001011" };
    instr_map[11] = '{ "NAND",  "001100" };
    instr_map[12] = '{ "NOR",   "001101" };
    instr_map[13] = '{ "XNOR",  "001110" };
    instr_map[14] = '{ "SHL",   "001111" };
    instr_map[15] = '{ "SHR",   "010000" };
    instr_map[16] = '{ "SAR",   "010001" };
    instr_map[17] = '{ "EQ",    "010010" };
    instr_map[18] = '{ "NE",    "010011" };
    instr_map[19] = '{ "GT",    "010100" };
    instr_map[20] = '{ "LT",    "010101" };
    instr_map[21] = '{ "GE",    "010110" };
    instr_map[22] = '{ "LE",    "010111" };
    instr_map[23] = '{ "ZERO",  "011000" };
    instr_map[24] = '{ "NEG",   "011001" };
    instr_map[25] = '{ "ROR",   "011010" };
    instr_map[26] = '{ "ROL",   "011011" };
    instr_map[27] = '{ "MAX",   "011100" };
    instr_map[28] = '{ "MIN",   "011110" };
    instr_map[29] = '{ "MOV",   "011111" };
    instr_map[30] = '{ "SWAP",  "100000" };
    instr_map[31] = '{ "REV",   "100011" };
  endfunction

  // Look up the binary opcode for a given mnemonic
  function string get_opcode(string mnemonic);
    for (int i = 0; i < 32; i++)
      if (instr_map[i].mnemonic == mnemonic)
        return instr_map[i].opcode;
    return "XXXXXX";  // Unknown instruction
  endfunction

  // Convert register name like "R5" to 8-bit binary string
  function automatic string reg_to_bin(string regname);
    string digit_str = "";
    int idx;
    int sscanf_result;
    if (regname.len() < 2 || regname.getc(0) != "R") return "INVALID";
    for (int i = 1; i < regname.len(); i++)
      digit_str = {digit_str, regname.getc(i)};
    sscanf_result = $sscanf(digit_str, "%d", idx);
    if (sscanf_result == 0) return "INVALID";
    if (idx < 0 || idx > 255) return "INVALID";
    return $sformatf("%08b", idx);
  endfunction

  // Convert immediate value like "#15" to 16-bit binary string
  function automatic string imm_to_bin(string imm_str);
    string digit_str = "";
    int val;
    int sscanf_result;
    if (imm_str.len() < 2 || imm_str.getc(0) != "#") return "INVALID";
    for (int i = 1; i < imm_str.len(); i++)
      digit_str = {digit_str, imm_str.getc(i)};
    sscanf_result = $sscanf(digit_str, "%d", val);
    if (sscanf_result == 0) return "INVALID";
    if (val < -256 || val > 255) return "OUT_OF_RANGE";
    return $sformatf("%016b", val & 16'hFFFF);
  endfunction

  // Core task to assemble a single line of assembly code
  task assemble_line(string line);
    string instr, op1, op2;
    string opcode;
    int tokens, temp;
    string bin1, bin2;
    bit [39:0] final_code;
    bit [7:0] reg_val1, reg_val2;
    bit [15:0] imm_val1, imm_val2;
    int mode;
    bit is_op1_reg, is_op2_reg;
    int sscanf_result;

    tokens = $sscanf(line, "%s %s %s", instr, op1, op2);
    opcode = get_opcode(instr);

    if (opcode == "XXXXXX") begin
      $fdisplay(outfile, "XXXXXXXXXX");
      $display("? Unknown instruction: %s", instr);
      return;
    end

    // Set opcode (6 bits) in final 40-bit instruction
    sscanf_result = $sscanf(opcode, "%b", temp);
    final_code[39:34] = temp[5:0];

    // Determine operand types
    is_op1_reg = (op1.len() && op1.getc(0) == "R");
    is_op2_reg = (op2.len() && op2.getc(0) == "R");

    // Determine operand mode
    if (tokens < 3) begin
      if (is_op1_reg) mode = 0; // R format with only one operand (e.g., NOT R1)
      else mode = 2;            // Imm–R format with one immediate
    end else begin
      if (is_op1_reg && is_op2_reg) mode = 0;       // Register–Register
      else if (is_op1_reg && !is_op2_reg) mode = 1; // Register–Immediate
      else if (!is_op1_reg && is_op2_reg) mode = 2; // Immediate–Register
      else mode = 3;                                // Immediate–Immediate
    end

    final_code[33:32] = mode[1:0]; // Set operand mode in instruction

    // Convert operands to binary strings
    if (is_op1_reg)
      bin1 = reg_to_bin(op1);
    else
      bin1 = imm_to_bin(op1);

    if (tokens >= 3) begin
      if (is_op2_reg)
        bin2 = reg_to_bin(op2);
      else
        bin2 = imm_to_bin(op2);
    end

    // Encode operands based on mode
    case (mode)
      0: begin // Register–Register
        sscanf_result = $sscanf(bin1, "%b", reg_val1);
        sscanf_result = $sscanf(bin2, "%b", reg_val2);
        final_code[31:24] = reg_val1;
        final_code[23:16] = reg_val2;
        final_code[15:0]  = 16'b0;
      end
      1: begin // Register–Immediate
        sscanf_result = $sscanf(bin1, "%b", reg_val1);
        sscanf_result = $sscanf(bin2, "%b", imm_val2);
        final_code[31:24] = reg_val1;
        final_code[23:8]  = imm_val2;
        final_code[7:0]   = 8'b0;
      end
      2: begin // Immediate–Register
        sscanf_result = $sscanf(bin1, "%b", imm_val1);
        sscanf_result = $sscanf(bin2, "%b", reg_val2);
        final_code[31:16] = imm_val1;
        final_code[15:8]  = reg_val2;
        final_code[7:0]   = 8'b0;
      end
      3: begin // Immediate–Immediate
        sscanf_result = $sscanf(bin1, "%b", imm_val1);
        sscanf_result = $sscanf(bin2, "%b", imm_val2);
        final_code[31:16] = imm_val1;
        final_code[15:0]  = imm_val2;
      end
    endcase

    // Write the 40-bit instruction in hex to output file
    $fdisplay(outfile, "%010h", final_code);
  endtask

  // Entry point
  initial begin
    string line;
    init_instr_map();  // Initialize instruction table

    infile = $fopen("input.txt", "r");
    outfile = $fopen("output.txt", "w");

    if (infile == 0 || outfile == 0) begin
      $display("Error: Could not open input or output file.");
      $finish;
    end

    // Read and assemble each instruction line
    while (!$feof(infile)) begin
      line = "";
      void'($fgets(line, infile));
      if (line.len() > 1)
        assemble_line(line);
    end

    $fclose(infile);
    $fclose(outfile);
    $display("? Assembly complete. Output written to output.txt");
    $finish;
  end

endmodule
