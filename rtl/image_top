`timescale 1ns / 1ps
module image_top(
    input wire clk,
    input wire resetn,

    input  wire start,
    output wire done,

    // External BRAM1 side connected to AXI BRAM Controller in Block Design
    input  wire bram1_clka,
    input  wire bram1_ena,
    input  wire bram1_wea,
    input  wire [13:0] bram1_addra,
    input  wire [7:0]  bram1_dina,
    output wire [7:0]  bram1_douta,

    // External BRAM2 side connected to AXI BRAM Controller in Block Design
    input  wire bram2_clka,
    input  wire bram2_ena,
    input  wire bram2_wea,
    input  wire [13:0] bram2_addra,
    input  wire [7:0]  bram2_dina,
    output wire [7:0]  bram2_douta
);

    wire bram1_en;
    wire bram2_en;
    wire bram2_we;

    wire [13:0] bram1_addr;
    wire [13:0] bram2_addr;

    wire [7:0] bram1_dout;
    wire [7:0] bram2_din;
    wire [7:0] bram2_dout;

    wire [7:0] sobel_result;

    wire [7:0] p00, p01, p02;
    wire [7:0] p10, p11, p12;
    wire [7:0] p20, p21, p22;

    wire [71:0] pixel_window;

    // ============================================================
    // MARK_DEBUG signals for ILA / Set Up Debug
    // These do not change the block design ports.
    // ============================================================
    (* mark_debug = "true" *) wire dbg_start_int;
    (* mark_debug = "true" *) wire dbg_done_int;

    (* mark_debug = "true" *) wire dbg_bram1_en_int;
    (* mark_debug = "true" *) wire [13:0] dbg_bram1_addr_int;
    (* mark_debug = "true" *) wire [7:0]  dbg_bram1_dout_int;

    (* mark_debug = "true" *) wire dbg_bram2_en_int;
    (* mark_debug = "true" *) wire dbg_bram2_we_int;
    (* mark_debug = "true" *) wire [13:0] dbg_bram2_addr_int;
    (* mark_debug = "true" *) wire [7:0]  dbg_bram2_din_int;

    (* mark_debug = "true" *) wire [7:0] dbg_sobel_result_int;

    assign dbg_start_int       = start;
    assign dbg_done_int        = done;

    assign dbg_bram1_en_int    = bram1_en;
    assign dbg_bram1_addr_int  = bram1_addr;
    assign dbg_bram1_dout_int  = bram1_dout;

    assign dbg_bram2_en_int    = bram2_en;
    assign dbg_bram2_we_int    = bram2_we;
    assign dbg_bram2_addr_int  = bram2_addr;
    assign dbg_bram2_din_int   = bram2_din;

    assign dbg_sobel_result_int = sobel_result;

    assign pixel_window = {
        p22, p21, p20,
        p12, p11, p10,
        p02, p01, p00
    };

    image_cntrl #(
        .BRAM1_BW(8),
        .BRAM1_AMAX(10404),
        .BRAM2_BW(8),
        .BRAM2_AMAX(10000)
    ) controller_inst (
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .done(done),

        .bram1_en(bram1_en),
        .bram2_en(bram2_en),
        .bram2_we(bram2_we),

        .bram1_addr(bram1_addr),
        .bram2_addr(bram2_addr),

        .bram1_dout(bram1_dout),
        .bram2_din(bram2_din),

        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),

        .sobel_result(sobel_result)
    );

    sobel_core sobel_inst (
        .pixel_data(pixel_window),
        .o_convolved_data(sobel_result)
    );

    // ============================================================
    // BRAM1
    // Port A = PL/Sobel controller side
    // Port B = AXI/Block Design side
    // ============================================================
    BRAM1 BRAM1 (
        // Port A: PL side
        .clka(clk),
        .ena(bram1_en),
        .wea(1'b0),
        .addra(bram1_addr),
        .dina(8'd0),
        .douta(bram1_dout),

        // Port B: AXI/Block Design side
        .clkb(bram1_clka),
        .enb(bram1_ena),
        .web(bram1_wea),
        .addrb(bram1_addra),
        .dinb(bram1_dina),
        .doutb(bram1_douta)
    );

    // ============================================================
    // BRAM2
    // Port A = PL/Sobel controller side
    // Port B = AXI/Block Design side
    // ============================================================
    BRAM2 BRAM2 (
        // Port A: PL side
        .clka(clk),
        .ena(bram2_en),
        .wea(bram2_we),
        .addra(bram2_addr),
        .dina(bram2_din),
        .douta(bram2_dout),

        // Port B: AXI/Block Design side
        .clkb(bram2_clka),
        .enb(bram2_ena),
        .web(bram2_wea),
        .addrb(bram2_addra),
        .dinb(bram2_dina),
        .doutb(bram2_douta)
    );

endmodule
