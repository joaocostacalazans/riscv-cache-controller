/**
 * @file mem_main_model.sv
 * @brief Modelo de Simulação da Memória Principal (Atualizado para T4)
 */

module mem_main_model #(
    parameter int    MEM_DELAY     = 5, // Número de ciclos de clock para responder
    parameter string MEM_INIT_FILE = "" // [T4] Caminho para o arquivo .hex
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

    // Memória interna simplificada
    logic [31:0] ram [0:1023]; 
    
    // [T4] Inicialização opcional via arquivo .hex
    initial begin
        // Preenche com um padrão detectável (ajuda a achar bugs de leitura de lixo)
        for (int i = 0; i < 1024; i++) begin
            ram[i] = 32'hDEAD_BEEF; 
        end
        // Carrega parâmetro se o usuário passou em um arquivo
        if (MEM_INIT_FILE != "") begin
            $readmemh(MEM_INIT_FILE, ram);
        end
    end
    
    // Controle de Latência
    int counter;
    logic busy;
    logic burst_mode; // [T4] Nova flag para controlar o estado pós-delay inicial

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter    <= 0;
            busy       <= 0;
            burst_mode <= 0; // [T4]
            mem_ready  <= 0;
            mem_rdata  <= 32'd0;
        end else begin
            // Caso 1: Nova requisição vinda da cache (inicia a contagem de delay)
            if (mem_req && !busy && !burst_mode) begin
                busy <= 1;
                counter <= MEM_DELAY;
            end
            
            // Caso 2: Memória está contando o tempo de latência (sua lógica original)
            if (busy) begin
                if (counter > 1) begin
                    counter <= counter - 1;
                end else begin
                    busy <= 0;
                    burst_mode <= 1; // [T4] Ativa o modo burst para as próximas palavras
                    mem_ready  <= 1;
                    
                    if (mem_write) begin
                        ram[mem_addr[11:2]] <= mem_wdata;
                    end else begin
                        mem_rdata <= ram[mem_addr[11:2]];
                    end
                end
            end
            // Caso 3: [T4] Modo Burst (Acessos sequenciais imediatos de 1 ciclo)
            else if (burst_mode) begin
                if (mem_req) begin
                    mem_ready <= 1; // Responde imediatamente no mesmo ciclo
                    if (mem_write) begin
                        ram[mem_addr[11:2]] <= mem_wdata;
                    end else begin
                        mem_rdata <= ram[mem_addr[11:2]];
                    end
                end else begin
                    // A cache terminou de ler/escrever as 4 palavras e baixou o mem_req
                    mem_ready  <= 0;
                    burst_mode <= 0; // Desliga o modo burst e volta para o IDLE
                end
            end 
            // Caso 4: Memória ociosa
            else begin
                mem_ready <= 0;
            end
        end
    end

endmodule