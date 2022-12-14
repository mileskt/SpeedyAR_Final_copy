`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  divider x_div(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(x_sum),
    .divisor_in(input_count),
    .data_valid_in(tabulate_in),
    .quotient_out(x_noisy),
    .remainder_out(),
    .data_valid_out(x_div_complete),
    .error_out(),
    .busy_out());

  divider y_div(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(y_sum),
    .divisor_in(input_count),
    .data_valid_in(tabulate_in),
    .quotient_out(y_noisy),
    .remainder_out(),
    .data_valid_out(y_div_complete),
    .error_out(),
    .busy_out());

  moving_avg #(.WIDTH(11)) x_avg (
    .clk_in(clk_in),
    .valid_in(x_div_complete),
    .value_in(x_noisy),
    .value_out(x_out));

  moving_avg #(.WIDTH(10)) y_avg(
    .clk_in(clk_in),
    .valid_in(y_div_complete),
    .value_in(y_noisy),
    .value_out(y_out));

  logic [31:0] x_sum;
  logic [31:0] y_sum;
  logic [31:0] input_count;
  logic x_div_complete;
  logic y_div_complete;
  logic division_partway_done;
  logic [10:0] x_noisy;
  logic [9:0] y_noisy;

  localparam SUMMING = 0;
  localparam DIVIDING = 1;
  logic state;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      x_sum <= 0;
      y_sum <= 0;
      input_count <= 0;
      valid_out <= 0;
      division_partway_done <= 0;
      state <= SUMMING;
    end else begin
      case (state)
        SUMMING: begin
          valid_out <= 0;
          if (tabulate_in && input_count != 0) state <= DIVIDING;
          else if (valid_in) begin
            x_sum <= (x_in>=11'd50)&&(x_in<=11'd430)&&(y_in>=10'd50)&&(y_in<=10'd600) ? x_sum + x_in : x_sum;
            y_sum <= (x_in>=11'd50)&&(x_in<=11'd430)&&(y_in>=10'd50)&&(y_in<=10'd600) ? y_sum + y_in: y_sum;
            input_count <= (x_in>=11'd50)&&(x_in<=11'd430)&&(y_in>=10'd50)&&(y_in<=10'd600) ? input_count + 1 : input_count;
          end
        end
        DIVIDING: begin
          // If they both finish at the same time, or one is done and the
          // other finished before, return the value and go back to summing
          if ((x_div_complete && y_div_complete) || ((x_div_complete || y_div_complete) && division_partway_done)) begin
            state <= SUMMING;
            valid_out <= 1;
            division_partway_done <= 0;
            x_sum <= 0;
            y_sum <= 0;
            input_count <= 0;
          end else if (x_div_complete || y_div_complete) division_partway_done <= 1;
        end
        default: ;
      endcase
    end
  end

endmodule

`default_nettype wire
