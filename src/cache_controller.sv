/**
 * @file cache_controller.sv
 * @brief Controlador de Cache RISC-V
 *
 * Módulo principal responsável por gerenciar as operações de leitura e escrita,
 * controlando a máquina de estados (FSM) de acerto (hit) e erro (miss), bem
 * como a política de escrita (e.g., Write-Back / Write-Through).
 */

module cache_controller (
    input  logic        clk,
    input  logic        rst,

    // Interface com o Processador (CPU)
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_wdata,
    input  logic        cpu_req,
    input  logic        cpu_write,      // 0: Leitura, 1: Escrita
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,      // Sinaliza fim da operação para a CPU

    // Interface com a Memória Principal
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic        mem_req,
    output logic        mem_write,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready
);

    // TODO: Instanciar cache_tag e cache_data
    // TODO: Implementar FSM do controlador de cache (Compare Tag, Allocate, Write-Back)

endmodule
