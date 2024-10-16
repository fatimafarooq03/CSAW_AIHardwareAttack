module tb_riscv_core;

  // Parameters
  parameter MEM_CACHE_ADDR_MIN = 32'h80000000;
  parameter MEM_CACHE_ADDR_MAX = 32'h8fffffff;

  // Inputs to DUT
  reg           clk_i;
  reg           rst_i;
  reg  [31:0]   mem_d_data_rd_i;
  reg           mem_d_accept_i;
  reg           mem_d_ack_i;
  reg           mem_d_error_i;
  reg  [10:0]   mem_d_resp_tag_i;
  reg           mem_i_accept_i;
  reg           mem_i_valid_i;
  reg           mem_i_error_i;
  reg  [31:0]   mem_i_inst_i;
  reg           intr_i;
  reg  [31:0]   reset_vector_i;
  reg  [31:0]   cpu_id_i;

  // Outputs from DUT
  wire [31:0]   mem_d_addr_o;
  wire          mem_d_rd_o;
  wire [31:0]   mem_d_data_wr_o;
  wire [3:0]    mem_d_wr_o;
  wire          mem_d_cacheable_o;
  wire [10:0]   mem_d_req_tag_o;
  wire          mem_d_invalidate_o;
  wire          mem_d_writeback_o;
  wire          mem_d_flush_o;
  wire          mem_i_rd_o;
  wire          mem_i_flush_o;
  wire          mem_i_invalidate_o;
  wire [31:0]   mem_i_pc_o;

  // Instantiate the DUT (Design Under Test)
  riscv_core #(
    .MEM_CACHE_ADDR_MIN(MEM_CACHE_ADDR_MIN),
    .MEM_CACHE_ADDR_MAX(MEM_CACHE_ADDR_MAX)
  ) uut (
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
    .mem_d_addr_o(mem_d_addr_o),  // Driven by DUT
    .mem_d_data_wr_o(mem_d_data_wr_o),
    .mem_d_rd_o(mem_d_rd_o),      // Driven by DUT
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
  always #5 clk_i = ~clk_i;

  // Test procedure
  initial begin
    // Initialize inputs
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
    reset_vector_i = 32'h00000000;
    cpu_id_i = 32'h00000001;

    // Display reset
    $display("Applying reset at time %t", $time);

    // Apply reset
    #10;
    rst_i = 0;

    $display("Reset deasserted at time %t, starting simulation...", $time);

    // Force the address to be within cacheable range early
    force mem_d_addr_o = MEM_CACHE_ADDR_MIN;  // Start with the minimum address

    // Simulate memory read and write accesses with valid address range
    repeat(10) begin  // Increase the number of iterations to trigger condition faster
      // Wait for 10 time units
      #10;

      // Generate random read data
      mem_d_data_rd_i = $random;

      // Signal memory accept
      mem_d_accept_i = 1;

      // Display the current state of memory addresses and reads
      $display("Time: %t, Memory Address: 0x%h, Read Data: 0x%h", $time, mem_d_addr_o, mem_d_data_rd_i);

      // Check for corruption in the written data
      if (mem_d_rd_o == 1 && mem_d_addr_o >= MEM_CACHE_ADDR_MIN && mem_d_addr_o <= MEM_CACHE_ADDR_MAX) begin
        if (mem_d_data_wr_o != (mem_d_data_rd_i ^ 32'hDEADBEEF)) begin
          $display("Time: %t, Vulnerability Compromised! Data corruption detected. Written: 0x%h, Expected: 0x%h", 
                   $time, mem_d_data_wr_o, (mem_d_data_rd_i ^ 32'hDEADBEEF));
        end else begin
          $display("Time: %t, No data corruption detected. Data Written: 0x%h", 
                   $time, mem_d_data_wr_o);
        end
      end

      mem_d_accept_i = 0; // Clear accept signal
    end

    // Release the forced signal to allow normal operation
    release mem_d_addr_o;

    // End simulation
    $display("Ending simulation at time %t", $time);
    #100 $finish;
  end

endmodule
