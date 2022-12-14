`timescale 1ns / 1ps
`default_nettype none

module vectors_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [10:0] x_in;
    logic [9:0] y_in;
    logic valid_in;
    logic tabulate_in;
    logic [10:0] x_out;
    logic [9:0] y_out;
    logic valid_out;

    logic [10:0] red_x_com;
    logic [9:0] red_y_com;
    logic [10:0] purple_x_com;
    logic [9:0] purple_y_com;
    logic [10:0] green_x_com;
    logic [9:0] green_y_com;
    logic [10:0] blue_x_com;
    logic [9:0] blue_y_com;
    logic valid_blue;
    logic valid_red;
    logic valid_green;
    logic valid_purple;

    logic signed [2:0][15:0] ball_vectors_x;
    logic signed [2:0][15:0] ball_vectors_y;

    vectors uut(
            .clk_in(clk_in), .rst_in(rst_in),
            .red_x_com(red_x_com),
            .red_y_com(red_y_com),
            .purple_x_com(purple_x_com),
            .purple_y_com(purple_y_com),
            .green_x_com(green_x_com),
            .green_y_com(green_y_com),
            .blue_x_com(blue_x_com),
            .blue_y_com(blue_y_com),
            .valid_blue(valid_blue),
            .valid_red(valid_red),
            .valid_green(valid_green),
            .valid_purple(valid_purple),
            .ball_vectors_x(ball_vectors_x),
            .ball_vectors_y(ball_vectors_y)
            );
    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("vectors.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,vectors_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        valid_blue=1;
        valid_red=1;
        valid_green=1;
        valid_purple=1;
        red_x_com=11'd300;
        red_y_com=10'd300;
        purple_x_com=11'd300;
        purple_y_com=10'd200;
        green_x_com=11'd400;
        green_y_com=10'd300;
        blue_x_com=11'd250;
        blue_y_com=10'd350;
        #10;
        valid_blue=0;
        valid_red=0;
        valid_green=0;
        valid_purple=0;
        #10000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
