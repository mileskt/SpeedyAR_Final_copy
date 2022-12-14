
`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Kevin Zheng Class of 2012
// Dept of Electrical Engineering & Computer Science
//
// Create Date: 18:45:01 11/10/2010
// Design Name:
// Module Name: rgb2hsv
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module rgb2hsv(
	input wire clock,
	input wire reset,
	input wire [7:0] r,
	input wire [7:0] g,
	input wire [7:0] b,
	output reg [7:0] h,
	output reg [7:0] s,
	output reg [7:0] v
);
	logic [7:0] my_r_delay1, my_g_delay1, my_b_delay1;
	logic [7:0] my_r_delay2, my_g_delay2, my_b_delay2;
	logic [7:0] my_r, my_g, my_b;
	logic [7:0] min, max, delta;
	logic [15:0] s_top;
	logic [15:0] s_bottom;
	logic [15:0] h_top;
	logic [15:0] h_bottom;
	logic [15:0] s_quotient;
	logic [15:0] s_remainder;
	logic s_rfd;
	logic [15:0] h_quotient;
	logic [15:0] h_remainder;
	logic h_rfd;
	logic [7:0] v_delay [19:0];
	logic [18:0] h_negative;
	logic [15:0] h_add [18:0];
	logic [4:0] i;
	logic [31:0] hue_out;
	logic [17:0] s_res;
	logic [17:0] h_res;
	logic dout_valid_h;
	logic dout_valid_s;

	// Clocks 4-18: perform all the divisions 
	//the s_divider (16/16) has delay 18
	//the hue_div (16/16) has delay 18

	div_gen_0 hue_div1(
	.aclk(clock),
	.s_axis_dividend_tdata(s_top),
	.s_axis_dividend_tvalid(1),
	.s_axis_divisor_tdata(s_bottom),
	.s_axis_divisor_tvalid(1),
	.m_axis_dout_tdata(s_res),
	.m_axis_dout_tvalid(dout_valid_s)
	);
	assign s_quotient = s_res[17:2];
	assign s_remainder = s_res[1:0];

	div_gen_0 hue_div2(
	.aclk(clock),
	.s_axis_dividend_tdata(h_top),
	.s_axis_dividend_tvalid(1),
	.s_axis_divisor_tdata(h_bottom),
	.s_axis_divisor_tvalid(1),
	.m_axis_dout_tdata(h_res),
	.m_axis_dout_tvalid(dout_valid_h)
	);

	assign h_quotient = h_res[17:2];
	assign h_remainder = h_res[1:0];

	always @ (posedge clock) begin

	// Clock 1: latch the inputs (always positive)
	{my_r, my_g, my_b} <= {r, g, b};

	// Clock 2: compute min, max
	{my_r_delay1, my_g_delay1, my_b_delay1} <= {my_r, my_g, my_b};

	if((my_r >= my_g) && (my_r >= my_b)) begin //(B,S,S)
		max <= my_r;
	end else if((my_g >= my_r) && (my_g >= my_b)) begin //(S,B,S)
		max <= my_g;
	end else max <= my_b;

	if((my_r <= my_g) && (my_r <= my_b)) begin //(S,B,B)
		min <= my_r;
	end else if((my_g <= my_r) && (my_g <= my_b)) begin //(B,S,B)
		min <= my_g;
	end else begin
		min <= my_b;
	end
	// Clock 3: compute the delta
	{my_r_delay2, my_g_delay2, my_b_delay2} <= {my_r_delay1,
	my_g_delay1, my_b_delay1};
	v_delay[0] <= max;
	delta <= max - min;
	// Clock 4: compute the top and bottom of divisions
	s_top <= 8'd255 * delta;
	s_bottom <= (v_delay[0]>0)?{8'd0, v_delay[0]}: 16'd1;

	if(my_r_delay2 == v_delay[0]) begin
		h_top <= (my_g_delay2 >= my_b_delay2)?(my_g_delay2 -my_b_delay2)
		* 8'd255:(my_b_delay2 - my_g_delay2) * 8'd255;
		h_negative[0] <= (my_g_delay2 >= my_b_delay2)?0:1;
		h_add[0] <= 16'd0;
	end else if(my_g_delay2 == v_delay[0]) begin
		h_top <= (my_b_delay2 >= my_r_delay2)?(my_b_delay2 -my_r_delay2)
		* 8'd255:(my_r_delay2 - my_b_delay2) * 8'd255;
		h_negative[0] <= (my_b_delay2 >= my_r_delay2)?0:1;
		h_add[0] <= 16'd85;
	end else if(my_b_delay2 == v_delay[0]) begin
		h_top <= (my_r_delay2 >= my_g_delay2)?(my_r_delay2 -my_g_delay2)
		* 8'd255:(my_g_delay2 - my_r_delay2) * 8'd255;
		h_negative[0] <= (my_r_delay2 >= my_g_delay2)?0:1;
		h_add[0] <= 16'd170;
	end

	h_bottom <= (delta > 0)?delta * 8'd6:16'd6;


	//delay the v and h_negative signals 18 times
	for(i=1; i<19; i=i+1) begin
		v_delay[i] <= v_delay[i-1];
		h_negative[i] <= h_negative[i-1];
		h_add[i] <= h_add[i-1];
	end

	v_delay[19] <= v_delay[18];
	//Clock 22: compute the final value of h
	//depending on the value of h_delay[18], we need to subtract from it to make it come back around the circle
	if(h_negative[18] && (h_quotient > h_add[18])) begin
		h <= 8'd255 - h_quotient[7:0] + h_add[18];
	end else if(h_negative[18]) begin
		h <= h_add[18] - h_quotient[7:0];
	end else begin
		h <= h_quotient[7:0] + h_add[18];
	end
	//pass out s and v straight
	s <= s_quotient;
	v <= v_delay[19];
	end
endmodule
`default_nettype wire
