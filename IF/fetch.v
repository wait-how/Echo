`include "imem_pc.v"
`timescale 1ns / 1ns

module fetch(
	input clk,
	input en,
	input rst,
	
	input jmp,
	input [XLEN - 1:0] jmp_addr,

	output [XLEN - 1:0] instr,
	output [XLEN - 1:0] pc,
	output [XLEN - 1:0] pcp4,
	output decode_en
	);
	parameter XLEN = 32;
	parameter PC_RST = 0;
	parameter IMEM_PATH = "imemb.mem";
	parameter IS_BIN = 0;
	parameter SIZE = 128;

	wire [XLEN - 1:0] mem_val;
	
	imem_pc #(.XLEN(XLEN), .PC_RST(PC_RST), .SIZE(SIZE), .IMEM_PATH(IMEM_PATH), .IS_BIN(IS_BIN)) i_pc0 (
		.clk(clk),
		.en(en),
		.rst(rst),
		.jmp(jmp),
		.jmp_addr(jmp_addr),
		.instr(mem_val),
		.pc_out(pc),
		.pcp4_out(pcp4),
		.decode_en(decode_en)
	);

	assign instr = mem_val;

endmodule

