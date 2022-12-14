`timescale 1ns / 1ps
`default_nettype none


module projection #(
      parameter N_TRACKING_POINTS=4,
      parameter N_VIRTUAL_POINTS=8
    ) (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire signed [N_TRACKING_POINTS - 2:0][15:0] x_vec,
    input wire signed [N_TRACKING_POINTS - 2:0][15:0] y_vec,

    input wire signed [N_TRACKING_POINTS - 2:0][15:0] point_scalars,
    input wire [3:0] point_color,

    input wire [10:0] x_origin,
    input wire [9:0] y_origin,

    output logic signed [31:0] x_proj,
    output logic signed [31:0] y_proj,

    output logic [3:0] color_proj
  );

  logic [$clog2(N_VIRTUAL_POINTS) - 1:0] index;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      index <= 0;
      x_proj <= 0;
      y_proj <= 0;
      color_proj <= 0;
    end else begin
        x_proj <= ((($signed({x_vec[0],8'b0})*$signed(point_scalars[0]))>>>16)+
                  (($signed({x_vec[1],8'b0})*$signed(point_scalars[1]))>>>16)+
                  (($signed({x_vec[2],8'b0})*$signed(point_scalars[2]))>>>16))+$signed({1'b0,x_origin});
        y_proj <= ((($signed({y_vec[0],8'b0})*$signed(point_scalars[0]))>>>16)+
                  (($signed({y_vec[1],8'b0})*$signed(point_scalars[1]))>>>16)+
                  (($signed({y_vec[2],8'b0})*$signed(point_scalars[2]))>>>16))+$signed({1'b0,y_origin});
        color_proj <= point_color;
    end
  end


endmodule


`default_nettype wire
