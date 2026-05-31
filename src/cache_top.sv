module cache_top (
    input  logic        clk,
    input  logic        rst,

    // CPU Interface (directly exposed)
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_wdata,
    input  logic        cpu_req,
    input  logic        cpu_write,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,

    // Main Memory Interface (directly exposed)
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic        mem_req,
    output logic        mem_write,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready
);
    // Internal: instantiate cache_controller
    cache_controller u_ctrl ( .* );
endmodule