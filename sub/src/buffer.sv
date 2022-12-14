`timescale 1ns / 1ps
`default_nettype none


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][15:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  // Your code here!
  
  logic [3:0][15:0] unmapped_line_buffer;

  logic [15:0] test_buff;

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

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_buff_0 (
    .addra(hcount_in),  // Port A address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    // .wea((write_line_buffer_index == 2'd0) && data_valid_in),                            // Port A write enable
    .wea((vcount_in[1:0] == 2'd0) && data_valid_in),                            // Port A write enable
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(unmapped_line_buffer[0])         // Port A RAM output data
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_buff_1 (
    .addra(hcount_in),  // Port A address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    // .wea((write_line_buffer_index == 2'd1) && data_valid_in),                            // Port A write enable
    .wea((vcount_in[1:0] == 2'd1) && data_valid_in),                            // Port A write enable
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(unmapped_line_buffer[1])         // Port A RAM output data
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_buff_2 (
    .addra(hcount_in),  // Port A address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    // .wea((write_line_buffer_index == 2'd2) && data_valid_in),                            // Port A write enable
    .wea((vcount_in[1:0] == 2'd2) && data_valid_in),                            // Port A write enable
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(unmapped_line_buffer[2])         // Port A RAM output data
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_buff_3 (
    .addra(hcount_in),  // Port A address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),           // Port A RAM input data
    .clka(clk_in),                           // Clock
    // .wea((write_line_buffer_index == 2'd3) && data_valid_in),                            // Port A write enable
    .wea((vcount_in[1:0] == 2'd3) && data_valid_in),                            // Port A write enable
    .ena(1'b1),                            // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),                            // Port B RAM Enable, for some reason need to be enabled?
    .rsta(rst_in),                           // Port A output reset (does not affect memory contents)
    .regcea(1'b1),                         // Port A output register enable
    .douta(unmapped_line_buffer[3])         // Port A RAM output data
  );

  localparam PIPE_LEN = 2;
  logic [10:0] hcount_pipe [PIPE_LEN-1:0];
  logic [9:0] vcount_pipe [PIPE_LEN-1:0];
  logic data_valid_pipe [PIPE_LEN-1:0];

  always_ff @(posedge clk_in) begin
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;
    data_valid_pipe[0] <= data_valid_in;
    for (int i=1; i<PIPE_LEN; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      data_valid_pipe[i] <= data_valid_pipe[i-1];
    end
  end

  // Combinationally determine which buffer to write to
  logic [1:0] write_line_buffer_index;
  assign write_line_buffer_index = vcount_in[1:0];

  assign hcount_out = rst_in ? 0 : hcount_pipe[PIPE_LEN - 1];
  assign vcount_out = rst_in ? 0 : (vcount_pipe[PIPE_LEN - 1] - 2) % 240;
  assign data_valid_out = rst_in ? 0 : data_valid_pipe[PIPE_LEN - 1];
  // assign hcount_out = rst_in ? 0 : hcount_in;
  // assign vcount_out = rst_in ? 0 : vcount_in;
  // assign data_valid_out = rst_in ? 0 : data_valid_in;

  // assign line_buffer_out[0] = 0;
  // assign line_buffer_out[1] = rst_in ? 0 : unmapped_line_buffer[(vcount_pipe[PIPE_LEN - 1] - 2) % 4];
  // assign line_buffer_out[1] = rst_in ? 0 : pixel_data_in;
  // assign line_buffer_out[2] = 0;

  assign line_buffer_out[0] = rst_in ? 0 : unmapped_line_buffer[(vcount_pipe[PIPE_LEN - 1] - 1) % 4];
  assign line_buffer_out[1] = rst_in ? 0 : unmapped_line_buffer[(vcount_pipe[PIPE_LEN - 1] - 2) % 4];
  assign line_buffer_out[2] = rst_in ? 0 : unmapped_line_buffer[(vcount_pipe[PIPE_LEN - 1] - 3) % 4];

endmodule


`default_nettype wire
