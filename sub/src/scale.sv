`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  always_comb begin
    case (scale_in)
      2'b00: cam_out = (hcount_in < 240 && vcount_in < 320) ? frame_buff_in : 16'h0000;
      2'b01: cam_out = (hcount_in < 480 && vcount_in < 640) ? frame_buff_in : 16'h0000;
      default: cam_out = (hcount_in < 640 && vcount_in < 853) ? frame_buff_in : 16'h0000;
    endcase
  end
endmodule


`default_nettype wire
