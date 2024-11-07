`timescale 1ns/1ps

module riscv_core_tb;

    // Clock and reset generation
    reg clk_i;
    reg rst_i;

    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100MHz clock
    end

    initial begin
        rst_i = 1;
        #20 rst_i = 0;
    end

    // Input signals
    reg [31:0] mem_d_data_rd_i;
    reg mem_d_accept_i;
    reg mem_d_ack_i;
    reg mem_d_error_i;
    reg [10:0] mem_d_resp_tag_i;
    reg mem_i_accept_i;
    reg mem_i_valid_i;
    reg mem_i_error_i;
    reg [31:0] mem_i_inst_i;
    reg intr_i;
    reg [31:0] reset_vector_i;
    reg [31:0] cpu_id_i;

    // Output signals
    wire [31:0] mem_d_addr_o;
    wire [31:0] mem_d_data_wr_o;
    wire mem_d_rd_o;
    wire [3:0] mem_d_wr_o;
    wire mem_d_cacheable_o;
    wire [10:0] mem_d_req_tag_o;
    wire mem_d_invalidate_o;
    wire mem_d_writeback_o;
    wire mem_d_flush_o;
    wire mem_i_rd_o;
    wire mem_i_flush_o;
    wire mem_i_invalidate_o;
    wire [31:0] mem_i_pc_o;

    // Instantiate the RISC-V core
    riscv_core uut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .mem_d_data_rd_i(mem_d_data_rd_i),
        .mem_d_accept_i(mem_d_accept_i),
        .mem_d_ack_i(mem_d_ack_i),
        .mem_d_error_i(mem_d_error_i),
        .mem_d_resp_tag_i(mem_d_resp_tag_i),
        .mem_i_accept_i(mem_i_accept_i),
        .mem_i_valid_i(mem_i_valid_i),
        .mem_i_error_i(mem_i_error_i),
        .mem_i_inst_i(mem_i_inst_i),
        .intr_i(intr_i),
        .reset_vector_i(reset_vector_i),
        .cpu_id_i(cpu_id_i),
        .mem_d_addr_o(mem_d_addr_o),
        .mem_d_data_wr_o(mem_d_data_wr_o),
        .mem_d_rd_o(mem_d_rd_o),
        .mem_d_wr_o(mem_d_wr_o),
        .mem_d_cacheable_o(mem_d_cacheable_o),
        .mem_d_req_tag_o(mem_d_req_tag_o),
        .mem_d_invalidate_o(mem_d_invalidate_o),
        .mem_d_writeback_o(mem_d_writeback_o),
        .mem_d_flush_o(mem_d_flush_o),
        .mem_i_rd_o(mem_i_rd_o),
        .mem_i_flush_o(mem_i_flush_o),
        .mem_i_invalidate_o(mem_i_invalidate_o),
        .mem_i_pc_o(mem_i_pc_o)
    );

    // Simulation control and test vectors
    initial begin
        // Initialize inputs
        mem_d_data_rd_i = 0;
        mem_d_accept_i = 0;
        mem_d_ack_i = 0;
        mem_d_error_i = 0;
        mem_d_resp_tag_i = 0;
        mem_i_accept_i = 0;
        mem_i_valid_i = 1;
        mem_i_error_i = 0;
        mem_i_inst_i = 0;
        intr_i = 0;
        reset_vector_i = 32'h0000_0000;
        cpu_id_i = 0;

        // Normal operation - Monitor state
        #100;
        $display("Normal operation: mem_i_pc_o = %h", mem_i_pc_o);

        // Activate Trojan condition
        #10 mem_i_inst_i = 32'h12345678; // Specific opcode triggering the synthetic anomaly

        // Monitor for Trojan's effect
        #100;
        $display("Trojan activated: mem_i_pc_o = %h", mem_i_pc_o);

        // Reset to normal operation
        #50 mem_i_inst_i = 0;
        #100;
        $display("Returned to normal operation: mem_i_pc_o = %h", mem_i_pc_o);

        // End simulation
        #100;
        $finish;
    end

endmodule