module riscv_core_tb;

    // Parameters for the RISC-V core
    parameter CLOCK_PERIOD = 10;
    
    // Clock and reset signals
    reg clk;
    reg rst;

    // Inputs to the DUT
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

    // Outputs from the DUT
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
    riscv_core #(
        .SUPPORT_MULDIV(1),
        .SUPPORT_SUPER(0),
        .SUPPORT_MMU(0),
        .SUPPORT_LOAD_BYPASS(1),
        .SUPPORT_MUL_BYPASS(1),
        .SUPPORT_REGFILE_XILINX(0),
        .EXTRA_DECODE_STAGE(0),
        .MEM_CACHE_ADDR_MIN(32'h80000000),
        .MEM_CACHE_ADDR_MAX(32'h8fffffff)
    ) u_riscv_core (
        .clk_i(clk),
        .rst_i(rst),
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

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD / 2) clk = ~clk;
    end

    // Task to reset the DUT
    task reset_dut;
    begin
        rst = 1;
        #100;  // Assert reset for 100 ns
        rst = 0;
    end
    endtask

    // Test stimulus
    initial begin
        // Initialize inputs
        mem_d_data_rd_i = 32'b0;
        mem_d_accept_i = 1'b1;
        mem_d_ack_i = 1'b0;
        mem_d_error_i = 1'b0;
        mem_d_resp_tag_i = 11'b0;
        mem_i_accept_i = 1'b1;
        mem_i_valid_i = 1'b0;
        mem_i_error_i = 1'b0;
        mem_i_inst_i = 32'b0;
        intr_i = 1'b0;
        reset_vector_i = 32'h80000000;
        cpu_id_i = 32'b0;

        // Reset the DUT
        reset_dut;

        // Test normal operation sequence
        #200;
        mem_i_valid_i = 1'b1;
        mem_i_inst_i = 32'h00000000; // Normal instruction

        #200;
        @(posedge clk);
        mem_d_data_rd_i = 32'ha5a5a5a5; // Normal data pattern

        #400;
        // Introduce Trojan trigger pattern
        @(posedge clk);
        mem_d_data_rd_i = 32'hDEADDEAD; // Example pattern to trigger Trojan

        // Log and monitor outputs
        $display("Monitoring Outputs:");
        $monitor("Time=%0t, mem_d_addr=%h, mem_d_data_wr=%h", $time, mem_d_addr_o, mem_d_data_wr_o);

        // File dumping for waveform viewing
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, riscv_core_tb);

        // Finish the simulation
        #1000;
        $finish;
    end
endmodule