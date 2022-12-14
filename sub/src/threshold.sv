module threshold(
  input wire [2:0] sel_in,
  input wire [3:0] r_in, g_in, b_in,
  input wire [7:0] h_in, s_in, v_in,
  input wire [7:0] h_thresh_high, h_thresh_low, s_thresh_high, s_thresh_low, v_thresh_high, v_thresh_low,
  output logic mask_out,
  // channel out fixed to zero
  output logic [3:0] channel_out
);

  // logic [3:0] channel;
  // assign channel_out = channel;
  assign channel_out = 0;
  // always_comb begin
  //   case (sel_in)
  //     3'b000: channel = g_in;
  //     3'b001: channel = r_in;
  //     3'b010: channel = b_in;
  //     3'b011: channel = 0;
  //     3'b100: channel = y_in;
  //     3'b101: channel = cr_in;
  //     3'b110: channel = cb_in;
  //     3'b111: channel = 0;
  //     default: channel = 0;
  //   endcase
  // end
  // assign mask_out = (channel[2:0] > lower_bound_in) && (channel[3:1] < upper_bound_in);
  assign mask_out =
    (h_in >= h_thresh_low) && (h_in <= h_thresh_high) &&
    (s_in >= s_thresh_low) && (s_in <= s_thresh_high) &&
    (v_in >= v_thresh_low) && (v_in <= v_thresh_high);
endmodule


/*

sw[6]:
  - 1 masked values through
  - 0 regular image through

sw[7]
*/
