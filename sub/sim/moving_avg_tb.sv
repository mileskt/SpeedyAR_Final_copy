`timescale 1ns / 1ps
`default_nettype none

module moving_avg_tb;

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

    logic [10:0] value_in;
    logic [10:0] value_out;

    moving_avg #(.WIDTH(11)) uut_avg (.clk_in(clk_in),
      .valid_in(valid_in),
      .value_in(value_in),
      .value_out(value_out));
    center_of_mass uut(.clk_in(clk_in), .rst_in(rst_in),
                         .x_in(x_in),
                         .y_in(y_in),
                         .valid_in(valid_in),
                         .tabulate_in(tabulate_in),
                         .x_out(x_out),
                         .y_out(y_out),
                         .valid_out(valid_out));
    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("moving_avg.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,moving_avg_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)

        valid_in = 0;
        #10
        #10
        #10
        valid_in = 1;
        value_in = 45;
        #10
        valid_in = 0;
        #10
        #10
        #10
        valid_in = 1;
        value_in = 55;
        #10
        valid_in = 0;
        #10
        #10
        #10
        valid_in = 1;
        value_in = 65;
        #10
        valid_in = 0;
        #10
        #10
        #10
        valid_in = 1;
        value_in = 55;
        #10
        valid_in = 0;
        #10
        #10
        #10
        valid_in = 1;
        value_in = 65;
        #10
        valid_in = 0;

        x_in = 11'b0;
        y_in = 10'b0;
        valid_in = 0;
        tabulate_in = 0;
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;

        // Testing a 1000 x's and y's
        for (int i = 0; i<1000; i= i+1)begin
          x_in = i;
          y_in = i/2;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing a 1000 x's and y's
        for (int i = 0; i<1000; i= i+1)begin
          x_in = i;
          y_in = i/2;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing a 1000 x's and y's
        for (int i = 0; i<1000; i= i+1)begin
          x_in = i;
          y_in = i/2;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing a 1000 x's and y's
        for (int i = 0; i<1000; i= i+1)begin
          x_in = i;
          y_in = i/2;
          valid_in = 1;
          #10;
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing just one frame
        x_in = 111;
        y_in = 333;
        valid_in = 1;
        #10;
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing 1024 x 768 valid pixels
        for (int i = 0; i<1024; i= i+1)begin
          for (int j = 0; j<768; j= j+1)begin
            x_in = i;
            y_in = j;
            valid_in = 1;
            #10;
          end
        end
        valid_in = 0;
        #100;
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        // Testing no valid pixels
        tabulate_in = 1;
        #10;
        tabulate_in = 0;
        #1000;

        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire
