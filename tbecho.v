`include "echo.v"
`timescale 1ns / 1ns

module tbecho();
	parameter XLEN = 32;
	parameter XLENM1 = XLEN - 1;
	parameter CLK_PERIOD = 10.0;
	parameter NUM_INSTRS = 83; // number of instructions in binary
	parameter NUM_CLOCKS = NUM_INSTRS * 5;
	
	parameter PATH = "test.bin";

	reg clk, run, rst;
	wire [4:0] addr;
	wire [XLENM1:0] data;
	wire en;
	
	always #(CLK_PERIOD / 2.0) begin
		clk <= ~clk;
	end

	echo #(.XLEN(XLEN), .IMEM_PATH(PATH), .SIZE(NUM_INSTRS * 4)) e (.debug_write_enabled(en), .debug_write_addr(addr), .debug_write_data(data), .clk(clk), .run(run), .rst(rst));

	integer i;
	integer expect_addr = 0;
	integer failed = 0;
	
	reg [XLENM1:0] expected_output [NUM_INSTRS * 2 - 1:0];

	initial begin
		$dumpfile("dump.lxt");
		$dumpvars(0, tbecho);
		$display("\n\nstarting echo simulation...");
		
		$readmemh("test_outputs.mem", expected_output);

		clk <= 1'b0;
		run <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		rst <= 1'b0;
		run <= 1'b1;
		@(posedge clk); // start instructions through the pipeline, wait until they hit WB
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		for (i = 1; i <= NUM_INSTRS; i = i + 1) begin // from this point on, 1 ipc
			$write("instruction %0d: ", i);
			if (addr !== expected_output[expect_addr+1][4:0] && en) begin
				$display("FAIL: expected reg x%0d, got x%0d.", expected_output[expect_addr+1][4:0], addr);
				failed = 1;
			end
			if (data !== expected_output[expect_addr] && en) begin
				$display("FAIL: expected data %0h, got %0h.", expected_output[expect_addr], data);
				failed = 1;
			end
			if (failed) begin
				$finish;
			end
			$display("PASS: wrote %0h to x%0d.", data, addr);
			expect_addr = expect_addr + 2;
			@(posedge clk);
		end
		$display("echo simulation completed.\n");
		$finish;
	end
endmodule
