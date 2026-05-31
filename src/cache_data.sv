/**
 * @file cache_data.sv
 * @brief Memória de Dados da Cache
 *
 * Este módulo armazena as palavras de dados correspondentes
 * a cada linha da cache.
 */

module cache_data (
    input  logic         clk,

    // Acesso por palavra
    input  logic [9:0]   index,       // Seleciona uma das 1024 linhas
    input  logic [1:0]   offset,      // Seleciona uma das 4 palavras da linha (0 a 3)
    input  logic         we,          // Habilita escrita de uma palavra
    input  logic [31:0]  data_in,     // Palavra a ser escrita
    
    output logic [31:0]  data_out,     // Palavra lida

    // Acesso por linha inteira
    input  logic          line_we,    // Habilita escrita da linha completa  
    input  logic [127:0]  line_in,    // {word3, word2, word1, word0}

    output logic [127:0]  line_out    // Linha completa
);

    // 1024 linhas de cache, cada uma contendo 4 palavras de 32 bits
    logic [31:0] data_array [0:1023][0:3];

    localparam int WORDS_PER_LINE = 4;

    always_comb begin

        // Leitura de uma palavra
        data_out = data_array[index][offset];

        // Leitura da linha completa
        for (int i = 0; i < WORDS_PER_LINE; i++) begin
            line_out[i*32 +: 32] = data_array[index][i];
        end

    end

    always_ff @(posedge clk) begin

        // Escrita de uma palavra
        if (we) begin
            data_array[index][offset] <= data_in;
        end

        // Escrita de uma linha completa
        else if (line_we) begin
            for (int i = 0; i < WORDS_PER_LINE; i++) begin
                data_array[index][i] <= line_in[i*32 +: 32];
            end
        end

    end

endmodule
