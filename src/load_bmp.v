`define IMAGE_SOURCE   "lena_256x256.bmp"
`define IMAGE_OUTPUT   "lena_output.bmp"
`define IMAGE__GRAY_OUTPUT   "lena_gray_output.bmp"
`define IMAGE_GRAY_HEX "img_gray_hex.txt"
`define IMAGE_GRAY_DEC "img_gray_dec.txt"
`define EDGE_OUTPUT    "out_log.txt"
`define FSDB_FILE      "filter.fsdb"

module load_bmp(
  clk,
  rst_n,
  start,
  fc_valid,
  fc,
  out_pixel,
  out_valid
);
  parameter period = 1000;
  parameter delay = 1;
  integer img_in, img_out,img_gray_out, cc, out_log, gray_dec, gray_hex;
  output reg clk;
  output reg rst_n;
  output reg start;
  output reg fc_valid;
  output reg signed [7:0] fc;

  input [7:0] out_pixel;
  input out_valid;

  reg [7:0] bmp_data [0:2000000];
  reg [23:0] bmp_new [0:255][0:255];
  reg [23:0] tmp_data;
  integer bmp_width, bmp_height, data_start_index, bmp_size,
      pixel_bits, reserve1, reserve2, image_size;
  integer i, j, index;
  integer debug=3;                // debug flag
  integer r;
  reg signed [8:0] index_x;
  reg signed [8:0] index_y;
  reg signed [3:0] m,n;

  initial begin
    //$fsdbDumpfile(`FSDB_FILE);
    //$fsdbDumpvars;
  end

  initial begin

    // setting the debug level
    if ($value$plusargs("debug=%d", debug)) begin
      $display(">> Debug level = %d", debug);
    end else begin
      debug = 0;
    end

    // File handlers
    img_in = $fopen(`IMAGE_SOURCE, "rb");
    //gray_dec = $fopen(`IMAGE_GRAY_DEC, "wd");
    //gray_hex = $fopen(`IMAGE_GRAY_HEX, "wd");
    //out_log = $fopen(`EDGE_OUTPUT, "wd");
    //img_out = $fopen(`IMAGE_OUTPUT, "wb");
    gray_dec = $fopen(`IMAGE_GRAY_DEC, "w");
    gray_hex = $fopen(`IMAGE_GRAY_HEX, "w");
    out_log = $fopen(`EDGE_OUTPUT, "w");
    img_out = $fopen(`IMAGE_OUTPUT, "wb");
	img_gray_out = $fopen(`IMAGE__GRAY_OUTPUT, "wb");
    // Read the input BMP image
    $display(">> Reading the image file: %s", `IMAGE_SOURCE);
    cc = $fread(bmp_data, img_in);
    $fclose(img_in);

    // Parse the BMP header
    // Don't worry about the header processing
    $display(">> Parsing the image file header...");
    reserve1 = {bmp_data[7], bmp_data[6]};
    reserve2 = {bmp_data[9], bmp_data[8]};
    pixel_bits = {bmp_data[29], bmp_data[28]};
//    $display("pixel_bits: %d", pixel_bits);
    bmp_width = {bmp_data[21], bmp_data[20], bmp_data[19], bmp_data[18]};
//    $display("width: %d", bmp_width);
    bmp_height = {bmp_data[25], bmp_data[24], bmp_data[23], bmp_data[22]};
//    $display("height: %d", bmp_height);
    data_start_index = {bmp_data[13], bmp_data[12], bmp_data[11], bmp_data[10]};
