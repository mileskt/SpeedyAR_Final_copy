`timescale 1ns / 1ps
`default_nettype none

module manager_tb;
  logic clk;
  logic rst;


    logic clk_in; //system clock
    logic rst_in; //system r
    logic [10:0] hcount_in; //current hcount being read
    logic [9:0] vcount_in;//current vcount being read
    // not sure if we need this
    logic data_valid_in; //incoming  valid data signal

    logic [10:0] x_in;
    logic [9:0] y_in;

    logic [10:0] hcount_out;
    logic [9:0] vcount_out;
    logic data_valid_out;
    logic pixel_out;


  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  pixel_manager #(
    .N_TRACKING_POINTS(4),
    .N_VIRTUAL_POINTS(8)
  ) p_manager (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .hcount_out(), // TODO: I don't think we need these
    .vcount_out(),
    .x_in(x_in),
    .y_in(y_in),
    .pixel_out(pixel_out));
  always begin
    #5;
    clk_in = !clk_in;
  end

  initial begin
    $dumpfile("manager.vcd");
    $dumpvars(0, manager_tb);
    $display("Starting Sim");
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;

    // Test mimic vcount and hcount of image
    for (int k =0; k<3; k=k+1)begin
        for (int i = 0; i<5; i= i+1)begin
            for (int j = 0; j<4; j= j+1)begin
                if (i==4 && j==3) begin
                    vcount_in = 640;
                    hcount_in = 320;
                end else begin
                    vcount_in = i;
                    hcount_in = j;
                end
                if (i==2) begin
                    x_in = 10;
                    y_in = j;
                end
                #10;
            end
        end
    end

    #100;

    $display("Finishing Sim");
    $finish;
  end
endmodule //buffer_tb

`default_nettype wire
