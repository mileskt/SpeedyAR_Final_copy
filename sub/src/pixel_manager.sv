`timescale 1ns / 1ps
`default_nettype none

// Takes a given number of pixel x's and y's and writes them to bram and
// outputs the value at hcount_in, vcount_in

module pixel_manager #(
    parameter N_TRACKING_POINTS=4,
    parameter N_VIRTUAL_POINTS=8) (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    // not sure if we need this

    input wire [10:0] x_in,
    input wire [9:0] y_in,
    input wire [3:0] color_in,

    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic [3:0] pixel_out //output pixels of data (blah make this packed)
  );

  localparam WIDTH = 480;
  localparam HEIGHT = 640;
  localparam PIXELSHIFT = 4;

  // TESTING
  // xilinx_true_dual_port_read_first_1_clock_ram #(
  //   .RAM_WIDTH(16),                       // Specify RAM data width
  //   .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  // ) testing (
  //   .addra(hcount_in),  // Port A address bus, width determined from RAM_DEPTH
  //   // .dina(pixel_data_in),           // Port A RAM input data
  //   .clka(clk_in),                           // Clock
  //   // .wea((write_line_buffer_index == 2'd0) && data_valid_in),                            // Port A write enable
  //   // .wea((vcount_in[1:0] == 2'd0) && data_valid_in),                            // Port A write enable
  //   .wea(1'b0),                            // Port A write enable
  //   .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
  //   .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
  //   .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
  //   .regcea(1'b1),                         // Port A output register enable
  //   .douta(test_buff)         // Port A RAM output data
  // );

  logic [1:0] write_bram_index;
  logic [1:0] bram_outputs [2:0];
  logic [$clog2(N_VIRTUAL_POINTS) - 1:0] virtual_point_count;
  // write_bram_index - 1 % 3 -> read
  // write_bram_index - 2 % 3 -> clear

  localparam PIPE_LEN = 2;

  logic [10:0] hcount_pipe [PIPE_LEN-1:0];
  logic [9:0] vcount_pipe [PIPE_LEN-1:0];
  logic [1:0] write_bram_index_pipe [PIPE_LEN-1:0];

  always_ff @(posedge clk_in) begin
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;
    write_bram_index_pipe[0] <= write_bram_index;
    for (int i=1; i<PIPE_LEN; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      write_bram_index_pipe[i] <= write_bram_index_pipe[i-1];
    end
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      write_bram_index <= 0;
    end else if (hcount_in == WIDTH && vcount_in == HEIGHT) begin
        write_bram_index <= write_bram_index == 2 ? 0 : write_bram_index + 1;
    end
  end

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH((WIDTH*HEIGHT)),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) pixels_0 (
    .addra(write_bram_index == 2'b00 ? (x_in + y_in * WIDTH) : (hcount_in + vcount_in * WIDTH)),  // Port A address bus, width determined from RAM_DEPTH
    .dina(write_bram_index == 2'b00 ? color_in : 4'b0),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    .wea((write_bram_index == 2'b0 && color_in != 0 && x_in<WIDTH && y_in<HEIGHT && x_in>0 && y_in>0) || write_bram_index == 2'b10),                            // Port A write enable (when writing and still under the number of points, or clearing)
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(bram_outputs[0])         // Port A RAM output data
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH((WIDTH*HEIGHT)),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) pixels_1 (
    .addra(write_bram_index == 2'b10 ? (x_in + y_in * WIDTH) : (hcount_in + vcount_in * WIDTH)),  // Port A address bus, width determined from RAM_DEPTH
    .dina(write_bram_index == 2'b10 && x_in<WIDTH && y_in<HEIGHT && x_in>0 && y_in>0? color_in : 4'b0),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    .wea((write_bram_index == 2'b10 && color_in != 0 && x_in<WIDTH && y_in<HEIGHT && x_in>0 && y_in>0) || write_bram_index == 2'b01),                            // Port A write enable (when writing and still under the number of points, or clearing)
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(bram_outputs[1])         // Port A RAM output data
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(4),                       // Specify RAM data width
    .RAM_DEPTH((WIDTH*HEIGHT)),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) pixels_2 (
    .addra(write_bram_index == 2'b01 ? (x_in + y_in * WIDTH) : (hcount_in + vcount_in * WIDTH)),  // Port A address bus, width determined from RAM_DEPTH
    .dina(write_bram_index == 2'b01 && x_in<WIDTH && y_in<HEIGHT && x_in>0 && y_in>0 ? color_in : 4'b0),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    .wea((write_bram_index == 2'b01 && color_in != 0 && x_in<WIDTH && y_in<HEIGHT && x_in>0 && y_in>0) || write_bram_index == 2'b00),                            // Port A write enable (when writing and still under the number of points, or clearing)
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(bram_outputs[2])         // Port A RAM output data
  );

  assign hcount_out = rst_in ? 0 : hcount_pipe[PIPE_LEN - 1];
  assign vcount_out = rst_in ? 0 : (vcount_pipe[PIPE_LEN - 1] - 2) % 240;
  // assign pixel_out =  hcount_pipe[PIPE_LEN - 1]==11'd300 && vcount_pipe[PIPE_LEN - 1] ==10'd300 ? 1 : 0; //bram_outputs[(write_bram_index_pipe[PIPE_LEN - 1] + 1) % 3];
  assign pixel_out =  rst_in || hcount_pipe[PIPE_LEN - 1]>11'd480 || vcount_pipe[PIPE_LEN-1]>10'd640 ? 0: bram_outputs[(2'b11-write_bram_index_pipe[PIPE_LEN - 1]+1) % 3];
  // assign pixel_out =  1; //bram_outputs[(write_bram_index_pipe[PIPE_LEN - 1] + 1) % 3];


endmodule


`default_nettype wire
