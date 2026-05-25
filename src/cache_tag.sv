/**
 * @file cache_tag.sv
 * @brief Memória de Tags da Cache
 *
 * Este módulo armazena as tags e os bits de validade/sujeira (dirty bit)
 * para controle de correspondência e consistência de dados da cache.
 */

module cache_tag (
    input  logic        clk,
    input  logic        rst,
    // Interface de Acesso
    input  logic [7:0]  index,      // Índice para acesso à linha da cache
    input  logic        we,         // Habilita escrita de tag/status
    input  logic [19:0] tag_in,     // Tag a ser gravada
    input  logic        valid_in,   // Bit de validade a ser gravado
    input  logic        dirty_in,   // Bit de dirty a ser gravado
    
    // Saídas correspondentes ao índice
    output logic [19:0] tag_out,
    output logic        valid_out,
    output logic        dirty_out
);

    // TODO: Implementar array de armazenamento de tags e bits de controle

endmodule
