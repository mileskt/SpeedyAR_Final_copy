`timescale 1ns / 1ps
`default_nettype none

module convolution_tb;
  logic clk;
  logic rst;

  logic [2:0][15:0] data;
  logic [10:0] hcount_in, identity_hcount_out, edge_hcount_out;
  logic [9:0] vcount_in, identity_vcount_out, edge_vcount_out;
  logic data_valid_in, identity_data_valid_out, edge_data_valid_out;
  logic [15:0] identity_line_out;
  logic [15:0] edge_line_out;

  logic [4:0] i_r, e_r;
  logic [5:0] i_g, e_g;
  logic [4:0] i_b, e_b;

  assign i_r = identity_line_out[15:11];
  assign i_g = identity_line_out[10:5];
  assign i_b = identity_line_out[4:0];

  assign e_r = edge_line_out[15:11];
  assign e_g = edge_line_out[10:5];
  assign e_b = edge_line_out[4:0];

  parameter K_SELECT = 0;

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  convolution #(
    .K_SELECT(K_SELECT)
    ) identity (
    .clk_in(clk),
    .rst_in(rst),
    .data_in(data),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .data_valid_in(data_valid_in),

    .data_valid_out(identity_data_valid_out),
    .hcount_out(identity_hcount_out),
    .vcount_out(identity_vcount_out),
    .line_out(identity_line_out));

  convolution #(
    .K_SELECT(3'b100)
    ) edge_detecting (
    .clk_in(clk),
    .rst_in(rst),
    .data_in(data),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .data_valid_in(data_valid_in),

    .data_valid_out(edge_data_valid_out),
    .hcount_out(edge_hcount_out),
    .vcount_out(edge_vcount_out),
    .line_out(edge_line_out));

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("convolution.vcd");
    $dumpvars(0, convolution_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    // $display("Test 1: {test description}");
    // data_valid_in = 1;
    // data[0] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data[1] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data[2] = {5'd0, 6'd0, 5'd0};
    // #10;
    // data_valid_in = 0;
    // $display("line_out: (unsigned): %h", identity_line_out);
    // $display("RGB: %3d %3d %3d", i_r, i_g, i_b);
    // #20;

    $display("Test 2: {test description}");
    for (int i = 0; i<4; i= i+1)begin
      for (int j = 0; j<10; j= j+1)begin
        vcount_in = i;
        hcount_in = j;
        data_valid_in = 1;
        data[0] = {5'd5, 6'd5, 5'd5};
        data[1] = {5'b11111, 6'b111111, 5'b00000};
        data[2] = {5'd5, 6'd5, 5'd5};
        $display("identity_line_out: (unsigned): %h", identity_line_out);
        $display("RGB: %3d %3d %3d", i_r, i_g, i_b);
        $display("RGB: %5b %6b %5b", i_r, i_g, i_b);
        #10;
      end
    end


    // $display("Test 2: {test description}");
    // for (int i = 0; i<4; i= i+1)begin
    //   for (int j = 0; j<10; j= j+1)begin
    //     vcount_in = i;
    //     hcount_in = j;
    //     data_valid_in = 1;
    //     data[0] = {5'd2, 6'd2, 5'd2};
    //     data[1] = {5'd0, 6'd1, 5'd0};
    //     data[2] = {5'd2, 6'd2, 5'd2};
    //     $display("identity_line_out: (unsigned): %h", identity_line_out);
    //     $display("RGB: %3d %3d %3d", i_r, i_g, i_b);
    //     #10;
    //   end
    // end

    // // X edge detection
    // $display("Test 2: {test description}");
    // for (int i = 0; i<4; i= i+1)begin
    //   for (int j = 0; j<10; j= j+1)begin
    //     vcount_in = i;
    //     hcount_in = j;
    //     data_valid_in = 1;
    //     data[0] = {5'd1, 6'd1, 5'd1};
    //     data[1] = {5'd1, 6'd1, 5'd1};
    //     data[2] = {5'd0, 6'd0, 5'd0};
    //     $display("edge_line_out: (unsigned): %h", edge_line_out);
    //     $display("RGB: %3d %3d %3d", e_r, e_g, e_b);
    //     #10;
    //   end
    // end

    // #100;

    // // Test mimic vcount and hcount of image
    // for (int i = 0; i<240; i= i+1)begin
    //   for (int j = 0; j<320; j= j+1)begin
    //     vcount_in = i;
    //     hcount_in = j;
    //     data[0] = {5'd2, 6'd2, 5'd2};
    //     data[1] = {5'd0, 6'd1, 5'd0};
    //     data[2] = {5'd2, 6'd2, 5'd2};
    //     data_valid_in = 1;
    //     $display("identity_line_out: (unsigned): %h", identity_line_out);
    //     $display("RGB: %3d %3d %3d", i_r, i_g, i_b);
    //     $display("Hcount, Vcount: %3d %3d", identity_hcount_out, identity_vcount_out);
    //     #10;
    //   end
    // end

    #100;


    $display("Finishing Sim");
    $finish;
  end
endmodule // convolution_tb

`default_nettype wire
