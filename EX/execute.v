`include "alu.v"
`timescale 1ns / 1ns

// does arithmetic on input values, outputs result.
module execute(
	input clk,
	input en,
	input rst,
	
	input [3:0] op,
	input use_imm,
	input op_choice,

	input [XLEN - 1:0] imm,
	input [XLEN - 1:0] src1,
	input [XLEN - 1:0] src2,
	input [XLEN - 1:0] pc,
	
	output reg [XLEN - 1:0] src2_out, // needed for data for ST
	output reg [XLEN - 1:0] dest,

	// needed in MEM and WB.
	input en_mem,
	output reg en_mem_out,
	input mem_write,
	output reg mem_write_out,
	input mem_read_unsigned,
	output reg mem_read_unsigned_out,
	input [1:0] mem_size,
	output reg [1:0] mem_size_out,

	input en_wb,
	output reg en_wb_out,
	input [4:0] reg_write,
	input [XLEN - 1:0] pcp4,
	input use_pcp4,
	output reg [XLEN - 1:0] pcp4_out,
	output reg [4:0] reg_write_out,
	output reg use_pcp4_out
	);
	parameter XLEN = 32;
	
	wire [XLEN - 1:0] alu_out;

	alu #(.XLEN(XLEN)) a0(
		.op(op),
		.use_imm(use_imm),
		.op_choice(op_choice),
		.imm(imm),
		.src1(src1),
		.src2(src2),
		.pc(pc),
		.dest(alu_out)
	);
	
	always @(posedge clk) begin
		if (en) begin
			src2_out <= src2;
			dest <= alu_out;
		end

		// passthrough
		en_mem_out <= en_mem;
		mem_read_unsigned_out <= mem_read_unsigned;
		mem_write_out <= mem_write;
		mem_size_out <= mem_size;

		en_wb_out <= en_wb;
		pcp4_out <= pcp4;
		reg_write_out <= reg_write;
		use_pcp4_out <= use_pcp4;
	end

	always @(posedge rst) begin
		dest <= {XLEN{1'b0}};
		src2_out <= {XLEN{1'bx}};
		en_mem_out <= 1'b0;
		en_wb_out <= 1'b0;
		use_pcp4_out <= 1'b0;
		reg_write_out <= 1'b0;
	end
endmodule

