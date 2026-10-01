module sobel_core(
    input  [71:0] pixel_data,
    output [7:0]  o_convolved_data
);

wire signed [8:0] p00 = $signed({1'b0, pixel_data[0*8 +: 8]});
wire signed [8:0] p01 = $signed({1'b0, pixel_data[1*8 +: 8]});
wire signed [8:0] p02 = $signed({1'b0, pixel_data[2*8 +: 8]});

wire signed [8:0] p10 = $signed({1'b0, pixel_data[3*8 +: 8]});
wire signed [8:0] p11 = $signed({1'b0, pixel_data[4*8 +: 8]});
wire signed [8:0] p12 = $signed({1'b0, pixel_data[5*8 +: 8]});

wire signed [8:0] p20 = $signed({1'b0, pixel_data[6*8 +: 8]});
wire signed [8:0] p21 = $signed({1'b0, pixel_data[7*8 +: 8]});
wire signed [8:0] p22 = $signed({1'b0, pixel_data[8*8 +: 8]});

wire signed [13:0] sx;
wire signed [13:0] sy;

assign sx = p00 - p02
          + (p10 <<< 1) - (p12 <<< 1)
          + p20 - p22;

assign sy = p00 + (p01 <<< 1) + p02
          - p20 - (p21 <<< 1) - p22;

wire [13:0] abs_sx = sx[13] ? -sx : sx;
wire [13:0] abs_sy = sy[13] ? -sy : sy;

wire [14:0] sobel_sum = abs_sx + abs_sy;

assign o_convolved_data = (sobel_sum > 15'd255) ? 8'd255 : sobel_sum[7:0];

endmodule
