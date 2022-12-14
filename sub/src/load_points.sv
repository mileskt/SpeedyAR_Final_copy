`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module load_points #(
      parameter N_TRACKING_POINTS=4,
      parameter N_VIRTUAL_POINTS=48,
      parameter N_FRAMES=4
    ) (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire next_point,
    input wire [31:0] curr_frame,
    input wire [$clog2(N_FRAMES):0] offset,

    output wire [N_TRACKING_POINTS - 2:0][15:0] point_scalars,
    output wire [3:0] point_color
  );

  logic [$clog2(N_VIRTUAL_POINTS) - 1:0] index;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(52),                       // Specify RAM data width
    .RAM_DEPTH(N_VIRTUAL_POINTS*N_FRAMES),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image (
    .addra(index + (offset * N_VIRTUAL_POINTS)),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta({point_color, point_scalars})      // RAM output data, width determined from RAM_WIDTH
  );

  // assign point_color = 4'd1;
  // assign point_scalars = {16'h01_00, 16'h02_00, 16'h01_00};

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      index <= 0;
    end else begin
      if (next_point) begin
        index <= index == N_VIRTUAL_POINTS - 1 ? 0 : index + 1;
      end
    end
  end


endmodule


`default_nettype wire
