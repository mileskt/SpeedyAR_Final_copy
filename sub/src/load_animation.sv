`timescale 1ns / 1ps
`default_nettype none

module load_animation #(
      parameter N_TRACKING_POINTS=4,
      parameter N_VIRTUAL_POINTS=48,
      parameter N_FRAMES=4
    ) (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire next_point,

    output wire [N_TRACKING_POINTS - 2:0][15:0] point_scalars,
    output wire [3:0] point_color
  );

  localparam N_CYCLES_PER_FRAME = 8388608; //640*480*300 almost but actually 2^23

  logic [$clog2(N_CYCLES_PER_FRAME) + $clog2(N_FRAMES) - 1:0] counter;
  logic [$clog2(N_CYCLES_PER_FRAME) + $clog2(N_FRAMES) - 1:0] next_counter;

  load_points #(
    .N_TRACKING_POINTS(N_TRACKING_POINTS),
    .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS),
    .N_FRAMES(N_FRAMES)
  ) point_load (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .next_point(next_point),
    .offset(counter[$clog2(N_CYCLES_PER_FRAME) + $clog2(N_FRAMES) - 1:$clog2(N_CYCLES_PER_FRAME)]),
    .point_scalars(point_scalars),
    .point_color(point_color)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in || next_counter[$clog2(N_CYCLES_PER_FRAME) + $clog2(N_FRAMES) - 1:$clog2(N_CYCLES_PER_FRAME)] >= N_FRAMES) begin
      counter <= 0;
      next_counter <= 1;
    end else begin
      counter <= counter + 1;
      next_counter <= next_counter + 1;
    end
  end


endmodule


`default_nettype wire
