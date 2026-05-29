/**
 * @file dm_cache_tag.sv
 * @brief Memória de Tags — Cache Direct-Mapped
 *
 * Módulo de armazenamento das tags e bits de controle (valid, dirty)
 * para uma cache direct-mapped com 1024 blocos e tags de 18 bits.
 *
 * Decisões de temporização:
 *   - Escrita: SÍNCRONA em posedge clk, habilitada por 'we'.
 *   - Leitura: ASSÍNCRONA (combinacional) — a saída reflete continuamente
 *     o conteúdo da posição endereçada por 'index', permitindo que a FSM
 *     resolva hit/miss no mesmo ciclo em que entra em COMPARE_TAG.
 *   - Reset: ASSÍNCRONO (posedge rst) — limpa todos os bits de validade,
 *     garantindo estado "frio" (cold start) na inicialização.
 */

module dm_cache_tag
    import cache_def::*;
(
    input  logic                    clk,
    input  logic                    rst,

    // Porta de Acesso (indexada por addr[13:4])
    input  logic [INDEX_WIDTH-1:0]  index,      // Índice do bloco (10 bits)
    input  logic                    we,         // Habilitação de escrita
    input  cache_tag_type           tag_in,     // Dados de entrada: {valid, dirty, tag[17:0]}

    // Saída Combinacional
    output cache_tag_type           tag_out     // Dados lidos no índice atual
);

    // =========================================================================
    // Armazenamento Interno
    // =========================================================================
    //
    // Array de 1024 entradas do tipo cache_tag_type (struct packed).
    // Cada entrada ocupa 20 bits: 1 (valid) + 1 (dirty) + 18 (tag).
    //
    cache_tag_type tag_mem [0:NUM_BLOCKS-1];

    // =========================================================================
    // Leitura Assíncrona (Combinacional)
    // =========================================================================
    //
    // Justificativa: A FSM do controlador precisa avaliar o resultado da
    // comparação de tag (hit/miss) no mesmo ciclo de clock em que o
    // índice é apresentado. Uma leitura síncrona (registrada) introduziria
    // um ciclo de latência adicional, exigindo um estado extra na FSM
    // apenas para aguardar os dados do tag array.
    //
    assign tag_out = tag_mem[index];

    // =========================================================================
    // Escrita Síncrona + Reset Assíncrono
    // =========================================================================
    //
    // Reset: Todos os bits de validade são zerados assincronamente,
    //        garantindo que a cache inicie em estado "cold" independente
    //        do clock. Os bits de dirty e tag também são limpos para
    //        evitar valores indeterminados em simulação.
    //
    // Escrita: Ocorre estritamente na borda positiva do clock, condicionada
    //          ao sinal de habilitação 'we'. Apenas a posição apontada por
    //          'index' é atualizada — as demais 1023 entradas permanecem
    //          inalteradas.
    //
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < NUM_BLOCKS; i++) begin
                tag_mem[i] = {1'b0, 1'b0, {TAG_WIDTH{1'b0}}};
            end
        end else if (we) begin
            tag_mem[index] <= tag_in;
        end
    end

endmodule
