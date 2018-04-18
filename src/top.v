module top;
  wire clk;
  wire rst_n;
  wire start;
  wire [15:0] addr;
  wire wen;
  wire out_valid;
  wire [7:0] d;
  wire [7:0] q;
  wire signed [7:0] fc;
  wire [7:0] out_pixel;

  load_bmp testbench (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .fc_valid(fc_valid),
    .fc(fc),
    .out_pixel(out_pixel),
    .out_valid(out_valid)
  );

  sram65536x8 sram (
    .clk(clk),
    .wen(wen),
    .addr(addr),
    .d(d),
    .q(q)
  );

  filter filt (
    .clk(clk),
    .rst_n(rst_n),
    .fc_valid(fc_valid),
    .working_pixel(q),
    .wen(wen),
    .fc(fc),
    .out_pixel(out_pixel),
    .out_valid(out_valid),
    .d(d),
    .addr(addr),
    .start(start)
  );

endmodule
