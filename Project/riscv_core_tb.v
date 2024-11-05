`timescale 1ns / 1ps

module riscv_core_tb;

// Clock and Reset Signals
reg clk_i;
reg rst_i;

// Memory Signals
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

// Parameters
parameter MEM_CACHE_ADDR_MIN = 32'h80000000;
parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff;

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

// Clock Generation
always #5 clk_i = ~clk_i;

// Testbench Logic
initial begin
    // Initialize signals
    clk_i = 0;
    rst_i = 1;
    mem_d_data_rd_i = 0;
    mem_d_accept_i = 0;
    mem_d_ack_i = 0;
    mem_d_error_i = 0;
    mem_d_resp_tag_i = 0;
    mem_i_accept_i = 0;
    mem_i_valid_i = 0;
    mem_i_error_i = 0;
    mem_i_inst_i = 0;
    intr_i = 0;
    reset_vector_i = 32'h80000000;
    cpu_id_i = 0;

    // Apply reset
    #20 rst_i = 0;

    // Write to a specific memory address within cacheable range
    @(posedge clk_i);
    force uut.mem_d_addr_o = 32'h80000010; // Specify write address within range
    mem_d_accept_i = 1;
    @(posedge clk_i);
    mem_d_accept_i = 0;
    @(posedge clk_i);
    mem_d_data_rd_i = 32'hDEADBEEF; // Write data
    mem_d_ack_i = 1;
    $display("[WRITE IN RANGE] Address: %h, Data Written: %h", mem_d_addr_o, mem_d_data_rd_i);
    @(posedge clk_i);
    mem_d_ack_i = 0;
    release uut.mem_d_addr_o;
    release uut.mem_d_rd_o;

// Read from a specific memory address within cacheable range
@(posedge clk_i);
force uut.mem_d_addr_o = 32'h80000010; // Specify read address within range
force uut.mem_d_rd_o = 1;
@(posedge clk_i);

// Directly read data from the memory address without checking for corruption
mem_d_data_rd_i = uut.mem_d_data_wr_o; // Capture data directly from memory
$display("[READ IN RANGE] Address: %h, Data Read: %h", mem_d_addr_o, mem_d_data_rd_i);

mem_d_ack_i = 1;
@(posedge clk_i);
mem_d_ack_i = 0;
release uut.mem_d_addr_o;
release uut.mem_d_rd_o;


    // Write to a specific memory address out of cacheable range
    @(posedge clk_i);
    force uut.mem_d_addr_o = 32'h90000010; // Specify write address out of range
    mem_d_accept_i = 1;
    @(posedge clk_i);
    mem_d_accept_i = 0;
    @(posedge clk_i);
    mem_d_data_rd_i = 32'hBADDCAFE; // Write data
    mem_d_ack_i = 1;
    $display("[WRITE OUT OF RANGE] Address: %h, Data Written: %h", mem_d_addr_o, mem_d_data_rd_i);
    @(posedge clk_i);
    mem_d_ack_i = 0;
    release uut.mem_d_addr_o;
    release uut.mem_d_rd_o;

    
// Read from a specific memory address out of cacheable range
@(posedge clk_i);
force uut.mem_d_addr_o = 32'h90000010; // Specify read address out of range
force uut.mem_d_rd_o = 1;
@(posedge clk_i);

// Directly assign and display the read data
mem_d_data_rd_i = 32'h12345678; // Simulate read data
$display("[READ OUT OF RANGE] Address: %h, Data Read: %h", mem_d_addr_o, mem_d_data_rd_i);

mem_d_ack_i = 1;
@(posedge clk_i);
mem_d_ack_i = 0;
release uut.mem_d_addr_o;
release uut.mem_d_rd_o;


    // Finish simulation
    #100 $finish;
end

endmodule
 