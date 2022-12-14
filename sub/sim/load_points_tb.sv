`timescale 1ns / 1ps
`default_nettype none

module load_points_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic next_point;
    logic [3:0] point_color;
    logic [2:0][15:0] point_scalars;


    load_points #(.N_TRACKING_POINTS(4), .N_VIRTUAL_POINTS(48))
            uut
            ( .clk_in(clk_in),
              .rst_in(rst_in),
              .next_point(next_point),
              .point_scalars(point_scalars),
              .point_color(point_color)
            );
    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("load_points.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,load_points_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        for (int i=0; i<48; i=i+1)begin
          next_point=1'b1;
          #10;
          next_point=1'b0;
          #10;
        end
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
