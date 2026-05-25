/**
 * @file cache_controller_tb.sv
 * @brief Testbench para Validação Funcional do Controlador de Cache
 *
 * Instancia o controlador de cache e o modelo de memória principal,
 * aplicando estímulos de leitura/escrita e monitorando as saídas (waveforms).
 */

`timescale 1ns/1ps

module cache_controller_tb;

    // Sinais de Clock e Reset
    logic clk;
    logic rst;

    // Sinais da CPU
    logic [31:0] cpu_addr;
    logic [31:0] cpu_wdata;
    logic        cpu_req;
    logic        cpu_write;
    logic [31:0] cpu_rdata;
    logic        cpu_ready;

    // Sinais da Memória Principal
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic        mem_req;
    logic        mem_write;
    logic [31:0] mem_rdata;
    logic        mem_ready;

    // Instanciação do Controlador de Cache (DUT)
    cache_controller dut (
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // Instanciação do Modelo de Memória Principal
    mem_main_model #(
        .MEM_DELAY(5)
    ) main_mem (
        .clk(clk),
        .rst(rst),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_req(mem_req),
        .mem_write(mem_write),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // Geração do Clock (50MHz -> Período de 20ns)
    always #10 clk = ~clk;

    // Procedimento de Teste
    initial begin
        // Geração de VCD para ondas de simulação
        $dumpfile("dump.vcd");
        $dumpvars(0, cache_controller_tb);

        // Inicialização de Sinais
        clk = 0;
        rst = 1;
        cpu_addr = 0;
        cpu_wdata = 0;
        cpu_req = 0;
        cpu_write = 0;

        // Reset do Sistema
        #40;
        rst = 0;
        #20;

        // TODO: Adicionar sequências de teste (Reads/Writes, Misses, Hits)

        $display("Simulação concluída!");
        $finish;
    end

endmodule
