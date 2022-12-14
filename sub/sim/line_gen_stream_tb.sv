`timescale 1ns / 1ps
`default_nettype none

module line_gen_stream_tb;
    logic clk_in; //system clock
    logic rst_in; //system reset

    logic data_valid_in;

    // logic [10:0] x_in;
    // logic [9:0] y_in;

    logic [10:0] x; //current hcount being read
    logic [9:0] y; //current vcount bein
    logic new_input;

    localparam N_TRACKING_POINTS=4;

    logic [N_TRACKING_POINTS - 2:0][15:0] x_vec;
    logic [N_TRACKING_POINTS - 2:0][15:0] y_vec;

    logic [10:0] x_origin;
    logic [9:0] y_origin;

    logic [10:0] x_proj;
    logic [9:0] y_proj;

    line_gen uut(.clk_in(clk_in), .rst_in(rst_in),
                         .x_in(x_proj),
                         .y_in(y_proj),
                         .data_valid_in(data_valid_in),
                         .next_point(new_input),
                         .x(x),
                         .y(y));

    projection uut_1(.clk_in(clk_in), .rst_in(rst_in),
                         .x_vec(x_vec),
                         .y_vec(y_vec),
                         .x_origin(x_origin),
                         .y_origin(y_origin),
                         .x_proj(x_proj),
                         .y_proj(y_proj),
                         .next_point(new_input));

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("line_gen_stream.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,line_gen_stream_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_vec = 48'b0;
        y_vec = 48'b0;
        x_origin = 11'b0;
        y_origin = 10'b0;
        #10;  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        x_vec = {16'h00_03, 16'h00_08, 16'h00_09};
        y_vec = {16'h00_05, 16'h00_02, 16'h00_04};
        data_valid_in = 1;
        #60000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
