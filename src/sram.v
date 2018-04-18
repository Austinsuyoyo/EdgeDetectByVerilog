module sram65536x8 (
  input clk,
  input wen,
  input [15:0] addr,
  input [7:0] d,
  output [7:0] q
);
 
reg [7:0] ram [0:65535];
reg [15:0] read_addr;

integer i, j;
  initial begin
    // load the gray-scale image
    $readmemh(`IMAGE_GRAY_HEX, ram);
  end
 
  always @(posedge clk) begin
    if (wen == 0)
      ram[addr] <= d;
    read_addr <= addr;
  end

  assign q = ram[read_addr];
endmodule
