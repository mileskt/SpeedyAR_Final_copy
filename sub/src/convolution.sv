`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    logic [2:0][2:0][15:0] cache;
    // Needs to be bigger (11,12,11) because the multiplication can be bigger
    // (add 6 for the largest possible coeffs)
    // logic [2:0][2:0][34:0] multiplied_cache;
    // Needs to be bigger (12,13,12) because the multiplication can be bigger
    // (add 7 for the largest possible coeffs)
    logic signed [2:0][2:0][15:0] multiplied_red_cache;
    logic signed [2:0][2:0][15:0] multiplied_green_cache;
    logic signed [2:0][2:0][15:0] multiplied_blue_cache;

    // Add 8 possible carry's for each
    // logic signed [15:0] added_red_cache;
    // logic signed [15:0] added_green_cache;
    // logic signed [15:0] added_blue_cache;

    // Back to 5, 6, and 5 bits
    logic [4:0] shifted_red_cache;
    logic [5:0] shifted_green_cache;
    logic [4:0] shifted_blue_cache;

    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;
    logic signed [7:0] offset;
    
    kernels #(
      .K_SELECT(K_SELECT)
    ) kern (
      .rst_in(rst_in),
      .coeffs(coeffs),
      .shift(shift),
      .offset(offset)
    );

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be 
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing 
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */
    
    localparam PIPE_LEN = 3;
    logic [10:0] hcount_pipe [PIPE_LEN-1:0];
    logic [9:0] vcount_pipe [PIPE_LEN-1:0];
    logic data_valid_pipe [PIPE_LEN-1:0];

    // assign added_red_cache = (
    //   $signed(multiplied_red_cache[0][0]) +
    //   $signed(multiplied_red_cache[1][0]) +
    //   $signed(multiplied_red_cache[2][0]) +
    //   $signed(multiplied_red_cache[0][1]) +
    //   $signed(multiplied_red_cache[1][1]) +
    //   $signed(multiplied_red_cache[2][1]) +
    //   $signed(multiplied_red_cache[0][2]) +
    //   $signed(multiplied_red_cache[1][2]) +
    //   $signed(multiplied_red_cache[2][2])
    // );
    // assign added_green_cache = (
    //   $signed(multiplied_green_cache[0][0]) +
    //   $signed(multiplied_green_cache[1][0]) +
    //   $signed(multiplied_green_cache[2][0]) +
    //   $signed(multiplied_green_cache[0][1]) +
    //   $signed(multiplied_green_cache[1][1]) +
    //   $signed(multiplied_green_cache[2][1]) +
    //   $signed(multiplied_green_cache[0][2]) +
    //   $signed(multiplied_green_cache[1][2]) +
    //   $signed(multiplied_green_cache[2][2])
    // );
    // assign added_blue_cache = (
    //   $signed(multiplied_blue_cache[0][0]) +
    //   $signed(multiplied_blue_cache[1][0]) +
    //   $signed(multiplied_blue_cache[2][0]) +
    //   $signed(multiplied_blue_cache[0][1]) +
    //   $signed(multiplied_blue_cache[1][1]) +
    //   $signed(multiplied_blue_cache[2][1]) +
    //   $signed(multiplied_blue_cache[0][2]) +
    //   $signed(multiplied_blue_cache[1][2]) +
    //   $signed(multiplied_blue_cache[2][2])
    // );

    always_ff @(posedge clk_in) begin
      // Update pipes
      hcount_pipe[0] <= hcount_in;
      vcount_pipe[0] <= vcount_in;
      data_valid_pipe[0] <= data_valid_in;
      for (int i=1; i<PIPE_LEN; i = i+1)begin
        hcount_pipe[i] <= hcount_pipe[i-1];
        vcount_pipe[i] <= vcount_pipe[i-1];
        data_valid_pipe[i] <= data_valid_pipe[i-1];
      end

      if (rst_in) begin
        cache <= 0;
        multiplied_red_cache <= 0;
        multiplied_green_cache <= 0;
        multiplied_blue_cache <= 0;
        shifted_red_cache <= 0;
        shifted_green_cache <= 0;
        shifted_blue_cache <= 0;
        data_valid_out <= 0;
        hcount_out <= 0;
        vcount_out <= 0;
        line_out <= 0;
      end else begin
        // Take new data and update cache
        if (data_valid_in) begin
          cache[2][0] <= data_in[0];
          cache[2][1] <= data_in[1];
          cache[2][2] <= data_in[2];

          cache[1][0] <= cache[2][0];
          cache[1][1] <= cache[2][1];
          cache[1][2] <= cache[2][2];

          cache[0][0] <= cache[1][0];
          cache[0][1] <= cache[1][1];
          cache[0][2] <= cache[1][2];
          // for (int i = 0; i<3; i= i+1) begin
          //   cache[2] <= data_in[i];
          //   cache[1] <= cache[2][i];
          //   cache[0] <= cache[1][i];
          // end
        end

        if (data_valid_pipe[0]) begin
          multiplied_red_cache[0][0] <= $signed({8'b0, cache[0][0][15:11]}) * $signed(coeffs[0][0]);
          multiplied_green_cache[0][0] <= $signed({8'b0, cache[0][0][10:5]}) * $signed(coeffs[0][0]);
          multiplied_blue_cache[0][0] <= $signed({8'b0, cache[0][0][4:0]}) * $signed(coeffs[0][0]);

          multiplied_red_cache[0][1] <= $signed({8'b0, cache[0][1][15:11]}) * $signed(coeffs[0][1]);
          multiplied_green_cache[0][1] <= $signed({8'b0, cache[0][1][10:5]}) * $signed(coeffs[0][1]);
          multiplied_blue_cache[0][1] <= $signed({8'b0, cache[0][1][4:0]}) * $signed(coeffs[0][1]);

          multiplied_red_cache[0][2] <= $signed({8'b0, cache[0][2][15:11]}) * $signed(coeffs[0][2]);
          multiplied_green_cache[0][2] <= $signed({8'b0, cache[0][2][10:5]}) * $signed(coeffs[0][2]);
          multiplied_blue_cache[0][2] <= $signed({8'b0, cache[0][2][4:0]}) * $signed(coeffs[0][2]);

          multiplied_red_cache[1][0] <= $signed({8'b0, cache[1][0][15:11]}) * $signed(coeffs[1][0]);
          multiplied_green_cache[1][0] <= $signed({8'b0, cache[1][0][10:5]}) * $signed(coeffs[1][0]);
          multiplied_blue_cache[1][0] <= $signed({8'b0, cache[1][0][4:0]}) * $signed(coeffs[1][0]);

          multiplied_red_cache[1][1] <= $signed({8'b0, cache[1][1][15:11]}) * coeffs[1][1];
          multiplied_green_cache[1][1] <= $signed({8'b0, cache[1][1][10:5]}) * coeffs[1][1];
          multiplied_blue_cache[1][1] <= $signed({8'b0, cache[1][1][4:0]}) * coeffs[1][1];
          // multiplied_red_cache[1][1] <= cache[1][1][15:11];
          // multiplied_green_cache[1][1] <= cache[1][1][10:5];
          // multiplied_blue_cache[1][1] <= cache[1][1][4:0];

          multiplied_red_cache[1][2] <= $signed({8'b0, cache[1][2][15:11]}) * $signed(coeffs[1][2]);
          multiplied_green_cache[1][2] <= $signed({8'b0, cache[1][2][10:5]}) * $signed(coeffs[1][2]);
          multiplied_blue_cache[1][2] <= $signed({8'b0, cache[1][2][4:0]}) * $signed(coeffs[1][2]);

          multiplied_red_cache[2][0] <= $signed({8'b0, cache[2][0][15:11]}) * $signed(coeffs[2][0]);
          multiplied_green_cache[2][0] <= $signed({8'b0, cache[2][0][10:5]}) * $signed(coeffs[2][0]);
          multiplied_blue_cache[2][0] <= $signed({8'b0, cache[2][0][4:0]}) * $signed(coeffs[2][0]);

          multiplied_red_cache[2][1] <= $signed({8'b0, cache[2][1][15:11]}) * $signed(coeffs[2][1]);
          multiplied_green_cache[2][1] <= $signed({8'b0, cache[2][1][10:5]}) * $signed(coeffs[2][1]);
          multiplied_blue_cache[2][1] <= $signed({8'b0, cache[2][1][4:0]}) * $signed(coeffs[2][1]);

          multiplied_red_cache[2][2] <= $signed({8'b0, cache[2][2][15:11]}) * $signed(coeffs[2][2]);
          multiplied_green_cache[2][2] <= $signed({8'b0, cache[2][2][10:5]}) * $signed(coeffs[2][2]);
          multiplied_blue_cache[2][2] <= $signed({8'b0, cache[2][2][4:0]}) * $signed(coeffs[2][2]);

          // for (int i = 0; i<3; i= i+1) begin
          //   multiplied_red_cache[i][0] <= $signed({8'b0, cache[i][0][15:11]}) * $signed(coeffs[i][0]);
          //   multiplied_green_cache[i][0] <= $signed({8'b0, cache[i][0][10:5]}) * $signed(coeffs[i][0]);
          //   multiplied_blue_cache[i][0] <= $signed({8'b0, cache[i][0][4:0]}) * $signed(coeffs[i][0]);

          //   multiplied_red_cache[i][1] <= $signed({8'b0, cache[i][1][15:11]}) * $signed(coeffs[i][1]);
          //   multiplied_green_cache[i][1] <= $signed({8'b0, cache[i][1][10:5]}) * $signed(coeffs[i][1]);
          //   multiplied_blue_cache[i][1] <= $signed({8'b0, cache[i][1][4:0]}) * $signed(coeffs[i][1]);

          //   multiplied_red_cache[i][2] <= $signed({8'b0, cache[i][2][15:11]}) * $signed(coeffs[i][2]);
          //   multiplied_green_cache[i][2] <= $signed({8'b0, cache[i][2][10:5]}) * $signed(coeffs[i][2]);
          //   multiplied_blue_cache[i][2] <= $signed({8'b0, cache[i][2][4:0]}) * $signed(coeffs[i][2]);
          // end
          // for (int i = 0; i<3; i= i+1) begin
          //   for (int j = 0; j<3; j= j+1) begin
          //     multiplied_red_cache[i][j] <= $signed({8'b0, cache[i][j][15:11]}) * $signed(coeffs[i][j]);
          //     multiplied_green_cache[i][j] <= $signed({8'b0, cache[i][j][10:5]}) * $signed(coeffs[i][j]);
          //     multiplied_blue_cache[i][j] <= $signed({8'b0, cache[i][j][4:0]}) * $signed(coeffs[i][j]);
          //   end
          // end
          // for (int j = 0; j<3; j= j+1) begin
          //   multiplied_red_cache[0][j] <= $signed({8'b0, cache[0][j][15:11]}) * $signed(coeffs[0][j]);
          //   multiplied_green_cache[0][j] <= $signed({8'b0, cache[0][j][10:5]}) * $signed(coeffs[0][j]);
          //   multiplied_blue_cache[0][j] <= $signed({8'b0, cache[0][j][4:0]}) * $signed(coeffs[0][j]);
          // end
          // for (int j = 0; j<3; j= j+1) begin
          //   multiplied_red_cache[1][j] <= $signed({8'b0, cache[1][j][15:11]}) * $signed(coeffs[1][j]);
          //   multiplied_green_cache[1][j] <= $signed({8'b0, cache[1][j][10:5]}) * $signed(coeffs[1][j]);
          //   multiplied_blue_cache[1][j] <= $signed({8'b0, cache[1][j][4:0]}) * $signed(coeffs[1][j]);
          // end
          // for (int j = 0; j<3; j= j+1) begin
          //   multiplied_red_cache[2][j] <= $signed({8'b0, cache[2][j][15:11]}) * $signed(coeffs[2][j]);
          //   multiplied_green_cache[2][j] <= $signed({8'b0, cache[2][j][10:5]}) * $signed(coeffs[2][j]);
          //   multiplied_blue_cache[2][j] <= $signed({8'b0, cache[2][j][4:0]}) * $signed(coeffs[2][j]);
          // end
          // multiplied_red_cache <= {
          //   $signed({8'b0, cache[0][0][15:11]}) * $signed(coeffs[0][0]),
          //   $signed({8'b0, cache[1][0][15:11]}) * $signed(coeffs[1][0]),
          //   $signed({8'b0, cache[2][0][15:11]}) * $signed(coeffs[2][0]),
          //   $signed({8'b0, cache[0][1][15:11]}) * $signed(coeffs[0][1]),
          //   $signed({8'b0, cache[1][1][15:11]}) * $signed(coeffs[1][1]),
          //   $signed({8'b0, cache[2][1][15:11]}) * $signed(coeffs[2][1]),
          //   $signed({8'b0, cache[0][2][15:11]}) * $signed(coeffs[0][2]),
          //   $signed({8'b0, cache[1][2][15:11]}) * $signed(coeffs[1][2]),
          //   $signed({8'b0, cache[2][2][15:11]}) * $signed(coeffs[2][2])
          // };
          // multiplied_green_cache <= {
          //   13'($signed({8'b0, cache[0][0][10:5]}) * $signed(coeffs[0][0])),
          //   13'($signed({8'b0, cache[1][0][10:5]}) * $signed(coeffs[1][0])),
          //   13'($signed({8'b0, cache[2][0][10:5]}) * $signed(coeffs[2][0])),
          //   13'($signed({8'b0, cache[0][1][10:5]}) * $signed(coeffs[0][1])),
          //   13'($signed({8'b0, cache[1][1][10:5]}) * $signed(coeffs[1][1])),
          //   13'($signed({8'b0, cache[2][1][10:5]}) * $signed(coeffs[2][1])),
          //   13'($signed({8'b0, cache[0][2][10:5]}) * $signed(coeffs[0][2])),
          //   13'($signed({8'b0, cache[1][2][10:5]}) * $signed(coeffs[1][2])),
          //   13'($signed({8'b0, cache[2][2][10:5]}) * $signed(coeffs[2][2]))
          // };
          // multiplied_blue_cache <= {
          //   12'($signed({8'b0, cache[0][0][4:0]}) * $signed(coeffs[0][0])),
          //   12'($signed({8'b0, cache[1][0][4:0]}) * $signed(coeffs[1][0])),
          //   12'($signed({8'b0, cache[2][0][4:0]}) * $signed(coeffs[2][0])),
          //   12'($signed({8'b0, cache[0][1][4:0]}) * $signed(coeffs[0][1])),
          //   12'($signed({8'b0, cache[1][1][4:0]}) * $signed(coeffs[1][1])),
          //   12'($signed({8'b0, cache[2][1][4:0]}) * $signed(coeffs[2][1])),
          //   12'($signed({8'b0, cache[0][2][4:0]}) * $signed(coeffs[0][2])),
          //   12'($signed({8'b0, cache[1][2][4:0]}) * $signed(coeffs[1][2])),
          //   12'($signed({8'b0, cache[2][2][4:0]}) * $signed(coeffs[2][2]))
          // };
          // for (int i = 0; i<3; i= i+1) begin
          //   for (int j = 0; j<3; j= j+1) begin
          //     multiplied_red_cache[i][j] = $signed({8'b0, cache[i][j][15:11]}) * $signed(coeffs[i][j]);
          //     multiplied_green_cache[i][j] = $signed({8'b0, cache[i][j][10:5]}) * $signed(coeffs[i][j]);
          //     multiplied_blue_cache[i][j] = $signed({8'b0, cache[i][j][4:0]}) * $signed(coeffs[i][j]);
          //     // multiplied_cache[i][j] <= {
          //     //   11'(),
          //     //   12'($signed(8'b0, cache[i][j][10:5]) * $signed(coeffs[i][j])),
          //     //   11'($signed(8'b0, cache[i][j][4:0]) * $signed(coeffs[i][j]))
          //     // };
          //   end
          // end
        end

        if (data_valid_pipe[1]) begin
          // shifted_red_cache <= multiplied_red_cache[1][1];
          // shifted_green_cache <= multiplied_green_cache[1][1];
          // shifted_blue_cache <= multiplied_blue_cache[1][1];
          shifted_red_cache <= (
            ($signed(multiplied_red_cache[0][0]) +
            $signed(multiplied_red_cache[1][0]) +
            $signed(multiplied_red_cache[2][0]) +
            $signed(multiplied_red_cache[0][1]) +
            $signed(multiplied_red_cache[1][1]) +
            $signed(multiplied_red_cache[2][1]) +
            $signed(multiplied_red_cache[0][2]) +
            $signed(multiplied_red_cache[1][2]) +
            $signed(multiplied_red_cache[2][2]))
           > 0 ? (
            ($signed(multiplied_red_cache[0][0]) +
            $signed(multiplied_red_cache[1][0]) +
            $signed(multiplied_red_cache[2][0]) +
            $signed(multiplied_red_cache[0][1]) +
            $signed(multiplied_red_cache[1][1]) +
            $signed(multiplied_red_cache[2][1]) +
            $signed(multiplied_red_cache[0][2]) +
            $signed(multiplied_red_cache[1][2]) +
            $signed(multiplied_red_cache[2][2]))
             >>> shift) : 0);
          shifted_green_cache <= (
            ($signed(multiplied_green_cache[0][0]) +
            $signed(multiplied_green_cache[1][0]) +
            $signed(multiplied_green_cache[2][0]) +
            $signed(multiplied_green_cache[0][1]) +
            $signed(multiplied_green_cache[1][1]) +
            $signed(multiplied_green_cache[2][1]) +
            $signed(multiplied_green_cache[0][2]) +
            $signed(multiplied_green_cache[1][2]) +
            $signed(multiplied_green_cache[2][2]))
           > 0 ? (
            ($signed(multiplied_green_cache[0][0]) +
            $signed(multiplied_green_cache[1][0]) +
            $signed(multiplied_green_cache[2][0]) +
            $signed(multiplied_green_cache[0][1]) +
            $signed(multiplied_green_cache[1][1]) +
            $signed(multiplied_green_cache[2][1]) +
            $signed(multiplied_green_cache[0][2]) +
            $signed(multiplied_green_cache[1][2]) +
            $signed(multiplied_green_cache[2][2]))
             >>> shift) : 0);
          shifted_blue_cache <= (
            ($signed(multiplied_blue_cache[0][0]) +
            $signed(multiplied_blue_cache[1][0]) +
            $signed(multiplied_blue_cache[2][0]) +
            $signed(multiplied_blue_cache[0][1]) +
            $signed(multiplied_blue_cache[1][1]) +
            $signed(multiplied_blue_cache[2][1]) +
            $signed(multiplied_blue_cache[0][2]) +
            $signed(multiplied_blue_cache[1][2]) +
            $signed(multiplied_blue_cache[2][2]))
           > 0 ? (
            ($signed(multiplied_blue_cache[0][0]) +
            $signed(multiplied_blue_cache[1][0]) +
            $signed(multiplied_blue_cache[2][0]) +
            $signed(multiplied_blue_cache[0][1]) +
            $signed(multiplied_blue_cache[1][1]) +
            $signed(multiplied_blue_cache[2][1]) +
            $signed(multiplied_blue_cache[0][2]) +
            $signed(multiplied_blue_cache[1][2]) +
            $signed(multiplied_blue_cache[2][2]))
             >>> shift) : 0);
          // shifted_red_cache <= 5'(added_red_cache > 0 ? (added_red_cache >>> shift) <<< offset : 0);
          // shifted_green_cache <= 6'(added_green_cache > 0 ? (added_green_cache >>> shift) <<< offset : 0);
          // shifted_blue_cache <= 5'(added_blue_cache > 0 ? (added_blue_cache >>> shift) <<< offset : 0);
        end

        // Make sure to have your output be set with registered logic!
        // Otherwise you'll have timing violations.
        line_out <= {shifted_red_cache, shifted_green_cache, shifted_blue_cache};
        // line_out <= cache[1][1];
        data_valid_out <= data_valid_pipe[2];
        hcount_out <= hcount_pipe[2];
        vcount_out <= vcount_pipe[2];

        // line_out <= data_in[1];
        // data_valid_out <= data_valid_in;
        // hcount_out <= hcount_in;
        // vcount_out <= vcount_in;
      end
    end
endmodule

`default_nettype wire
