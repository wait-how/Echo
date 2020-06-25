`timescale 1ns / 1ns

module regfile (
	input clk,
	input read_en,
	input rst,

	input [4:0] rs1,
	input [4:0] rs2,
	output reg [XLEN - 1:0] rs1_val,
	output reg [XLEN - 1:0] rs2_val,
	
	input write_en,
	input [4:0] rd,
	input [XLEN - 1:0] rd_val
	);
	parameter XLEN = 32;
	
	reg [XLEN - 1:0] reg_array[31:0];
	
	task set_zero;
		integer i;
		for (i = 0; i < 32; i++) begin
			reg_array[i] <= 32'h0;
		end
	endtask

	always @(negedge clk) begin // reads happen half a clock after writes to avoid hazards
		if (read_en) begin
			rs1_val <= reg_array[rs1];
			rs2_val <= reg_array[rs2];
		end
	end

	always @(posedge clk) begin
		if (write_en && rd != 5'b0) begin
			reg_array[rd] <= rd_val;
		end
	end

	always @(posedge rst) begin
		set_zero;
	end
	
endmodule
