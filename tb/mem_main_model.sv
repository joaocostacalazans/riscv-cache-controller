/**
 * @file mem_main_model.sv
 * @brief Modelo de Simulação da Memória Principal
 *
 * Simula a memória principal com atrasos configuráveis para leitura/escrita,
 * permitindo testar o comportamento assíncrono ou com latência do controlador de cache.
 */

module mem_main_model #(
    parameter int MEM_DELAY = 5 // Número de ciclos de clock para responder
)(
    input  logic        clk,
    input  logic        rst,
    
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic        mem_req,
    input  logic        mem_write,
    
    output logic [31:0] mem_rdata,
    output logic        mem_ready
);

    // Memória interna simplificada (ex: tabela hash ou array esparso)
    logic [31:0] ram [0:1023]; // Pequena memória local de teste
    
    // Controle de Latência
    int counter;
    logic busy;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter   <= 0;
            busy      <= 0;
            mem_ready <= 0;
            mem_rdata <= 32'd0;
        end else begin
            if (mem_req && !busy) begin
                busy <= 1;
                counter <= MEM_DELAY;
            end
            
            if (busy) begin
                if (counter > 1) begin
                    counter <= counter - 1;
                end else begin
                    busy <= 0;
                    mem_ready <= 1;
                    if (mem_write) begin
                        ram[mem_addr[11:2]] <= mem_wdata;
                    end else begin
                        mem_rdata <= ram[mem_addr[11:2]];
                    end
                end
            end else begin
                mem_ready <= 0;
            end
        end
    end

endmodule
