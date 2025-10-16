`timescale 1ns/1ps

module instruction_decoder (
    input  logic         clk,         // Clock signal for synchronous operation
    input  logic         rst,         // Active-high asynchronous reset
    output logic [5:0]   opcode,      // Decoded 6-bit opcode from instruction
    output logic [1:0]   mode,        // Decoded 2-bit mode field
    output logic [15:0]  operand1,    // First decoded operand (16 bits)
    output logic [15:0]  operand2,    // Second decoded operand (16 bits)
    output logic         valid        // High when output holds valid decoded instruction
);

  // Internal memory to hold up to 256 instructions of 40 bits each
  bit [39:0] instruction_mem [0:255];

  // Total number of instructions loaded from file
  int instruction_count = 0;

  // Instruction pointer to track current instruction being decoded
  int instruction_pointer = 0;

  // Initial block to read instructions from external file "output.txt"
  initial begin
    int fd;         // File descriptor handle
    int i;          // Loop variable
    string line;    // Temporary string to hold file line content
    i = 0;

    // Open file in read mode
    fd = $fopen("output.txt", "r");
    if (fd == 0) begin
      $display("ERROR: Cannot open output.txt");
      $finish;  // Terminate simulation if file not found
    end

    // Read file line by line until EOF
    while (!$feof(fd)) begin
      line = "";
      void'($fgets(line, fd));  // Read a line into string 'line'

      // If line is not empty, parse hex value into instruction memory
      if (line.len() > 0) begin
        void'($sscanf(line, "%h", instruction_mem[i]));
        i++;
      end
    end

    instruction_count = i;  // Store total instructions read
    $fclose(fd);           // Close file descriptor
  end

  // Sequential logic block - triggered on rising clock edge or reset
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // On reset, clear instruction pointer and output registers
      instruction_pointer <= 0;
      opcode    <= 6'd0;
      mode      <= 2'd0;
      operand1  <= 16'd0;
      operand2  <= 16'd0;
      valid     <= 1'b0;
    end else begin
      // If instructions remain to decode
      if (instruction_pointer < instruction_count) begin
        bit [39:0] instr;
        instr = instruction_mem[instruction_pointer];  // Fetch current instruction

        // Extract opcode and mode fields
        opcode <= instr[39:34];
        mode   <= instr[33:32];
        valid  <= 1'b1;  // Valid output asserted for current instruction

        // Decode operands based on mode field
        case (instr[33:32])
          2'b00: begin
            operand1 <= {8'b0, instr[31:24]};  // Zero-extend 8-bit to 16-bit
            operand2 <= {8'b0, instr[23:16]};
          end
          2'b01: begin
            operand1 <= {8'b0, instr[31:24]};  // Zero-extend 8-bit to 16-bit
            operand2 <= instr[23:8];            // Use 16 bits directly
          end
          2'b10: begin
            operand1 <= instr[31:16];           // Use 16 bits directly
            operand2 <= {8'b0, instr[15:8]};   // Zero-extend 8-bit to 16-bit
          end
          2'b11: begin
            operand1 <= instr[31:16];           // Use 16 bits directly
            operand2 <= instr[15:0];            // Use 16 bits directly
          end
          default: begin
            operand1 <= 16'd0;
            operand2 <= 16'd0;
          end
        endcase

        instruction_pointer <= instruction_pointer + 1;  // Move to next instruction
      end else begin
        // No more instructions, de-assert valid
        valid <= 1'b0;
      end
    end
  end

endmodule
