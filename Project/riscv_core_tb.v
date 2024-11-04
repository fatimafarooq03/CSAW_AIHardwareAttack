module tb_riscv_core;

  // Task to set memory address (used to assign values to wire mem_d_addr_o)
  task set_mem_d_addr;
    input [31:0] addr;
    begin
      force mem_d_addr_o = addr;
    end
  endtask

  // Task to set write enable signal (used to assign values to wire mem_d_wr_o)
  task set_mem_d_wr;
    input [3:0] wr;
    begin
      force mem_d_wr_o = wr;
    end
  endtask

  // Task to set read enable signal (used to assign values to wire mem_d_rd_o)
  task set_mem_d_rd;
    input rd;
    begin
      force mem_d_rd_o = rd;
    end
  endtask

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
  reg  [31:0]   mem_d_data_wr_reg;  // Separate register for write data

  // Outputs from DUT
  wire [31:0]   mem_d_addr_o;
  wire          mem_d_rd_o;
  wire [31:0]   mem_d_data_wr_o;  // Changed back to wire
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

  // Continuous assignment to drive the output wire with the register value
  assign mem_d_data_wr_o = mem_d_data_wr_reg;

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
    mem_d_data_rd_i = 32'h00000000;
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
    mem_d_data_wr_reg = 32'h00000000;

    // Display reset
    $display("Applying reset at time %t", $time);

    // Apply reset
    #10;
    rst_i = 0;

    $display("Reset deasserted at time %t, starting simulation...");

    // Repeat write and read operations multiple times
    repeat (10) begin
      // Write to cacheable memory range
      // mem_d_addr_o is a wire; updating the address through a task
      set_mem_d_addr(MEM_CACHE_ADDR_MIN + 4);  // Set a valid address within range

      // Write data to memory
      mem_d_data_wr_reg = 32'hA5A5A5A5;  // Write specific data

      // Enable write signal and set write strobe
      // mem_d_wr_o is a wire; updating write enable through a task
      set_mem_d_wr(4'b1111);  // Full word write

      // Trigger memory accept
      mem_d_accept_i = 1;

      // Add a delay to allow data to propagate
      #10;

      // Deassert accept and write signals
      mem_d_accept_i = 0;
      release mem_d_wr_o;

      // Wait a few cycles before reading back
      #50;

      // Read back from the cacheable memory range
      // mem_d_addr_o is a wire; updating the address through a task
      set_mem_d_addr(MEM_CACHE_ADDR_MIN + 4);  // Set the address to read back from

      // Enable read signal
      // mem_d_rd_o is a wire; updating read enable through a task
      set_mem_d_rd(1);

      // Trigger memory accept
      mem_d_accept_i = 1;

      // Add a delay to allow read data to propagate
      #10;

      // Monitor output for data read and condition check
      $display("Time: %t, Address: 0x%h, Read Data: 0x%h", 
               $time, mem_d_addr_o, mem_d_data_rd_i);

      // Check if data is corrupted
      if (mem_d_addr_o >= MEM_CACHE_ADDR_MIN && mem_d_addr_o <= MEM_CACHE_ADDR_MAX) begin
          if (mem_d_data_rd_i != 32'hA5A5A5A5) begin
              $display("Time: %t, Corrupted Data Read! Data: 0x%h, Expected: 0x%h", 
                       $time, mem_d_data_rd_i, 32'hA5A5A5A5);
          end else begin
              $display("Time: %t, Data Read Successfully. Data: 0x%h", 
                       $time, mem_d_data_rd_i);
          end
      end

      // Deassert accept and read signals
      mem_d_accept_i = 0;
      release mem_d_rd_o;

      // Write to non-cacheable memory range
      // mem_d_addr_o is a wire; updating the address through a task
      set_mem_d_addr(MEM_CACHE_ADDR_MIN-4);  // Set a non-cacheable address

      // Write data to memory
      mem_d_data_wr_reg = 32'h5A5A5A5A;  // Write different specific data

      // Enable write signal and set write strobe
      // mem_d_wr_o is a wire; updating write enable through a task
      set_mem_d_wr(4'b1111);  // Full word write

      // Trigger memory accept
      mem_d_accept_i = 1;

      // Add a delay to allow data to propagate
      #10;

      // Deassert accept and write signals
      mem_d_accept_i = 0;
      release mem_d_wr_o;

      // Wait a few cycles before reading back
      #50;

      // Read back from the non-cacheable memory range
      // mem_d_addr_o is a wire; updating the address through a task
      set_mem_d_addr(MEM_CACHE_ADDR_MIN + 4);  // Set the address to read back from

      // Enable read signal
      // mem_d_rd_o is a wire; updating read enable through a task
      set_mem_d_rd(1);

      // Trigger memory accept
      mem_d_accept_i = 1;

      // Add a delay to allow read data to propagate
      #10;

      // Monitor output for data read and condition check
      $display("Time: %t, Address: 0x%h, Read Data: 0x%h", 
               $time, mem_d_addr_o, mem_d_data_rd_i);

      // Check if data is corrupted
      if (mem_d_addr_o < MEM_CACHE_ADDR_MIN || mem_d_addr_o > MEM_CACHE_ADDR_MAX) begin
          if (mem_d_data_rd_i != 32'h5A5A5A5A) begin
              $display("Time: %t, Corrupted Data Read! Data: 0x%h, Expected: 0x%h", 
                       $time, mem_d_data_rd_i, 32'h5A5A5A5A);
          end else begin
              $display("Time: %t, Data Read Successfully. Data: 0x%h", 
                       $time, mem_d_data_rd_i);
          end
      end

      // Deassert accept and read signals
      mem_d_accept_i = 0;
      release mem_d_rd_o;

    end

    // End simulation
    $display("Ending simulation at time %t", $time);
    #100 $finish;
  end

endmodule