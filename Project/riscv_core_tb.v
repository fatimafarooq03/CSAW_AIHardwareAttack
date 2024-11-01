module riscv_core_tb;

// Clock and reset signals
reg clk;
reg rst;
wire [31:0] mem_d_data_rd;
wire mem_d_accept;
wire mem_d_ack;
wire mem_d_error;
wire [10:0] mem_d_resp_tag;
wire mem_i_accept;
wire mem_i_valid;
wire mem_i_error;
wire [31:0] mem_i_inst;
reg intr;
reg [31:0] reset_vector;
reg [31:0] cpu_id;
wire [31:0] mem_d_addr;
wire [31:0] mem_d_data_wr;
wire mem_d_rd;
wire [3:0] mem_d_wr;
wire mem_d_cacheable;
wire [10:0] mem_d_req_tag;
wire mem_d_invalidate;
wire mem_d_writeback;
wire mem_d_flush;
wire mem_i_rd;
wire mem_i_flush;
wire mem_i_invalidate;
wire [31:0] mem_i_pc;

// Instantiate the riscv_core
riscv_core uut (
    // Inputs
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
    
    // Outputs
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
always begin
    #5 clk = ~clk; // 100MHz clock
end

// Initialize signals
initial begin
    $dumpfile("riscv_core_tb.vcd");
    $dumpvars(0, riscv_core_tb);
    clk = 0;
    rst = 0;
    intr = 0;
    reset_vector = 32'h80000000;
    cpu_id = 32'h0;

    // Assert reset
    rst = 1;
    #20;
    rst = 0;

    // Wait some time for memory initialization and others
    #100;

    // Apply stimulus to activate the Trojan
    if (trigger_trojan()) begin
        $display("Trojan activated at %0t ns", $time);
    end else begin
        $display("Trojan activation test completed without triggering");
    end

    // Complete the test after a specified time
    #2000;
    $finish;
end

// Function to trigger Trojan
function trigger_trojan;
    begin
        // Specific conditions to be met
        // These should align with the conditions that activate the Trojan part of the circuit
        // Example: Assign specific input values that the Trojan checks for before executing its payload

        // Set signals to trigger the Trojan.
        // This should match the Trojan triggering condition defined in the original Verilog module
        // Uncomment and modify based on actual Trojan logic:
        // signal_1 = specific_value_1;
        // signal_2 = specific_value_2;
        
        // Return 1 if triggered, 0 otherwise
        trigger_trojan = (/* check condition matching the Trojan trigger logic */);
    end
endfunction

// Monitor and log potential Trojan activations
always @(posedge clk) begin
    if (/* Trojan trigger condition */) begin
        $display("Trojan activated at %0t ns", $time);
        // Additional logging outputs for detailed analysis
        // E.g., dump register/memory states, or Trojan-specific signals

        // Uncomment and insert signal logging here
        // $display("Signal State: %0h", signal);
    end
end

endmodule