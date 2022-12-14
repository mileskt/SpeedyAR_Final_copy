`timescale 1ns / 1ps
`default_nettype none

module projection_tb;

    //make logics for inputs and outputs!
    localparam N_TRACKING_POINTS=4;

    logic clk_in;
    logic rst_in;

    // logic signed [N_TRACKING_POINTS - 2:0][15:0] x_vec;
    // logic signed [N_TRACKING_POINTS - 2:0][15:0] y_vec;
    logic signed [N_TRACKING_POINTS - 2:0][15:0] point_scalars;


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

    vectors uut1(
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

    logic signed [31:0] x_proj;
    logic signed [31:0] y_proj;
    logic signed [31:0] test_val;
    logic signed [10:0] other_val;
    logic [3:0] point_color;
    logic [3:0] color_proj;

    logic signed [31:0] x; //current hcount being read
    logic signed [31:0] y;

    projection uut(.clk_in(clk_in), .rst_in(rst_in),
                .x_vec(ball_vectors_x),
                .y_vec(ball_vectors_y),
                .x_origin(red_x_com),
                .point_color(point_color),
                .y_origin(red_y_com),
                .point_scalars(point_scalars),
                .x_proj(x_proj),
                .y_proj(y_proj),
                .color_proj(color_proj));


    line_gen uut2(.clk_in(clk_in), .rst_in(rst_in),
                    .x_in(x_proj),
                    .y_in(y_proj),
                    .color_in(color_proj),
                    .data_valid_in(1'b1),
                    .x(x),
                    .y(y));



    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("projection.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,projection_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        point_color = 4'd1;
        point_scalars = {16'h0000, 16'h0000, 16'h0100};
        red_x_com<=0;
        red_y_com<=0;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        // #10;

        // x_vec = {16'b1111111111111101, 16'b1111111111111000, 16'b1111111111110111};

        #10
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
        #10

        #100

        // test_val =  (((x_vec[0]<<<8)*point_scalars[0])>>>16)+
        //             (((x_vec[1]<<<8)*point_scalars[1])>>>16)
        //             +((x_vec[2]<<<8)* (point_scalars[2])>>>16)+$signed({1'b0,x_origin});
        // #10
        // other_val=((((x_vec[0]<<<8 * point_scalars[0])>>>16) +
        //             ((x_vec[1]<<<8 * point_scalars[1])>>>16) +
        //             ((x_vec[2]<<<8 * point_scalars[2])>>>16))) + $signed({1'b0, x_origin});
        // other_val=$signed(test_val)+$signed({1'b0,y_origin});

        // x_vec = {16'h00_03, 16'h00_08, 16'h00_09};
        // y_vec = {16'h00_05, 16'h00_02, 16'h00_04};

        // Testing a 1000 x's and y's
        // for (int i = 0; i<1000; i= i+1)begin
        //   x_in = i;
        //   y_in = i/2;
        //   valid_in = 1;
        //   #10;
        // end
        // valid_in = 0;
        // #100;
        // tabulate_in = 1;
        // #10;
        // tabulate_in = 0;
        // #10000;

        // // Testing just one frame
        // x_in = 111;
        // y_in = 333;
        // valid_in = 1;
        // #10;
        // valid_in = 0;
        // #100;
        // tabulate_in = 1;
        // #10;
        // tabulate_in = 0;
        // #10000;

        // // Testing 1024 x 768 valid pixels
        // for (int i = 0; i<1024; i= i+1)begin
        //   for (int j = 0; j<768; j= j+1)begin
        //     x_in = i;
        //     y_in = j;
        //     valid_in = 1;
        //     #10;
        //   end
        // end
        // valid_in = 0;
        // #100;
        // tabulate_in = 1;
        // #10;
        // tabulate_in = 0;
        // #10000;

        // // Testing no valid pixels
        // tabulate_in = 1;
        // #10;
        // tabulate_in = 0;
        #10000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
