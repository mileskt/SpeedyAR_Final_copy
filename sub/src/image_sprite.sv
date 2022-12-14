`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module image_sprite #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [11:0] pixel_out);

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic in_sprite;
  assign in_sprite = ((hcount_pipe[PS8 - 1] >= x_in && hcount_pipe[PS8 - 1] < (x_in + WIDTH)) &&
                      (vcount_pipe[PS8 - 1] >= y_in && vcount_pipe[PS8 - 1] < (y_in + HEIGHT)));

  logic [7:0] image_out;

  localparam PS8 = 4;
  logic [10:0] hcount_pipe [PS8-1:0];
  logic [9:0] vcount_pipe [PS8-1:0];

  always_ff @(posedge pixel_clk_in)begin
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;
    for (int i=1; i<PS8; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(256 * 256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(image_out)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [11:0] palette_out;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(12),                       // Specify RAM data width
    .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette (
    .addra(image_out),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(palette_out)      // RAM output data, width determined from RAM_WIDTH
  );
  // Modify the line below to use your BRAMs!
  assign pixel_out = in_sprite ? palette_out : 0;
endmodule

`default_nettype wire
