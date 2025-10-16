module register_file (
  input  logic        clk,         // Clock signal for synchronous operations
  input  logic        rst,         // Reset signal (active high) to initialize register file
  input  logic        write_en,    // Write enable signal for first write port
  input  logic        write_en2,   // Write enable signal for second write port
  input  logic [7:0]  addr1,       // 8-bit address for first write port (register index)
  input  logic [7:0]  addr2,       // 8-bit address for second write port (register index)
  input  logic [31:0] data1,       // 32-bit data input for first write port
  input  logic [31:0] data2,       // 32-bit data input for second write port
  output logic [31:0] regfile_out [0:255] // Output array: current state of all 256 registers
);

  // Internal 256 x 32-bit register file memory
  logic [31:0] rf [0:255];

  // Sequential block: handles reset and write operations on rising clock edge or reset
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // On reset, initialize all registers to 0
      for (int i = 0; i < 256; i++) begin
        rf[i] <= 0;
      end
    end else begin
      // If write enable is asserted, write data1 to register at addr1
      if (write_en)  
        rf[addr1] <= data1;
      // If second write enable is asserted, write data2 to register at addr2
      if (write_en2) 
        rf[addr2] <= data2;
    end
  end

  // Combinational block to continuously assign register contents to output port
  always_comb begin
    for (int i = 0; i < 256; i++)
      regfile_out[i] = rf[i];
  end

endmodule
