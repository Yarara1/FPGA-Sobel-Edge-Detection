`timescale 1ns / 1ps

module tb_image_top;

    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg resetn;
    reg start;
    wire done;

    // BRAM1 Port A: testbench writes input image
    reg bram1_ena;
    reg bram1_wea;
    reg [13:0] bram1_addra;
    reg [7:0]  bram1_dina;
    wire [7:0] bram1_douta;

    // BRAM2 Port A: testbench reads output image
    reg bram2_ena;
    reg bram2_wea;
    reg [13:0] bram2_addra;
    reg [7:0]  bram2_dina;
    wire [7:0] bram2_douta;

    reg [7:0] input_mem [0:10403]; // 102x102 input image

    integer i;
    integer outfile;

    image_top DUT (
        .clk(clk),
        .resetn(resetn),

        .start(start),
        .done(done),

        .bram1_clka(clk),
        .bram1_ena(bram1_ena),
        .bram1_wea(bram1_wea),
        .bram1_addra(bram1_addra),
        .bram1_dina(bram1_dina),
        .bram1_douta(bram1_douta),

        .bram2_clka(clk),
        .bram2_ena(bram2_ena),
        .bram2_wea(bram2_wea),
        .bram2_addra(bram2_addra),
        .bram2_dina(bram2_dina),
        .bram2_douta(bram2_douta)
    );

    initial begin
        $display("Testing full 100x100 image and dumping BRAM2 output...");

        resetn = 1'b1;
        start  = 1'b0;

        bram1_ena   = 1'b0;
        bram1_wea   = 1'b0;
        bram1_addra = 14'd0;
        bram1_dina  = 8'd0;

        bram2_ena   = 1'b0;
        bram2_wea   = 1'b0;
        bram2_addra = 14'd0;
        bram2_dina  = 8'd0;

        $readmemh("C:/Users/Yara/Downloads/flower_input_102x102.hex", input_mem);

        #50;
        resetn = 1'b0;
        #50;
        resetn = 1'b1;
        #50;

        load_bram1();

        #50;

        outfile = $fopen("output_from_fpga.hex", "w");

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        $display("DUT finished at time %0t", $time);

        repeat(10) @(posedge clk);

        dump_bram2();

        $display("PASS: output_from_fpga.hex created.");

        #100;
        $finish;
    end

    initial begin
        #5000000;
        $display("ERROR: Simulation timeout.");
        $finish;
    end

    task load_bram1;
        begin
            $display("Loading BRAM1 with 102x102 input image...");

            for(i = 0; i < 10404; i = i + 1) begin
                @(negedge clk);
                bram1_ena   = 1'b1;
                bram1_wea   = 1'b1;
                bram1_addra = i[13:0];
                bram1_dina  = input_mem[i];
            end

            @(negedge clk);
            bram1_wea = 1'b0;
            bram1_ena = 1'b0;

            $display("Finished loading BRAM1.");
        end
    endtask

    task dump_bram2;
        begin
            $display("Writing BRAM2 output to output_from_fpga.hex...");

            bram2_ena = 1'b1;
            bram2_wea = 1'b0;

            for(i = 0; i < 10000; i = i + 1) begin
                @(negedge clk);
                bram2_addra = i[13:0];

                // BRAM read latency
                @(posedge clk);
                @(posedge clk);
                #1;

                $fwrite(outfile, "%02x\n", bram2_douta);
            end

            @(negedge clk);
            bram2_ena = 1'b0;

            $fclose(outfile);

            $display("Finished writing output_from_fpga.hex.");
        end
    endtask

endmodule
