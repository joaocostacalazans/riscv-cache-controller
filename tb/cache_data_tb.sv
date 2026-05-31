`timescale 1ns/1ps

module cache_data_tb;

    logic         clk;

    logic [9:0]   index;
    logic [1:0]   offset;
    logic         we;
    logic [31:0]  data_in;
    logic [31:0]  data_out;

    logic         line_we;
    logic [127:0] line_in;
    logic [127:0] line_out;

    // Instância do DUT (Device Under Test)
    cache_data dut (
        .clk(clk),
        .index(index),
        .offset(offset),
        .we(we),
        .data_in(data_in),
        .data_out(data_out),
        .line_we(line_we),
        .line_in(line_in),
        .line_out(line_out)
    );

    // Gerador de clock, período de 10 ns
    always #5 clk = ~clk;

    initial begin

        clk     = 0;
        index   = 0;
        offset  = 0;
        we      = 0;
        data_in = 0;

        line_we = 0;
        line_in = 0;

        // ====================
        // TD-01
        // Word write + read
        // ====================

        index   = 10;
        offset  = 2;
        data_in = 32'h12345678;
        we      = 1;

        @(posedge clk);

        #1;

        we = 0;

        if (data_out == 32'h12345678)
            $display("TD-01 PASS");
        else
            $display("TD-01 FAIL");


        // ====================
        // TD-02
        // Line write + word read
        // ====================

        index   = 20;

        line_in = {
            32'h44444444,
            32'h33333333,
            32'h22222222,
            32'h11111111
        };

        line_we = 1;

        @(posedge clk);

        #1;

        line_we = 0;

        // Offset 0
        offset = 0;
        #1;
        if (data_out != 32'h11111111)
            $display("TD-02 FAIL (offset 0)");

        // Offset 1
        offset = 1;
        #1;
        if (data_out != 32'h22222222)
            $display("TD-02 FAIL (offset 1)");

        // Offset 2
        offset = 2;
        #1;
        if (data_out != 32'h33333333)
            $display("TD-02 FAIL (offset 2)");

        // Offset 3
        offset = 3;
        #1;
        if (data_out != 32'h44444444)
            $display("TD-02 FAIL (offset 3)");

        $display("TD-02 PASS");

        // ====================
        // TD-03
        // Line write + line read
        // ====================

        index = 30;

        line_in = {
            32'hAAAAAAAA,
            32'hBBBBBBBB,
            32'hCCCCCCCC,
            32'hDDDDDDDD
        };

        line_we = 1;

        @(posedge clk);

        #1;

        line_we = 0;

        #1;

        if (line_out == line_in)
            $display("TD-03 PASS");
        else
            $display("TD-03 FAIL");

        // ====================
        // TD-04
        // Word write preserves line
        // ====================

        index = 40;

        line_in = {
            32'h44444444,
            32'h33333333,
            32'h22222222,
            32'h11111111
        };

        line_we = 1;

        @(posedge clk);

        #1;

        line_we = 0;

        // altera apenas word2
        offset  = 2;
        data_in = 32'hAAAAAAAA;
        we      = 1;

        @(posedge clk);

        #1;

        we = 0;

        if (line_out == {
                32'h44444444,
                32'hAAAAAAAA,
                32'h22222222,
                32'h11111111
            })
            $display("TD-04 PASS");
        else
            $display("TD-04 FAIL");

        // ====================
        // TD-05
        // Cross-index isolation
        // ====================

        // Linha 50
        index = 50;

        line_in = {
            32'h44444444,
            32'h33333333,
            32'h22222222,
            32'h11111111
        };

        line_we = 1;

        @(posedge clk);

        #1;

        line_we = 0;

        // Linha 51
        index = 51;

        line_in = {
            32'hDDDDDDDD,
            32'hCCCCCCCC,
            32'hBBBBBBBB,
            32'hAAAAAAAA
        };

        line_we = 1;

        @(posedge clk);

        #1;

        line_we = 0;

        // Verifica linha 50
        index = 50;

        #1;

        if (line_out != {
                32'h44444444,
                32'h33333333,
                32'h22222222,
                32'h11111111
            })
            $display("TD-05 FAIL (linha 50)");

        // Verifica linha 51
        index = 51;

        #1;

        if (line_out != {
                32'hDDDDDDDD,
                32'hCCCCCCCC,
                32'hBBBBBBBB,
                32'hAAAAAAAA
            })
            $display("TD-05 FAIL (linha 51)");

        $display("TD-05 PASS");

        #20;
        $finish;

    end

endmodule