//    $display("start_index: %d", data_start_index);
    bmp_size = {bmp_data[5], bmp_data[4], bmp_data[3], bmp_data[2]};
    image_size = {bmp_data[37], bmp_data[36], bmp_data[35], bmp_data[34]};
	
    // writing the BMP file header to output image
	$display(">> Write BMP File header...");
    for(i = 0; i < data_start_index; i = i + 1) begin
		//$fwrite(img_out, "%c", bmp_data[i]);
		r=$fputc(bmp_data[i],img_out);
		r=$fputc(bmp_data[i],img_gray_out);
    end
	$display(">> Write BMP File header done.");
	
	
    // obtain pixel values from the BMP image
    // and convert them to gray scale
    $display(">> Converting to gray scale...");
    $display(">> Writing to gray-scale decimal values to %s", `IMAGE_GRAY_DEC);
    $display(">> Writing to gray-scale hexadecimal values to %s", `IMAGE_GRAY_HEX);
    for(i = 0; i < 256; i = i + 1) begin
      for(j = 0; j < 256; j = j + 1) begin
        index = i * 256 * 3 + j * 3 + data_start_index;
        //bmp_new[i][j][23:16] = bmp_data[index+2]; // Red
        //bmp_new[i][j][15:8] = bmp_data[index+1];  // Green
        //bmp_new[i][j][7:0] = bmp_data[index];     // Blue
		
        // writing the gray scale value in decimal
        $fwrite(gray_dec, "%d\n",
          (bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3);
        // writing the gray scale value in hexadecimal
        $fwrite(gray_hex, "%2h\n",
          (bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3);
		
      end
    end



    $fclose(gray_dec);
    $fclose(gray_hex);
  end
  
  // create the clock
  always #(period/2) clk = ~clk;

  // test patterns
  initial begin
    clk = 0;
    rst_n = 1;
    fc_valid =0;
    fc = 0;
    start = 0;
    #(delay) rst_n = 0;
    #(period) rst_n = 1;
    #(period) start = 1;

    // Output the filter coefficients to filter.v
    // You may see there are 25 coefficients, where the 13th is 24,
    // and all others are -1
    // The signal fc_valid will be high during these 25 cycles; 
    // It will be zero otherwise.
    for (i = 0; i < 5; i = i + 1 ) begin
      for (j = 0; j < 5; j = j + 1) begin
        #(period)
        fc_valid = 1;
        $write(">> Filter Coeff [%2d][%2d] = ", i, j);
        if (i == 2 && j == 2) begin
          fc = 24;
          $write("24\n");
        end else begin
          fc = -1;
          $write("-1\n");
        end
      end
    end
    #(period) fc_valid = 0;
    $display(">> Filter coeff done.");
	
	// Output gray image
    for(i = 0; i < 256; i = i + 1) begin
      for(j = 0; j < 256; j = j + 1) begin
        index = i * 256 * 3 + j * 3 + data_start_index;
		r=$fputc((bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3,img_gray_out);
		r=$fputc((bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3,img_gray_out);
		r=$fputc((bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3,img_gray_out);
        //$fwrite(img_gray_out, "%c", (bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3); //B
        //$fwrite(img_gray_out, "%c", (bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3); //G
        //$fwrite(img_gray_out, "%c", (bmp_data[index+2] + bmp_data[index+1] + bmp_data[index]) / 3); //R

      end
    end

    // Obtain the output pixel from filter.v and write it out to the BMP
    // image file.
    //
    for(i = 0; i < 256 ; i  = i + 1) begin
      for(j = 0; j< 256; j = j + 1) begin
        @(posedge out_valid)

        if (debug >= 3)
          $display(">> Computed pixel value [%4d][%4d] = %d", i, j, out_pixel);
        $fwrite(img_out, "%c", out_pixel); //B
        $fwrite(img_out, "%c", out_pixel); //G
        $fwrite(img_out, "%c", out_pixel); //R

        // We also write the decimal value to the log file for your validation
        $fwrite(out_log, "%d\n", out_pixel);
      end
    end
	$display(">> Output Done");
    $fclose(img_out);
    $fclose(out_log);

    // delay 100 more cycles
    #(period*100)
    $finish;

    // enjoy the Verilog coding
  end
endmodule
