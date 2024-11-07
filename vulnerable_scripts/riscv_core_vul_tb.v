`timescale 1ns/1ps

module riscv_core_tb;

    // Internal signals
    reg             clk;
    reg             rst;
    reg     [31:0]  mem_d_data_rd;
    reg             mem_d_accept;
    reg             mem_d_ack;
    reg             mem_d_error;
    reg     [10:0]  mem_d_resp_tag;
    reg             mem_i_accept;
    reg             mem_i_valid;
    reg             mem_i_error;
    reg     [31:0]  mem_i_inst;
    reg             intr;
    reg     [31:0]  reset_vector;
    reg     [31:0]  cpu_id;

    wire    [31:0]  mem_d_addr;
    wire    [31:0]  mem_d_data_wr;
    wire            mem_d_rd;
    wire    [3:0]   mem_d_wr;
    wire            mem_d_cacheable;
    wire    [10:0]  mem_d_req_tag;
    wire            mem_d_invalidate;
    wire            mem_d_writeback;
    wire            mem_d_flush;
    wire            mem_i_rd;
    wire            mem_i_flush;
    wire            mem_i_invalidate;
    wire    [31:0]  mem_i_pc;

    // Instantiate riscv_core
    riscv_core uut (
        .clk_i(clk),
        .rst_i(rst),
        .mem_d_data_rd_i(mem_d_data_rd),
        .mem_d_accept_i(mem_d_accept),
        .mem_d_ack_i(mem_d_ack),
        .mem_d_error_i(mem_d_error),
        .mem_d_resp_tag_i(mem_d_resp_tag),
        .mem_i_accept_i(mem_i_accept),
        .mem_i_valid_i(mem_i_valid),
        .mem_i_error_i(mem_i_error),
        .mem_i_inst_i(mem_i_inst),
        .intr_i(intr),
        .reset_vector_i(reset_vector),
        .cpu_id_i(cpu_id),
        .mem_d_addr_o(mem_d_addr),
        .mem_d_data_wr_o(mem_d_data_wr),
        .mem_d_rd_o(mem_d_rd),
        .mem_d_wr_o(mem_d_wr),
        .mem_d_cacheable_o(mem_d_cacheable),
        .mem_d_req_tag_o(mem_d_req_tag),
        .mem_d_invalidate_o(mem_d_invalidate),
        .mem_d_writeback_o(mem_d_writeback),
        .mem_d_flush_o(mem_d_flush),
        .mem_i_rd_o(mem_i_rd),
        .mem_i_flush_o(mem_i_flush),
        .mem_i_invalidate_o(mem_i_invalidate),
        .mem_i_pc_o(mem_i_pc)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench logic
    initial begin
        // Initialize signals
        rst = 1;
        mem_d_data_rd = 32'b0;
        mem_d_accept = 0;
        mem_d_ack = 0;
        mem_d_error = 0;
        mem_d_resp_tag = 11'b0;
        mem_i_accept = 0;
        mem_i_valid = 0;
        mem_i_error = 0;
        mem_i_inst = 32'b0;
        intr = 0;
        reset_vector = 32'h80000000;
        cpu_id = 32'h00000001;

        // Reset sequence
        #10
        rst = 0;

        // Apply test vectors and conditions to activate the Trojan
        #10
        mem_i_valid = 1;
        mem_i_inst = 32'hDEADBEEF;  // Example opcode to trigger the trojan
        
        #10
        mem_i_valid = 0;
        mem_i_inst = 32'hAA55AA55;  // Non-trigger condition

        // Monitor key signals
        #100
        $display("Memory Read Address: %h", mem_d_addr);
        $display("Memory Write Address: %h", mem_d_data_wr);
        $display("Program Counter: %h", mem_i_pc);

        // End simulation
        #100
        $finish;
    end

endmodule