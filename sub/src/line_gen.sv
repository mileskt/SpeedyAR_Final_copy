`timescale 1ns / 1ps
`default_nettype none

module line_gen (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire data_valid_in, // 1

    input wire signed [31:0] x_in,
    input wire signed [31:0] y_in,
    input wire [3:0] color_in,

    output logic signed [31:0] x_start_test,
    output logic signed [31:0] y_start_test,
    output logic signed [31:0] x_end_test,
    output logic signed [31:0] y_end_test,

    output logic signed [31:0] x, //current hcount being read
    output logic signed [31:0] y, //current vcount being read
    output logic [3:0] color, //current vcount being read
    output logic next_point
  );

  logic signed [31:0] x_start;
  logic signed [31:0] y_start;

  logic signed [31:0] x_end;
  logic signed [31:0] y_end;
  logic signed [3:0] color_end;

  assign x_start_test = x_start;
  assign y_start_test = y_start;
  assign x_end_test = x_end;
  assign y_end_test = y_end;

  logic has_first_point;
  logic signed [31:0] dx;
  logic signed [31:0] dy;
  logic sx, sy;
  logic signed [31:0] err;
  enum {IDLE, DRAWING} state;

  // assign test_display = {3'b0, state, 3'b0, has_first_point, 3'b0, next_point, x_end, y_end >>> 3};
  // assign test_display = {3'b0, state, 3'b0, has_first_point, 3'b0, next_point, x_end, y_end >>> 3};
  // assign test_display = {x_end, 1'b0, y_end};
  // assign test_display = {x_start, 1'b0, y_start};

  always_ff @(posedge clk_in)begin
    if (rst_in) begin
      dx <= 0;
      dy <= 0;
      sx <= 1;
      sy <= 1;
      err <= 0;
      x<=0;
      y<=0;
      state <= IDLE;
      has_first_point <= 0;
      next_point <= 0;
    end else begin
    case(state)
      DRAWING: begin
        next_point <= 0;
        //if we have reached the end of the line stop drawing
        if(x_end==x && y_end==y)begin
          state <= IDLE;
        //need this case due to verilog quirk
        end else if (2*err>=dy && 2*err<=dx) begin
          x <= sx ? x+1 : x-1;
          y <= sy ? y+1 : y-1;
          err <= err + dx + dy;
        end else if(2*err>=dy) begin
          x <= sx ? x+1 : x-1;
          err <= err + dy;
        end else if(2*err<=dx) begin
          y <= sy ? y + 1 : y - 1;
          err <= err + dx;
        end
      end
      default: begin
        if(data_valid_in)begin
          if (!has_first_point) begin
            has_first_point <= 1;
            x_end <= x_in;
            y_end <= y_in;
            color <= color_in;
          end else begin
            next_point <= 1;
            state <= DRAWING;
            //calculate current deltas
            dx = x_in>x_end ? $signed(x_in)-$signed(x_end) : $signed(x_end)-$signed(x_in);
            sx = x_end<x_in ? 1 : 0;
            dy = y_in>y_end ? $signed(y_end)-$signed(y_in) : $signed(y_in)-$signed(y_end);
            sy = y_end<y_in ? 1 : 0;
            err <= (x_in>x_end ? $signed(x_in)-$signed(x_end) : $signed(x_end)-$signed(x_in)) + (y_in>y_end ? $signed(y_end)-$signed(y_in) : $signed(y_in)-$signed(y_end));
            x <= x_end;
            y <= y_end;
            x_end <= x_in;
            y_end <= y_in;
            color_end <= color_in;
            x_start <= x_end;
            y_start <= y_end;
            color <= color_end;
          end
        end //else begin
        //   has_first_point<=1'b0;
        // end
      end
    endcase
    end
  end
endmodule
`default_nettype wire
