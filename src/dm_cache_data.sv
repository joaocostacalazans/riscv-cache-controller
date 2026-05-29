/**
 * @file dm_cache_data.sv
 * @brief Memória de Dados — Cache Direct-Mapped
 *
 * Módulo de armazenamento dos dados para uma cache direct-mapped com
 * 1024 blocos, cada um contendo uma linha de 128 bits (4 palavras de 32 bits).
 *
 * Decisões de temporização:
 *   - Escrita: SÍNCRONA em posedge clk, habilitada por 'we'.
 *   - Leitura: ASSÍNCRONA (combinacional) — a saída reflete continuamente
 *     a linha de cache endereçada por 'index'.
 *   - Reset: NÃO POSSUI — a validade dos dados é controlada exclusivamente
 *     pelo bit 'valid' no tag array (dm_cache_tag). Dados inválidos
 *     nunca são utilizados pela FSM, tornando desnecessária a inicialização
 *     do data array no reset.
 *
 * Decisões de projeto:
 *   - Este módulo opera no nível de LINHA (128 bits). A seleção de uma
 *     palavra individual (via campo offset addr[3:2]) é responsabilidade
 *     do controlador FSM na camada superior, utilizando multiplexação.
 *   - Essa separação de responsabilidades simplifica o data array e
 *     facilita a reutilização em diferentes configurações de cache.
 */

module dm_cache_data
    import cache_def::*;
(
    input  logic                    clk,

    // Porta de Acesso (indexada por addr[13:4])
    input  logic [INDEX_WIDTH-1:0]  index,      // Índice do bloco (10 bits)
    input  logic                    we,         // Habilitação de escrita
    input  cache_data_type          data_in,    // Linha completa de entrada (128 bits)

    // Saída Combinacional
    output cache_data_type          data_out    // Linha lida no índice atual (128 bits)
);

    // =========================================================================
    // Armazenamento Interno
    // =========================================================================
    //
    // Array de 1024 linhas de cache, cada uma com 128 bits.
    // Tamanho total: 1024 × 128 bits = 16 KB.
    //
    // Em uma implementação FPGA, este array será sintetizado como Block RAM
    // (BRAM) ou Distributed RAM, dependendo das restrições do sintetizador.
    //
    cache_data_type data_mem [0:NUM_BLOCKS-1];

    // =========================================================================
    // Leitura Assíncrona (Combinacional)
    // =========================================================================
    //
    // Justificativa: A leitura combinacional permite que o controlador FSM
    // obtenha a linha de dados no mesmo ciclo em que determina um cache hit
    // (via comparação de tag no dm_cache_tag). A palavra específica dentro
    // da linha é selecionada pelo controlador usando o campo offset[3:2]
    // do endereço:
    //
    //   Offset = 2'b00 → data_out[31:0]    (Palavra 0)
    //   Offset = 2'b01 → data_out[63:32]   (Palavra 1)
    //   Offset = 2'b10 → data_out[95:64]   (Palavra 2)
    //   Offset = 2'b11 → data_out[127:96]  (Palavra 3)
    //
    assign data_out = data_mem[index];

    // =========================================================================
    // Escrita Síncrona
    // =========================================================================
    //
    // A escrita de uma linha completa de 128 bits ocorre estritamente na
    // borda positiva do clock, condicionada ao sinal 'we'.
    //
    // Cenários de uso (controlados pela FSM):
    //   1. ALLOCATE: Linha completa recebida da memória principal é gravada.
    //   2. WRITE HIT: A FSM constrói a linha atualizada (read-modify-write
    //      na palavra específica) e grava a linha completa modificada.
    //
    always_ff @(posedge clk) begin
        if (we)
            data_mem[index] <= data_in;
    end

endmodule
