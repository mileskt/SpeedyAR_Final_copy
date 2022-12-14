`timescale 1ns / 1ps
`default_nettype none

module line_gen_tb;
    logic clk_in; //system clock
    logic rst_in; //system reset

    logic data_valid_in;

    logic [31:0] x_in;
    logic [31:0] y_in;

    logic [31:0] x; //current hcount being read
    logic [31:0] y; //current vcount bein
    logic [3:0] color_in;

    line_gen uut(.clk_in(clk_in), .rst_in(rst_in),
                         .x_in(x_in),
                         .y_in(y_in),
                         .color_in(color_in),
                         .data_valid_in(data_valid_in),
                         .x(x),
                         .y(y));

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("line_gen.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,line_gen_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10;  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10
        color_in=4'd1;
        data_valid_in = 1;
        // x_in=32'd200;
        // y_in=32'd480;
        x_in=32'd200;
        y_in=32'hFFFF_FFE0;
        #100
        x_in= 32'd300;
        y_in = 32'd160;
        #3000
        // x_in = 32'd200;
        // y_in = 32'd480;
        // #3000
        // x_in = 32'd300;
        // y_in = 32'd160;
        // #5000
        // x_in= 32'd300;
        // y_in = 32'd220;
        #10000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
