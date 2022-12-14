`timescale 1ns / 1ps
`default_nettype none

module moving_avg #(
      parameter WIDTH=11
    ) (
                         input wire clk_in,
                         input wire valid_in,
                         input wire [WIDTH-1:0] value_in,
                         output logic [WIDTH-1:0] value_out);

  logic [WIDTH-1:0] fifo [3:0];
  logic [WIDTH+1:0] sum;

  always_ff @(posedge clk_in)begin
    if (valid_in) begin
      fifo[0] <= value_in;
      for (int i=1; i<4; i = i+1)begin
        fifo[i] <= fifo[i - 1];
      end
    end
  end

  assign sum = fifo[0] + fifo[1] + fifo[2] + fifo[3];
  assign value_out = sum[WIDTH+1:2];
endmodule

`default_nettype wire
