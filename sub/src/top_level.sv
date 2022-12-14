`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)
  input wire btnl, //btnc (used for reset)
  input wire btnr, //btnc (used for reset)
  input wire btnd, //btnc (used for reset)
  input wire btnu, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  localparam N_TRACKING_POINTS = 4;
  localparam N_VIRTUAL_POINTS = 202;
  localparam N_FRAMES = 10;

  localparam COUNT_STAGES_NEEDED = 7 + 19;  // TODO: minimize
  localparam SYNC_STAGES_NEEDED = 8 + 19;  // TODO: minimize
  localparam PS1 = 3;
  localparam PS2 = 1;
  localparam PS3 = 3 + 19;
  localparam PS4 = 4;
  localparam PS5 = 3;
  localparam PS6 = 7 + 19;
  localparam PS7 = 1;

  // TESTING STUFF
  localparam FIXED_X = 11'd300;
  localparam FIXED_Y = 10'd300;

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

  /* Video Pipeline */
  logic clk_65mhz; //65 MHz clock line

  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic [10:0] hcount_pipe [COUNT_STAGES_NEEDED-1:0];
  logic [9:0] vcount_pipe [COUNT_STAGES_NEEDED-1:0];
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_pipe [SYNC_STAGES_NEEDED-1:0];
  logic vsync_pipe [SYNC_STAGES_NEEDED-1:0];
  logic blank_pipe [SYNC_STAGES_NEEDED-1:0];
  logic hsync_t, vsync_t, blank_t; //control signals out of transform


  //camera module: (see datasheet)
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //rotate module:
  logic valid_pixel_rotate;  //indicates valid rotated pixel
  logic [15:0] pixel_rotate; //rotated 565 rotate pixel
  logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

  //values  of frame buffer:
  logic [16:0] pixel_addr_out; //
  logic [15:0] frame_buff; //output of scale module

  // output of scale module
  logic [15:0] full_pixel;//mirrored and scaled 565 pixel
  logic [15:0] full_pixel_pipe [PS5 - 1:0];

  //output of rgb to ycrcb conversion:
  logic [7:0] h; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [7:0] s; //[2:0]; //ycrcb conversion of full pixel (NEW)
  logic [7:0] v; //[2:0]; //ycrcb conversion of full pixel (NEW)

  logic [7:0] rh_thresh_high;
  logic [7:0] rh_thresh_low;
  logic [7:0] rs_thresh_high;
  logic [7:0] rs_thresh_low;
  logic [7:0] rv_thresh_high;
  logic [7:0] rv_thresh_low;
  logic [7:0] gh_thresh_high;
  logic [7:0] gh_thresh_low;
  logic [7:0] gs_thresh_high;
  logic [7:0] gs_thresh_low;
  logic [7:0] gv_thresh_high;
  logic [7:0] gv_thresh_low;
  logic [7:0] bh_thresh_high;
  logic [7:0] bh_thresh_low;
  logic [7:0] bs_thresh_high;
  logic [7:0] bs_thresh_low;
  logic [7:0] bv_thresh_high;
  logic [7:0] bv_thresh_low;
  logic [7:0] ph_thresh_high;
  logic [7:0] ph_thresh_low;
  logic [7:0] ps_thresh_high;
  logic [7:0] ps_thresh_low;
  logic [7:0] pv_thresh_high;
  logic [7:0] pv_thresh_low;

  //output of threshold module:
  logic red_mask, green_mask, blue_mask, purple_mask; //Whether or not thresholded pixel is 1 or 0
  logic [3:0] sel_channel; //selected channels four bit information intensity
  //sel_channel could contain any of the six color channels depend on selection

  //Center of Mass variables
  logic [10:0] red_x_com, red_x_com_calc; //long term x_com and output from module, resp
  logic [9:0] red_y_com, red_y_com_calc; //long term y_com and output from module, resp
  logic [10:0] purple_x_com, purple_x_com_calc; //long term x_com and output from module, resp
  logic [9:0] purple_y_com, purple_y_com_calc; //long term y_com and output from module, resp
  logic [10:0] green_x_com, green_x_com_calc; //long term x_com and output from module, resp
  logic [9:0] green_y_com, green_y_com_calc; //long term y_com and output from module, resp
  logic [10:0] blue_x_com, blue_x_com_calc; //long term x_com and output from module, resp
  logic [9:0] blue_y_com, blue_y_com_calc; //long term y_com and output from module, resp
  logic new_com_red, new_com_blue, new_com_green, new_com_purple; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  // output of projection (each point sequentially)
  logic signed [31:0] proj_x_out;
  logic signed [31:0] proj_y_out;
  logic [3:0] proj_color_out;

  // output of line_gen (each point sequentially)
  logic signed [11:0] line_x_out;
  logic signed [10:0] line_y_out;
  logic [3:0] line_color_out;
  logic next_point;

  // Ouptut of projected pixel mask
  logic [3:0] projection_mask;

  //output of image sprite
  //Output of sprite that should be centered on Center of Mass (x_com, y_com):
  logic [11:0] com_sprite_pixel;

  //Crosshair value hot when hcount,vcount== (x_com, y_com)
  logic red_crosshair;
  logic green_crosshair;
  logic blue_crosshair;
  logic purple_crosshair;
  logic red_crosshair_pipe [PS4 - 1:0];
  logic green_crosshair_pipe [PS4 - 1:0];
  logic blue_crosshair_pipe [PS4 - 1:0];
  logic purple_crosshair_pipe [PS4 - 1:0];
  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render

  logic signed [N_TRACKING_POINTS - 2:0][15:0] ball_vectors_x;
  logic signed [N_TRACKING_POINTS - 2:0][15:0] ball_vectors_y;

  //Generate 65 MHz:
  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz

  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync;
    blank_pipe[0] <= blank;
    red_crosshair_pipe[0] <= red_crosshair;
    green_crosshair_pipe[0] <= green_crosshair;
    blue_crosshair_pipe[0] <= blue_crosshair;
    purple_crosshair_pipe[0] <= purple_crosshair;

    full_pixel_pipe[0] <= full_pixel;
    for (int i=1; i<COUNT_STAGES_NEEDED; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
    for (int i=1; i<SYNC_STAGES_NEEDED; i = i+1)begin
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
    end
    for (int i=1; i<PS4; i = i+1)begin
      red_crosshair_pipe[i] <= red_crosshair_pipe[i-1];
      green_crosshair_pipe[i] <= green_crosshair_pipe[i-1];
      blue_crosshair_pipe[i] <= blue_crosshair_pipe[i-1];
      purple_crosshair_pipe[i] <= purple_crosshair_pipe[i-1];
    end
    for (int i=1; i<PS5; i = i+1)begin
      full_pixel_pipe[i] <= full_pixel_pipe[i-1];
    end
  end

  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_65mhz) begin
    cam_clk_buff <= jb[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= jb[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= jb[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= ja; //sync pixels
    pixel_in <= pixel_buff;
  end

  //Controls and Processes Camera information
  camera camera_m(
    //signal generate to camera:
    .clk_65mhz(clk_65mhz),
    .jbclk(jbclk),
    .jblock(jblock),
    //returned information from camera:
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel),
    .pixel_valid_out(valid_pixel),
    .frame_done_out(frame_done));

  //NEW FOR LAB 04B (START)----------------------------------------------
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (65 MHz) valid data from recovery module

  logic [10:0] hcount_f0;  //hcount from filter modules
  logic [9:0] vcount_f0; //vcount from filter modules
  logic [15:0] pixel_data_f0; //pixel data from filter modules
  logic data_valid_f0; //valid signals for filter modules

  logic [10:0] hcount_f [5:0];  //hcount from filter modules
  logic [9:0] vcount_f [5:0]; //vcount from filter modules
  logic [15:0] pixel_data_f [5:0]; //pixel data from filter modules
  logic data_valid_f [5:0]; //valid signals for filter modules

  logic [10:0] hcount_fmux; //hcount from filter mux
  logic [9:0]  vcount_fmux; //vcount from filter mux
  logic [15:0] pixel_data_fmux; //pixel data from filter mux
  logic data_valid_fmux; //data valid from filter mux


  logic [10:0] red_x_stored;
  logic [9:0] red_y_stored;
  logic [10:0] blue_x_stored;
  logic [9:0] blue_y_stored;
  logic [10:0] purple_x_stored;
  logic [9:0] purple_y_stored;
  logic [10:0] green_x_stored;
  logic [9:0] green_y_stored;


  //recovers hcount and vcount from camera module:
  //generates data and a valid signal on 65 MHz
  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .frame_done_in(frame_done),

    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));

  //using generate/genvar, create five *Different* instances of the
  //filter module (you'll write that).  Each filter will implement a different
  //kernel
  filter #(.K_SELECT(1)) filtern(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .data_valid_in(data_valid_rec),
    .pixel_data_in(pixel_data_rec),
    .hcount_in(hcount_rec),
    .vcount_in(vcount_rec),
    .data_valid_out(data_valid_f0),
    .pixel_data_out(pixel_data_f0),
    .hcount_out(hcount_f0),
    .vcount_out(vcount_f0)
  );
  generate
    genvar i;
    for (i=0; i<6; i=i+1)begin
      filter #(.K_SELECT(i)) filterm(
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .data_valid_in(data_valid_f0),
        .pixel_data_in(pixel_data_f0),
        .hcount_in(hcount_f0),
        .vcount_in(vcount_f0),
        .data_valid_out(data_valid_f[i]),
        .pixel_data_out(pixel_data_f[i]),
        .hcount_out(hcount_f[i]),
        .vcount_out(vcount_f[i])
      );
    end
  endgenerate

  //combine hor and vert signals from filters 4 and 5 for special signal:
  logic [7:0] fcomb_r, fcomb_g, fcomb_b;
  assign fcomb_r = (pixel_data_f[4][15:11]+pixel_data_f[5][15:11])>>1;
  assign fcomb_g = (pixel_data_f[4][10:5]+pixel_data_f[5][10:5])>>1;
  assign fcomb_b = (pixel_data_f[4][4:0]+pixel_data_f[5][4:0])>>1;

  //based on values of sw[2:0] select which filter output gets handed on to the
  //next module. We must make sure to route hcount, vcount, pixels and valid signal
  // for each module.  Could have done this with a for loop as well!  Think
  // about it!
  always_ff @(posedge clk_65mhz)begin
    case (3'b0)
      3'b000: begin
        hcount_fmux <= hcount_f[0];
        vcount_fmux <= vcount_f[0];
        pixel_data_fmux <= pixel_data_f[0];
        data_valid_fmux <= data_valid_f[0];
        // hcount_fmux <= hcount_rec;
        // vcount_fmux <= vcount_rec;
        // pixel_data_fmux <= pixel_data_rec;
        // data_valid_fmux <= data_valid_rec;
      end
      3'b001: begin
        hcount_fmux <= hcount_f[1];
        vcount_fmux <= vcount_f[1];
        pixel_data_fmux <= pixel_data_f[1];
        data_valid_fmux <= data_valid_f[1];
      end
      3'b010: begin
        hcount_fmux <= hcount_f[2];
        vcount_fmux <= vcount_f[2];
        pixel_data_fmux <= pixel_data_f[2];
        data_valid_fmux <= data_valid_f[2];
      end
      3'b011: begin
        hcount_fmux <= hcount_f[3];
        vcount_fmux <= vcount_f[3];
        pixel_data_fmux <= pixel_data_f[3];
        data_valid_fmux <= data_valid_f[3];
      end
      3'b100: begin
        hcount_fmux <= hcount_f[4];
        vcount_fmux <= vcount_f[4];
        pixel_data_fmux <= pixel_data_f[4];
        data_valid_fmux <= data_valid_f[4];
      end
      3'b101: begin
        hcount_fmux <= hcount_f[5];
        vcount_fmux <= vcount_f[5];
        pixel_data_fmux <= pixel_data_f[5];
        data_valid_fmux <= data_valid_f[5];
      end
      3'b110: begin
        hcount_fmux <= hcount_f[4];
        vcount_fmux <= vcount_f[4];
        pixel_data_fmux <= {fcomb_r[4:0],fcomb_g[5:0],fcomb_b[4:0]};
        data_valid_fmux <= data_valid_f[4]&&data_valid_f[5];
      end
      default: begin
        hcount_fmux <= hcount_f[0];
        vcount_fmux <= vcount_f[0];
        pixel_data_fmux <= 16'b11111_000000_11111;
        data_valid_fmux <= data_valid_f[0];
      end
    endcase
  end
  //new rotate module only on 65 MHz:
  //same as old one, but this one runs on 65 MHz with valid signal as
  //opposed to old one that ran on 16.67 MHz.
  rotate2 rotate_m(
    .clk_in(clk_65mhz),
    .hcount_in(hcount_fmux),
    .vcount_in(vcount_fmux),
    .data_valid_in(data_valid_fmux),
    .pixel_in(pixel_data_fmux),
    .pixel_out(pixel_rotate),
    .pixel_addr_out(pixel_addr_in),
    .data_valid_out(valid_pixel_rotate));

  //NEW FOR LAB 04B (END)----------------------------------------------

  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank));

  //Rotates Image to render correctly (pi/2 CCW rotate):
  // rotate rotate_m (
  //   .cam_clk_in(cam_clk_in),
  //   .valid_pixel_in(valid_pixel),
  //   .pixel_in(cam_pixel),
  //   .valid_pixel_out(valid_pixel_rotate),
  //   .pixel_out(pixel_rotate),
  //   .frame_done_in(frame_done),
  //   .pixel_addr_in(pixel_addr_in));

  //Two Clock Frame Buffer:
  //Data written on 16.67 MHz (From camera)
  //Data read on 65 MHz (start of video pipeline information)
  //Latency is 2 cycles.
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (16.67MHz)
    .addra(pixel_addr_in),
    .clka(clk_65mhz), //NEW FOR LAB 04B
    .wea(valid_pixel_rotate),
    .dina(pixel_rotate),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side (65 MHz)
    .addrb(pixel_addr_out),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(frame_buff)
  );

  //Based on current hcount and vcount as well as
  //scaling and mirror information requests correct pixel
  //from BRAM (on 65 MHz side).
  //latency: 2 cycles
  //IMPORTANT: this module is "start" of Output pipeline
  //hcount and vcount are fine here.
  //however latency in the image information starts to build up starting here
  //and we need to make sure to continue to use screen location information
  //that is "delayed" the right amount of cycles!
  //AS A RESULT, most downstream modules after this will need to use appropriately
  //pipelined versions of hcount, vcount, hsync, vsync, blank as needed
  //these The pipelining of these stages will need to be determined
  //for CHECKOFF 3!
  mirror mirror_m(
    .clk_in(clk_65mhz),
    .mirror_in(1'b1), //NEW FOR LAB 04B
    .scale_in(2'b01), //NEW FOR LAB 04B
    .hcount_in(hcount), //
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_out)
  );

  //Based on hcount and vcount as well as scaling
  //gate the release of frame buffer information
  //Latency: 0
  scale scale_m(
    .scale_in(2'b01), //NEW FOR LAB 04B
    .hcount_in(hcount_pipe[PS1 + PS2 - 1]), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[PS1 + PS2 - 1]), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );

  //Convert RGB of full pixel to YCrCb
  //See lecture 04 for YCrCb discussion.
  //Module has a 3 cycle latency
  //assign full_pixel = line_buffer[0];
  // rgb_to_ycrcb rgbtoycrcb_m(
  //   .clk_in(clk_65mhz),
  //   .r_in({full_pixel[15:11], 5'b0}), //all five of red
  //   .g_in({full_pixel[10:5],4'b0}), //all six of green
  //   .b_in({full_pixel[4:0], 5'b0}), //all five of blue
  //   .y_out(y),
  //   .cr_out(cr),
  //   .cb_out(cb));
  rgb2hsv rgbtohsv_m(
    .clock(clk_65mhz),
    .reset(sys_rst),
    .r({full_pixel[15:11], 3'b0}), //all five of red
    .g({full_pixel[10:5], 2'b0}), //all six of green
    .b({full_pixel[4:0], 3'b0}), //all five of blue
    // .r({3'b0, full_pixel[15:11]}), //all five of red
    // .g({2'b0, full_pixel[10:5]}), //all six of green
    // .b({3'b0, full_pixel[4:0]}), //all five of blue
    .h(h),
    .s(s),
    .v(v)
  );


  //LED Display controller
  //module not in video pipeline, provides diagnostic information
  //about high/low mask state as well as what channel is selected:
  //: "r:red, g:green, b:blue, y: luminance, Cr: Red Chrom, Cb: Blue Chrom
  // lab04_ssc mssc(.clk_in(clk_65mhz),
  //                .rst_in(btnc),
  //                .val_in({sw[15:10],sw[5:3]}),
  //                .cat_out({cag, caf, cae, cad, cac, cab, caa}),
  //                .an_out(an));
  logic [31:0] mssc_value;
  logic [31:0] test_display;
  logic signed [31:0] x_start_test;
  logic signed [31:0] y_start_test;
  logic signed [31:0] x_end_test;
  logic signed [31:0] y_end_test;
  logic [15:0] prev_sw;
  always_ff @(posedge clk_65mhz)begin
    prev_sw <= sw;
    if (sw[0] && !prev_sw[0]) test_display <= x_start_test;
    if (sw[1] && !prev_sw[1]) test_display <= y_start_test;
    if (sw[2] && !prev_sw[2]) test_display <= x_end_test;
    if (sw[3] && !prev_sw[3]) test_display <= y_end_test;
    if (sw[4] && !prev_sw[4]) test_display <= ball_vectors_x[0];
    if (sw[5] && !prev_sw[5]) test_display <= ball_vectors_y[0];
    if (sw[6] && !prev_sw[6]) test_display <= ball_vectors_x[1];
    if (sw[7] && !prev_sw[7]) test_display <= ball_vectors_y[1];
    if (sw[8] && !prev_sw[8]) test_display <= ball_vectors_x[2];
    if (sw[9] && !prev_sw[9]) test_display <= ball_vectors_y[2];
  end

  logic [1:0] rgbp_selector;
  assign mssc_value = {sw[15:8], 8'b0, sw[7:0], 6'b0, rgbp_selector};
  seven_segment_controller mssc(.clk_in(clk_65mhz),
                                .rst_in(btnc),
                                .val_in(mssc_value),
                                .cat_out({cag, caf, cae, cad, cac, cab, caa}),
                                .an_out(an));

  //Thresholder: Takes in the full RGB and YCrCb information and
  //based on upper and lower bounds masks
  //module has 0 cycle latency
  threshold red_thresh(
    .sel_in(sw[5:3]),
    .r_in(full_pixel_pipe[PS5 - 1][15:12]), //TODO: needs to use pipelined signal (PS5)
    .g_in(full_pixel_pipe[PS5 - 1][10:7]),  //TODO: needs to use pipelined signal (PS5)
    .b_in(full_pixel_pipe[PS5 - 1][4:1]),   //TODO: needs to use pipelined signal (PS5)
    .h_in(h),
    .s_in(s),
    .v_in(v),
    .h_thresh_high(rh_thresh_high),
    .h_thresh_low(rh_thresh_low),
    .s_thresh_high(rs_thresh_high),
    .s_thresh_low(rs_thresh_low),
    .v_thresh_high(rv_thresh_high),
    .v_thresh_low(rv_thresh_low),
    .mask_out(red_mask),
    .channel_out(sel_channel)
    );

    threshold green_thresh(
    .sel_in(sw[5:3]),
    .r_in(full_pixel_pipe[PS5 - 1][15:12]), //TODO: needs to use pipelined signal (PS5)
    .g_in(full_pixel_pipe[PS5 - 1][10:7]),  //TODO: needs to use pipelined signal (PS5)
    .b_in(full_pixel_pipe[PS5 - 1][4:1]),   //TODO: needs to use pipelined signal (PS5)
    .h_in(h),
    .s_in(s),
    .v_in(v),
    .h_thresh_high(gh_thresh_high),
    .h_thresh_low(gh_thresh_low),
    .s_thresh_high(gs_thresh_high),
    .s_thresh_low(gs_thresh_low),
    .v_thresh_high(gv_thresh_high),
    .v_thresh_low(gv_thresh_low),
    .mask_out(green_mask),
    .channel_out(sel_channel)
    );

    threshold blue_thresh(
    .sel_in(sw[5:3]),
    .r_in(full_pixel_pipe[PS5 - 1][15:12]), //TODO: needs to use pipelined signal (PS5)
    .g_in(full_pixel_pipe[PS5 - 1][10:7]),  //TODO: needs to use pipelined signal (PS5)
    .b_in(full_pixel_pipe[PS5 - 1][4:1]),   //TODO: needs to use pipelined signal (PS5)
    .h_in(h),
    .s_in(s),
    .v_in(v),
    .h_thresh_high(bh_thresh_high),
    .h_thresh_low(bh_thresh_low),
    .s_thresh_high(bs_thresh_high),
    .s_thresh_low(bs_thresh_low),
    .v_thresh_high(bv_thresh_high),
    .v_thresh_low(bv_thresh_low),
    .mask_out(blue_mask),
    .channel_out(sel_channel)
    );

  threshold purple_thresh(
    .sel_in(sw[5:3]),
    .r_in(full_pixel_pipe[PS5 - 1][15:12]), //TODO: needs to use pipelined signal (PS5)
    .g_in(full_pixel_pipe[PS5 - 1][10:7]),  //TODO: needs to use pipelined signal (PS5)
    .b_in(full_pixel_pipe[PS5 - 1][4:1]),   //TODO: needs to use pipelined signal (PS5)
    .h_in(h),
    .s_in(s),
    .v_in(v),
    .h_thresh_high(ph_thresh_high),
    .h_thresh_low(ph_thresh_low),
    .s_thresh_high(ps_thresh_high),
    .s_thresh_low(ps_thresh_low),
    .v_thresh_high(pv_thresh_high),
    .v_thresh_low(pv_thresh_low),
    .mask_out(purple_mask),
    .channel_out(sel_channel)
    );

  // Center of Mass:
  center_of_mass red_com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[PS1 + PS2 + PS3 - 1]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[PS1 + PS2 + PS3 - 1]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(red_mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(red_x_com_calc),
    .y_out(red_y_com_calc),
    .valid_out(new_com_red));

  //Center of Mass:
  center_of_mass green_com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[PS1 + PS2 + PS3 - 1]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[PS1 + PS2 + PS3 - 1]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(green_mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(green_x_com_calc),
    .y_out(green_y_com_calc),
    .valid_out(new_com_green));

  //Center of Mass:
  center_of_mass blue_com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[PS1 + PS2 + PS3 - 1]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[PS1 + PS2 + PS3 - 1]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(blue_mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(blue_x_com_calc),
    .y_out(blue_y_com_calc),
    .valid_out(new_com_blue));

      //Center of Mass:
  center_of_mass purple_com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[PS1 + PS2 + PS3 - 1]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[PS1 + PS2 + PS3 - 1]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(purple_mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(purple_x_com_calc),
    .y_out(purple_y_com_calc),
    .valid_out(new_com_purple));

  vectors #(.N_TRACKING_POINTS(N_TRACKING_POINTS), .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS))vector_thing(
    .clk_in(clk_65mhz), .rst_in(sys_rst),
    // Testing hardcoded values
    // .red_x_com(300),
    // .red_y_com(300),
    // .purple_x_com(250),
    // .purple_y_com(350),
    // .green_x_com(375),
    // .green_y_com(325),
    // .blue_x_com(300),
    // .blue_y_com(200),
    // .valid_blue(1),  // y
    // .valid_red(1),
    // .valid_green(1),  // x
    // .valid_purple(1),  // z
    .red_x_com(red_x_com_calc),
    .red_y_com(red_y_com_calc),
    .purple_x_com(purple_x_com_calc),
    .purple_y_com(purple_y_com_calc),
    .green_x_com(green_x_com_calc),
    .green_y_com(green_y_com_calc),
    .blue_x_com(blue_x_com_calc),
    .blue_y_com(blue_y_com_calc),
    .valid_blue(new_com_blue),
    .valid_red(new_com_red),
    .valid_green(new_com_green),
    .valid_purple(new_com_green),
    .ball_vectors_x(ball_vectors_x),
    .ball_vectors_y(ball_vectors_y),
    .red_x_stored(red_x_stored),
    .red_y_stored(red_y_stored),
    .blue_x_stored(blue_x_stored),
    .blue_y_stored(blue_y_stored),
    .purple_x_stored(purple_x_stored),
    .purple_y_stored(purple_y_stored),
    .green_x_stored(green_x_stored),
    .green_y_stored(green_y_stored)
  );

  // logic [41:0] shift_reg;
  //update center of mass x_com, y_com based on new_com signal
  // always_ff @(posedge clk_65mhz)begin
    // if (sys_rst)begin
    //   red_x_com <= 11'd300;
    //   red_y_com <= 10'd300;
    //   green_x_com<=11'd200;
    //   green_y_com<=10'd400;
    //   blue_x_com<=11'd400;
    //   blue_y_com<=10'd300;
    //   purple_x_com<=11'd250;
    //   purple_y_com<=10'd350;
    //   // green_x_com <= 0;
    //   // green_y_com <= 0;
    //   // blue_x_com <= 0;
    //   // blue_y_com <= 0;
    //   // purple_x_com <= 0;
    //   // purple_y_com <= 0;
    //   // shift_reg<=0;
    //   ball_vectors_x[0]<=$signed({1'b0,green_x_com_calc}) - $signed({1'b0,11'd300});
    //   ball_vectors_y[0]<=$signed({1'b0,green_y_com_calc}) - $signed({1'b0,11'd300});
    //   ball_vectors_x[1]<=$signed({1'b0,blue_x_com_calc}) - $signed({1'b0,11'd300});
    //   ball_vectors_y[1]<=$signed({1'b0,blue_y_com_calc})- $signed({1'b0,11'd300});
    //   ball_vectors_x[2]<=$signed({1'b0,purple_x_com_calc}) - $signed({1'b0,11'd300});
    //   ball_vectors_y[2]<=$signed({1'b0,purple_y_com_calc}) - $signed({1'b0,11'd300});
    // end else if(btnu || btnr || btnd || btnl) begin
    //   ball_vectors_x[0] <= $signed({1'b0,green_x_com_calc}) - $signed({1'b0,red_x_com});
    //   ball_vectors_y[0] <= $signed({1'b0,green_y_com_calc}) - $signed({1'b0,red_y_com});
    //   ball_vectors_x[1] <= $signed({1'b0,blue_x_com_calc}) - $signed({1'b0,red_x_com});
    //   ball_vectors_y[1] <= $signed({1'b0,blue_y_com_calc})- $signed({1'b0,red_y_com});
    //   ball_vectors_x[2] <= $signed({1'b0,purple_x_com_calc}) - $signed({1'b0,red_x_com});
    //   ball_vectors_y[2] <= $signed({1'b0,purple_y_com_calc}) - $signed({1'b0,red_y_com});
    // end


    // end if(new_com_red)begin
    //   red_x_com <= red_x_com_calc;
    //   red_y_com <= red_y_com_calc;
    // end if(new_com_green)begin
    //   green_x_com <= green_x_com_calc;
    //   green_y_com <= green_y_com_calc;
    //   ball_vectors_x[0] <= $signed({1'b0,green_x_com_calc}) - ((new_com_red) ? $signed({1'b0,red_x_com_calc}) : $signed({1'b0,red_x_com}));
    //   ball_vectors_y[0] <= $signed({1'b0,green_y_com_calc}) - ((new_com_red) ? $signed({1'b0,red_y_com_calc}) : $signed({1'b0,red_y_com}));

    // end if(new_com_blue) begin
    //   blue_x_com <= blue_x_com_calc;
    //   blue_y_com <= blue_y_com_calc;
    //   ball_vectors_x[1] <=$signed({1'b0,blue_x_com_calc}) - ((new_com_red) ? $signed({1'b0,red_x_com_calc}) : $signed({1'b0,red_x_com}));
    //   ball_vectors_y[1] <=$signed({1'b0,blue_y_com_calc}) - ((new_com_red) ? $signed({1'b0,red_y_com_calc}) : $signed({1'b0,red_y_com}));
    // end if(new_com_purple) begin
    //   purple_x_com <= purple_x_com_calc;
    //   purple_y_com <= purple_y_com_calc;
    //   ball_vectors_x[2] <=$signed({1'b0,purple_x_com_calc}) - ((new_com_red) ? $signed({1'b0,red_x_com_calc}) : $signed({1'b0,red_x_com}));
    //   ball_vectors_y[2] <=$signed({1'b0,purple_y_com_calc}) - ((new_com_red) ? $signed({1'b0,red_y_com_calc}) : $signed({1'b0,red_y_com}));
    // end

  //   shift_reg<=shift_reg+1;
  // end

  logic signed [N_TRACKING_POINTS - 2:0][15:0] point_scalars;
  logic [3:0] point_color;

//  load_points #(
//    .N_TRACKING_POINTS(N_TRACKING_POINTS),
//    .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS)
//  ) point_load (
//    .clk_in(clk_65mhz),
//    .rst_in(sys_rst),
//    .next_point(next_point),
//    .point_scalars(point_scalars),
//    .point_color(point_color)
//  );

  load_animation #(
    .N_TRACKING_POINTS(N_TRACKING_POINTS),
    .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS),
    .N_FRAMES(N_FRAMES)
  ) point_load (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .next_point(next_point),
    .point_scalars(point_scalars),
    .point_color(point_color)
  );

  // assign red_x_com_calc=11'd400;
  // assign red_y_com_calc=10'd300;



  projection #(
    .N_TRACKING_POINTS(N_TRACKING_POINTS),
    .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS)
  ) map (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_vec(ball_vectors_x),
    .y_vec(ball_vectors_y),
    .point_scalars(point_scalars),
    .point_color(point_color),
    .x_origin(red_x_stored),
    .y_origin(red_y_stored),
    .x_proj(proj_x_out),
    .y_proj(proj_y_out),
    .color_proj(proj_color_out)
  );


  line_gen liner (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .data_valid_in(1'b1),
    .x_in(proj_x_out),
    .y_in(proj_y_out),
    .color_in(proj_color_out),//TODO: set this back to proj_color_out
    .x(line_x_out),
    .y(line_y_out),
    .color(line_color_out),
    .x_start_test(x_start_test),
    .y_start_test(y_start_test),
    .x_end_test(x_end_test),
    .y_end_test(y_end_test),
    .next_point(next_point));

  pixel_manager #(
    .N_TRACKING_POINTS(N_TRACKING_POINTS),
    .N_VIRTUAL_POINTS(N_VIRTUAL_POINTS)
  ) p_manager (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[PS1 - 1]),
    .vcount_in(vcount_pipe[PS1 - 1]),
    .hcount_out(), // TODO: I don't think we need these
    .vcount_out(),
    .x_in(line_x_out),
    .y_in(line_y_out),
    .color_in(line_color_out),
    .pixel_out(projection_mask));

  //Image Sprite (your implementation from Lab03):
  //Latency 4 cycle
  image_sprite #(
    .WIDTH(256),
    .HEIGHT(256))
    com_sprite_m (
    .pixel_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[PS1 - 1]),   //TODO: needs to use pipelined signal (PS1)
    .vcount_in(vcount_pipe[PS1 - 1]),   //TODO: needs to use pipelined signal (PS1)
    .x_in(red_x_com>128 ? red_x_com-128 : 0),
    .y_in(red_y_com>128 ? red_y_com-128 : 0),
    .pixel_out(com_sprite_pixel));

  //Create Crosshair patter on center of mass:
  //0 cycle latency
  // assign crosshair = ((vcount==y_com)||(hcount==x_com));;
  assign red_crosshair = (vcount==red_y_stored)||(hcount==red_x_stored);
  assign green_crosshair = (vcount==green_y_stored)||(hcount==green_x_stored);
  assign blue_crosshair = (vcount==blue_y_stored)||(hcount==blue_x_stored);
  assign purple_crosshair = (vcount==purple_y_stored)||(hcount==purple_x_stored);

  logic[11:0] proj_count;
  always_ff @(posedge clk_65mhz) begin
    if(sys_rst)begin
      proj_count<=0;
    end else if (projection_mask > 0 && hcount_pipe[PS1 - 1]<=10'd480 && vcount_pipe[PS1 - 1]<=10'd640 && proj_count<=11'd2000) begin
      proj_count<=proj_count+1;
    end
  end


  //VGA MUX:
  //latency 0 cycles (combinational-only module)
  //module decides what to draw on the screen:
  // sw[7:6]:
  //    00: 444 RGB image
  //    01: GrayScale of Selected Channel (Y, R, etc...)
  //    10: Masked Version of Selected Channel
  //    11: Chroma Image with Mask in 6.205 Pink
  // sw[9:8]:
  //    00: Nothing
  //    01: green crosshair on center of mass
  //    10: image sprite on top of center of mass
  //    11: all pink screen (for VGA functionality testing)
  vga_mux (
  // .sel_in(sw[9:6]),
    .sel_in(4'b0110),
    .camera_pixel_in({full_pixel_pipe[PS5 - 1][15:12],full_pixel_pipe[PS5 - 1][10:7],full_pixel_pipe[PS5 - 1][4:1]}), //TODO: needs to use pipelined signal(PS5)
    .camera_y_in(h[7:4]),
    .channel_in(sel_channel),
    .thresholded_pixel_in(rgbp_selector == 2'b0 ? red_mask : rgbp_selector == 2'b1 ? green_mask : rgbp_selector == 2'b10 ? blue_mask : purple_mask),
    .red_crosshair_in(red_crosshair_pipe[PS4 - 1]), //TODO: needs to use pipelined signal (PS4)
    .green_crosshair_in(green_crosshair_pipe[PS4 - 1]), //TODO: needs to use pipelined signal (PS4)
    .blue_crosshair_in(blue_crosshair_pipe[PS4 - 1]), //TODO: needs to use pipelined signal (PS4)
    .purple_crosshair_in(purple_crosshair_pipe[PS4 - 1]),
    .com_sprite_pixel_in(com_sprite_pixel),
    .projection_mask_pixel(projection_mask),
    .pixel_out(mux_pixel)
  );

  //blankig logic.
  //latency 1 cycle
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank_pipe[PS6 - 1]?mux_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank_pipe[PS6 - 1]?mux_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank_pipe[PS6 - 1]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
  end

  assign vga_hs = ~hsync_pipe[PS6 + PS7 - 1];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[PS6 + PS7 - 1];  //TODO: needs to use pipelined signal (PS7)

  logic prev_btnl;
  logic prev_btnd;
  logic prev_btnr;
  logic prev_btnu;

  always_ff @(posedge clk_65mhz)begin
    if (btnc) begin
      rh_thresh_low <= 8'h01;
      rh_thresh_high <= 8'h07;
      rs_thresh_low <= 8'hC0;
      rs_thresh_high <= 8'hFF;
      rv_thresh_low <= 8'h40;
      rv_thresh_high <= 8'hFF;

      gh_thresh_low <= 8'h1F;
      gh_thresh_high <= 8'h30;
      gs_thresh_low <= 8'h9F;
      gs_thresh_high <= 8'hFF;
      gv_thresh_low <= 8'h70;
      gv_thresh_high <= 8'hFF;

      bh_thresh_low <= 8'h83;
      bh_thresh_high <= 8'hA0;
      bs_thresh_low <= 8'h90;
      bs_thresh_high <= 8'hFF;
      bv_thresh_low <= 8'h7F;
      bv_thresh_high <= 8'hFF;

      ph_thresh_low <= 8'h9F;
      ph_thresh_high <= 8'hDF;
      ps_thresh_low <= 8'h60;
      ps_thresh_high <= 8'hFF;
      pv_thresh_low <= 8'h70;
      pv_thresh_high <= 8'hFF;

      prev_btnl <= 0;
      prev_btnd <= 0;
      prev_btnr <= 0;
      prev_btnu <= 0;

      rgbp_selector <= 0;
    end else begin
      if (btnu && !prev_btnu) begin
        rgbp_selector <= rgbp_selector == 2'b11 ? 0 : rgbp_selector + 1;
      end
      if (btnl && !prev_btnl) begin
        case (rgbp_selector)
          2'b0: begin
            rh_thresh_low <= sw[7:0];
            rh_thresh_high <= sw[15:8];
          end
          2'b1: begin
            gh_thresh_low <= sw[7:0];
            gh_thresh_high <= sw[15:8];
          end
          2'b10: begin
            bh_thresh_low <= sw[7:0];
            bh_thresh_high <= sw[15:8];
          end
          2'b11: begin
            ph_thresh_low <= sw[7:0];
            ph_thresh_high <= sw[15:8];
          end
        endcase
      end
      if (btnd && !prev_btnd) begin
        case (rgbp_selector)
          2'b0: begin
            rs_thresh_low <= sw[7:0];
            rs_thresh_high <= sw[15:8];
          end
          2'b1: begin
            gs_thresh_low <= sw[7:0];
            gs_thresh_high <= sw[15:8];
          end
          2'b10: begin
            bs_thresh_low <= sw[7:0];
            bs_thresh_high <= sw[15:8];
          end
          2'b11: begin
            ps_thresh_low <= sw[7:0];
            ps_thresh_high <= sw[15:8];
          end
        endcase
      end
      if (btnr && !prev_btnr) begin
        case (rgbp_selector)
          2'b0: begin
            rv_thresh_low <= sw[7:0];
            rv_thresh_high <= sw[15:8];
          end
          2'b1: begin
            gv_thresh_low <= sw[7:0];
            gv_thresh_high <= sw[15:8];
          end
          2'b10: begin
            bv_thresh_low <= sw[7:0];
            bv_thresh_high <= sw[15:8];
          end
          2'b11: begin
            pv_thresh_low <= sw[7:0];
            pv_thresh_high <= sw[15:8];
          end
        endcase
      end

      prev_btnl <= btnl;
      prev_btnd <= btnd;
      prev_btnr <= btnr;
      prev_btnu <= btnu;
    end
  end


endmodule
`default_nettype wire
