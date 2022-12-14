`timescale 1ns / 1ps
`default_nettype none

module vectors #(
      parameter N_TRACKING_POINTS=4,
      parameter N_VIRTUAL_POINTS=449608
    ) (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] red_x_com,
    input wire [9:0] red_y_com,
    input wire [10:0] purple_x_com,
    input wire [9:0] purple_y_com,
    input wire [10:0] green_x_com,
    input wire [9:0] green_y_com,
    input wire [10:0] blue_x_com,
    input wire [9:0] blue_y_com,
    input wire valid_blue,
    input wire valid_red,
    input wire valid_green,
    input wire valid_purple,

    output logic signed [N_TRACKING_POINTS - 2:0][15:0] ball_vectors_x,
    output logic signed [N_TRACKING_POINTS - 2:0][15:0] ball_vectors_y,

    output logic [10:0] red_x_stored,
    output logic [9:0] red_y_stored,
    output logic [10:0] blue_x_stored,
    output logic [9:0] blue_y_stored,
    output logic [10:0] purple_x_stored,
    output logic [9:0] purple_y_stored,
    output logic [10:0] green_x_stored,
    output logic [9:0] green_y_stored
  );

    logic has_green, has_red, has_purple, has_blue;
  //Center of Mass variables
  enum {IDLE, CALCULATING} state;

  always_ff @(posedge clk_in)begin
     if (rst_in)begin
        ball_vectors_x <= 0;
        ball_vectors_y <= 0;
     end else begin
        case(state)
            CALCULATING: begin
                state<=IDLE;
                ball_vectors_x[0] <= $signed({1'b0,green_x_stored}) - $signed({1'b0,red_x_stored});
                ball_vectors_y[0] <= $signed({1'b0,green_y_stored}) - $signed({1'b0,red_y_stored});
                ball_vectors_x[1] <= $signed({1'b0,blue_x_stored}) - $signed({1'b0,red_x_stored});
                ball_vectors_y[1] <= $signed({1'b0,blue_y_stored}) - $signed({1'b0,red_y_stored});
                ball_vectors_x[2] <= $signed({1'b0,purple_x_stored}) - $signed({1'b0,red_x_stored});
                ball_vectors_y[2] <= $signed({1'b0,purple_y_stored}) - $signed({1'b0,red_y_stored});
            end
            default: begin
                if (has_green && has_blue && has_red && has_purple)begin
                    state<=CALCULATING;
                    has_green<=0;
                    has_blue<=0;
                    has_purple<=0;
                    has_red<=0;
                end else begin
                    if(valid_red)begin
                    red_x_stored<=red_x_com;
                    red_y_stored<=red_y_com;
                    has_red<=1;
                    end
                    if(valid_blue)begin
                        blue_x_stored<=blue_x_com;
                        blue_y_stored<=blue_y_com;
                        has_blue<=1;
                    end
                    if(valid_purple)begin
                        purple_x_stored<=purple_x_com;
                        purple_y_stored<=purple_y_com;
                        has_purple<=1;
                    end
                    if(valid_green)begin
                        green_x_stored<=green_x_com;
                        green_y_stored<=green_y_com;
                        has_green<=1;
                    end
                end
            end
        endcase
    end
  end


endmodule


`default_nettype wire
