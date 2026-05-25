/**
 * @file cache_data.sv
 * @brief Memória de Dados da Cache
 *
 * Este módulo armazena as palavras de dados correspondentes
 * a cada linha da cache.
 */

module cache_data (
    input  logic         clk,
    // Interface de Acesso
    input  logic [7:0]   index,       // Índice da linha na cache
    input  logic         we,          // Habilita escrita nos dados
    input  logic [1:0]   offset,      // Offset da palavra na linha
    input  logic [31:0]  data_in,     // Dados de entrada para escrita
    
    output logic [31:0]  data_out     // Dados lidos correspondentes
);

    // TODO: Implementar array de armazenamento de dados (data array)

endmodule
