`include "memory.v"
`timescale 1ns / 1ns

module tbdmem();
	parameter XLEN = 32;
	parameter XLENM1 = XLEN - 1;
	parameter CLK_PERIOD = 10;

	reg clk, en, rst;
	
	reg [XLENM1:0] alu_out;
	reg [XLENM1:0] write_data;
	
	reg write;
	
	wire [XLENM1:0] read_data;
	
	reg is_unsigned;
	reg [1:0] write_size;

	always #(CLK_PERIOD / 2.0) begin
		clk <= ~clk;
	end
	
	reg en_wb;
	wire en_wb_out;
	reg [4:0] reg_write;
	wire [4:0] reg_write_out;

	memory s0 (
		.clk(clk),
		.en(en),
		.rst(rst),

		.addr(alu_out),
		.write_data(write_data),
		
		.write(write),

		.read_data(read_data),
		.load_unsigned(is_unsigned),
		.size(write_size),
		
		.en_wb(en_wb),
		.en_wb_out(en_wb_out),
		.reg_write(reg_write),
		.reg_write_out(reg_write_out)
	);

	integer test_number = 0;
	task test_mem_eq;
		input [31:0] val;
		begin
			#1;
			if (read_data != val) begin
				$display("Test %0d failed: read_data = 0x%x, expected 0x%x.", test_number, read_data, val);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask

	initial begin
		$dumpfile("dump.lxt");
		$dumpvars(0, tbdmem);
		$display("\n\nstarting memory simulation...");
		clk <= 0;
		en <= 0;
		rst <= 0;
		alu_out <= 0;
		write <= 0;
		write_data <= 0;
		is_unsigned <= 1;
		write_size <= 0;
		en_wb <= 0;
		reg_write <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		en <= 1;
		
		alu_out <= 32'h0;
		write_data <= 32'hFFFF_FFFF;
		write <= 1;
		write_size <= `SIZE_32;
		@(posedge clk);
		write_data <= 32'h0000_AAAA;
		write_size <= `SIZE_16;
		@(posedge clk);
		write_data <= 32'h0000_0055;
		write_size <= `SIZE_8;
		@(posedge clk);
		alu_out <= 8;
		write_data <= 32'h8000;
		write_size <= `SIZE_32;
		@(posedge clk);
		alu_out <= 12;
		write_data <= 32'h80;
		@(posedge clk);
		write <= 0;
		write_data <= {32{1'bZ}};
		alu_out <= 0;
		@(posedge clk);
		test_mem_eq(32'hFFFF_AA55);
		
		alu_out <= 8;
		write_size <= `SIZE_16;
		@(posedge clk);
		test_mem_eq(32'h0000_8000);
		
		is_unsigned <= 0;
		@(posedge clk);
		test_mem_eq(32'hFFFF_8000);

		is_unsigned <= 1;
		alu_out <= 12;
		write_size <= `SIZE_8;
		@(posedge clk);
		test_mem_eq(32'h0000_0080);
		
		is_unsigned <= 0;
		@(posedge clk);
		test_mem_eq(32'hFFFF_FF80);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("memory simulation finished %0d tests.\n\n", test_number);
		$finish;
	end
endmodule
