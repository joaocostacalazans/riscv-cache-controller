/**
 * @file cache_def.sv
 * @brief Definições e tipos para o controlador de cache RISC-V
 *
 * Package contendo as definições de tipos de dados, parâmetros arquiteturais
 * e estruturas de interface utilizadas por todos os módulos do sistema de cache.
 *
 * Referência: Seção 5.12 — "Computer Organization and Design: The Hardware/
 * Software Interface, RISC-V Edition" (Patterson & Hennessy).
 *
 * Geometria da Cache:
 *   - Direct-Mapped, Write-Back
 *   - 1024 blocos, linha de 128 bits (4 palavras × 32 bits)
 *   - Endereço de 32 bits: [31:14] tag | [13:4] index | [3:2] offset | [1:0] byte
 */

package cache_def;

    // =========================================================================
    // Parâmetros Arquiteturais
    // =========================================================================

    parameter int ADDR_WIDTH        = 32;    // Largura do endereço RISC-V
    parameter int WORD_WIDTH        = 32;    // Largura de palavra
    parameter int WORDS_PER_LINE    = 4;     // Palavras por linha de cache
    parameter int NUM_BLOCKS        = 1024;  // Número de blocos (linhas)

    // Larguras dos campos de endereço
    //
    //  31              14 | 13          4 | 3    2 | 1  0
    //  ──────────────────┼──────────────┼────────┼──────
    //      TAG (18)      |  INDEX (10)  | OFFSET | BYTE
    //                    |              |  (2)   | (2)
    //
    parameter int TAG_WIDTH         = 18;    // addr[31:14]
    parameter int INDEX_WIDTH       = 10;    // addr[13:4]
    parameter int OFFSET_WIDTH      = 2;     // addr[3:2] — seleção de palavra
    parameter int BYTE_OFFSET_WIDTH = 2;     // addr[1:0] — byte dentro da palavra

    // Tamanho da linha de cache em bits
    parameter int CACHE_LINE_WIDTH  = WORDS_PER_LINE * WORD_WIDTH; // 128 bits

    // =========================================================================
    // Tipos de Dados Internos da Cache
    // =========================================================================

    /**
     * cache_tag_type — Entrada no Tag Array
     *
     * Armazena os metadados de controle de cada bloco de cache:
     *   valid : Indica se a linha contém dados válidos.
     *   dirty : Indica se a linha foi modificada (necessita write-back).
     *   tag   : Porção mais significativa do endereço para comparação.
     *
     * Empacotado (packed) para permitir atribuição atômica e reset estruturado.
     */
    typedef struct packed {
        logic                   valid;  // Bit de validade
        logic                   dirty;  // Bit de sujeira (write-back)
        logic [TAG_WIDTH-1:0]   tag;    // Tag do bloco (18 bits)
    } cache_tag_type;

    /**
     * cache_data_type — Entrada no Data Array
     *
     * Representa uma linha completa de cache (128 bits = 4 palavras de 32 bits).
     * A seleção de palavra individual (via campo offset do endereço) é
     * responsabilidade do controlador FSM, não do módulo de armazenamento.
     */
    typedef logic [CACHE_LINE_WIDTH-1:0] cache_data_type;

    // =========================================================================
    // Estruturas de Interface: CPU ↔ Cache
    // =========================================================================

    /**
     * cpu_req_type — Requisição da CPU para a Cache
     *
     * Agrega todos os sinais que o processador envia ao controlador de cache
     * para iniciar uma operação de leitura ou escrita.
     */
    typedef struct packed {
        logic [ADDR_WIDTH-1:0]  addr;   // Endereço de acesso (32 bits)
        logic [WORD_WIDTH-1:0]  data;   // Dado a ser escrito (32 bits)
        logic                   rw;     // 0 = Leitura, 1 = Escrita
        logic                   valid;  // Requisição válida (handshake)
    } cpu_req_type;

    /**
     * cpu_result_type — Resultado da Cache para a CPU
     *
     * Agrega os sinais de resposta enviados pela cache ao processador
     * após a conclusão de uma operação.
     */
    typedef struct packed {
        logic [WORD_WIDTH-1:0]  data;   // Dado lido (32 bits)
        logic                   ready;  // Resultado pronto (handshake)
    } cpu_result_type;

    // =========================================================================
    // Estruturas de Interface: Cache ↔ Memória Principal
    // =========================================================================

    /**
     * mem_req_type — Requisição da Cache para a Memória Principal
     *
     * Utiliza a largura da linha completa (128 bits) para transferências
     * de write-back (evicção de linha suja) e allocate (preenchimento).
     */
    typedef struct packed {
        logic [ADDR_WIDTH-1:0]       addr;   // Endereço alinhado ao bloco
        logic [CACHE_LINE_WIDTH-1:0] data;   // Linha completa para write-back (128 bits)
        logic                        rw;     // 0 = Leitura (allocate), 1 = Escrita (write-back)
        logic                        valid;  // Requisição válida (handshake)
    } mem_req_type;

    /**
     * mem_data_type — Resposta da Memória Principal para a Cache
     *
     * Retorna uma linha completa de dados durante a operação de allocate
     * (preenchimento de bloco após cache miss).
     */
    typedef struct packed {
        logic [CACHE_LINE_WIDTH-1:0] data;   // Linha completa recebida (128 bits)
        logic                        ready;  // Dado pronto (handshake)
    } mem_data_type;

endpackage
