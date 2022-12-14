module vga_mux (
  input wire [3:0] sel_in, //regular video
  input wire [11:0] camera_pixel_in,
  input wire [3:0] camera_y_in,
  input wire [3:0] channel_in,
  input wire thresholded_pixel_in,
  input wire [11:0] com_sprite_pixel_in,
  input wire [3:0] projection_mask_pixel,
  input wire red_crosshair_in,
  input wire green_crosshair_in,
  input wire blue_crosshair_in,
  input wire purple_crosshair_in,
  output logic [11:0] pixel_out
);

  /*
  00: normal camera out
  01: channel image (in grayscale)
  10: (thresholded channel image b/w)
  11: y channel with magenta mask

  upper bits:
  00: nothing:
  01: crosshair
  10: sprite on top
  11: nothing (magenta test color)
  */
  logic [1:0] mask_video_thresh; //
  assign mask_video_thresh = sel_in[1:0];

  logic [1:0] options;
  assign options = sel_in[3:2];
  logic [11:0] l_2;
  logic seen_mask;
  always_comb begin
      case(projection_mask_pixel)
        4'd1:l_2=12'hE25;
        4'd2:l_2=12'h4B5;
        4'd3:l_2=12'hFE2;
        4'd4:l_2=12'h46E;
        4'd5:l_2=12'hF83;
        4'd6:l_2=12'h92B;
        4'd7:l_2=12'h4DF;
        4'd8:l_2=12'hF3E;
        4'd9:l_2=12'hCF4;
        4'd10:l_2=12'hFCD;
        4'd11:l_2=12'h4A9;
        4'd12:l_2=12'hECF;
        4'd13:l_2=12'hA62;
        4'd14:l_2=12'hFFD;
        4'd15:l_2=12'h800;
        default: l_2=camera_pixel_in;//green_crosshair_in ? 12'h0F0: camera_pixel_in//red_crosshair_in ? 12'hF00: blue_crosshair_in ? 12'h00F: purple_crosshair_in ? 12'hF0F : camera_pixel_in;

    endcase
  end
  // TESTING WITH THRESHOLDS
  // assign pixel_out = thresholded_pixel_in ? 12'hFFF : 12'h0;
  // TESTING WITH THRESHOLDS AND THRESHOLDS
  // assign pixel_out = green_crosshair_in ? 12'h0F0: red_crosshair_in ? 12'hF00: blue_crosshair_in ? 12'h00F: purple_crosshair_in ? 12'hF0F : thresholded_pixel_in ? 12'hFFF : 12'h0;
  // PRODUCTION
  assign pixel_out = l_2;
endmodule
