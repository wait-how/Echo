`include "regfile.v"
`timescale 1ns / 1ns

module tbregfile();
	parameter XLEN = 32;
	parameter XLENM1 = XLEN - 1;
	parameter CLK_PERIOD = 10;
	reg clk, read_en, rst;

	reg [4:0] rs1;
	reg [4:0] rs2;

	wire [XLENM1:0] rs1_val;
	wire [XLENM1:0] rs2_val;

	reg write_en;
	reg [4:0] rd;
	reg [XLENM1:0] rd_val;

	reg [4:0] test_addr;
	wire [XLENM1:0] test_data;
	
	regfile r0 (
		.clk(clk),
		.read_en(read_en),
		.rst(rst),
		.rs1(rs1),
		.rs2(rs2),
		.rs1_val(rs1_val),
		.rs2_val(rs2_val),
		.write_en(write_en),
		.rd(rd),
		.rd_val(rd_val)
	);
	
	always #(CLK_PERIOD / 2.0) begin
		clk <= ~clk;
	end
	
	integer test_number = 0;
	task test_regs_eq;
		input [XLENM1:0] test_rs1_val;
		input [XLENM1:0] test_rs2_val;
		begin
			#1;
			
			if (rs1_val != test_rs1_val) begin
				$display("Test %0d failed: rs1_val = %0h, expected %0h.", test_number, rs1_val, test_rs1_val);
				$finish;
			end
			test_number = test_number + 1;
			
			if (rs2_val != test_rs2_val) begin
				$display("Test %0d failed: rs2_val = %0h, expected %0h.", test_number, rs2_val, test_rs2_val);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask

	initial begin
		$dumpfile("dump.lxt");
		$dumpvars(0, tbregfile);
		$display("\n\nstarting regfile simulation...");
		clk <= 1'b0;
		read_en <= 1'b0;
		
		rst <= 1'b0;
		rs1 <= 5'b0;
		rs2 <= 5'b0;
		
		write_en <= 1'b0;
		rd <= 5'b0;
		rd_val <= 32'b0;
		@(posedge clk);
		rst <= 1'b1;
		@(posedge clk);
		rst <= 1'b0;
		write_en <= 1'b1;
		rd <= 5'd1;
		rd_val <= 32'hFFFF_FFFF;
		@(posedge clk);
		rd_val <= 32'hAAAA_AAAA;
		rd <= 5'd2;
		@(posedge clk);
		rd_val <= 32'h5555_5555;
		rd <= 5'h3;
		@(posedge clk);
		rd <= 5'h0;
		@(posedge clk);
		rd <= 5'd31;
		rd_val <= 32'd2;
		@(posedge clk);
		write_en <= 1'b0;
		read_en <= 1'b1;
		rs1 <= 5'h0;
		rs2 <= 5'h1;
		@(posedge clk);
		test_regs_eq(32'b0, 32'hFFFF_FFFF);

		rs1 <= 5'd2;
		rs2 <= 5'd3;
		@(posedge clk);
		test_regs_eq(32'hAAAA_AAAA, 32'h5555_5555);

		write_en <= 1'b1;
		read_en <= 1'b1;
		rs1 <= 5'd31;
		rs2 <= 5'd30;
		rd <= 5'd30;
		rd_val <= 32'd3;
		@(posedge clk);
		@(negedge clk);
		test_regs_eq(32'd2, 32'd3);

		@(posedge clk);
		@(posedge clk);
		$display("regfile simulation finished %0d tests.\n\n", test_number);
		$finish;
	end
endmodule
