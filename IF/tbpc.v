`include "fetch.v"
`timescale 1ns / 1ns

module tbpc();
	parameter XLEN = 32;
	parameter XLENM1 = XLEN - 1;
	parameter CLK_PERIOD = 10;
	
	reg clk, en, rst;
	reg jmp;
	reg [XLENM1:0] jmp_addr;
	
	wire [XLENM1:0] instr;
	wire [XLENM1:0] pc;
	wire [XLENM1:0] pcp4;
	
	fetch #(.XLEN(XLEN), .IMEM_PATH("IF/imemb_dbg.mem"), .IS_BIN(0)) f0 (
		.clk(clk),
		.en(en),
		.rst(rst),
		.jmp(jmp),
		.jmp_addr(jmp_addr),
		.instr(instr),
		.pc(pc),
		.pcp4(pcp4)
	);
	
	integer test_number = 0;
	task test_instr_val;
		input [31:0] val;
		begin
			#1;
			if (val != instr) begin
				$display("Test %0d failed: instr = 0x%x, expected 0x%x", test_number, instr, val);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask

	task test_pc_val;
		input [31:0] val;
		begin
			#1;
			if (val != pc) begin
				$display("Test %0d failed: pc = 0x%x, expected 0x%x", test_number, pc, val);
				$finish;
			end
			if (val + 4 != pcp4) begin
				$display("Test %0d failed: pc + 4 = 0x%x, expected 0x%x", test_number, pcp4, val + 4);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask
	
	always #(CLK_PERIOD / 2.0) begin
		clk <= ~clk;
	end

	initial begin
		$dumpfile("dump.lxt");
		$dumpvars(0, tbpc);
		$display("\n\nstarting fetch simulation...");
		
		clk <= 1'b0;
		en <= 1'b0;
		rst <= 1'b0;
		jmp <= 1'b0;
		jmp_addr <= 32'b0;
		@(posedge clk);
		rst <= 1'b1;
		@(posedge clk);
		rst <= 1'b0;
		en <= 1'b1;
		test_instr_val(32'h00000100);
		test_pc_val(32'd0);
		
		@(posedge clk);
		test_instr_val(32'h00000100);
		test_pc_val(32'd4);

		@(posedge clk);
		test_instr_val(32'h00000101);
		test_pc_val(32'd8);

		jmp <= 1'b1;
		jmp_addr <= 32'd28;
		@(posedge clk);
		test_instr_val(32'h00000107);
		test_pc_val(32'd28);
		
		jmp <= 1'b0;
		@(posedge clk);
		test_instr_val(32'h00000108);
		test_pc_val(32'd32);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		$display("fetch simulation finished %0d tests.\n\n", test_number);
		$finish;
	end
endmodule
