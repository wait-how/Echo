`timescale 1ns / 1ns

`define ADD_SUB		4'b0000
`define SLT			4'b0010
`define SLTU 		4'b0011 
`define XOR			4'b0100
`define OR			4'b0110
`define AND			4'b0111
`define SLL 		4'b0001
`define SRL_SRA 	4'b0101
`define AUIPC		4'b1010
`define LUI			4'b1011

module alu (
	input [3:0] op,
	input use_imm,
	input op_choice,
	
	input [XLEN - 1:0] imm, // assume imm has been sign-extended in ID
	input [XLEN - 1:0] src1,
	input [XLEN - 1:0] src2,
	input [XLEN - 1:0] pc,

	output [XLEN - 1:0] dest
	);

	parameter XLEN = 32;
	
	wire signed [XLEN - 1:0] src1_s = src1;
	wire signed [XLEN - 1:0] src2_s = src2;
	wire signed [XLEN - 1:0] imm_s = imm;

	wire [XLEN - 1:0] add_res = src1 + ((use_imm) ? imm : src2);
	wire [XLEN - 1:0] sub_res = src1 - ((use_imm) ? imm : src2);
	
	wire [XLEN - 1:0] sll_res = src1 << ((use_imm) ? imm[4:0] : src2[4:0]);
	wire [XLEN - 1:0] srl_res = src1 >> ((use_imm) ? imm[4:0] : src2[4:0]);
	wire [XLEN - 1:0] sra_res = src1_s >>> ((use_imm) ? imm[4:0] : src2[4:0]);
	
	wire [XLEN - 1:0] and_res = src1 & ((use_imm) ? imm : src2);
	wire [XLEN - 1:0] or_res = src1 | ((use_imm) ? imm : src2);
	wire [XLEN - 1:0] xor_res = src1 ^ ((use_imm) ? imm : src2);
	
	wire [XLEN - 1:0] slt_res = (use_imm) ? ((src1_s < imm_s) ? 1'b1 : 1'b0) : ((src1_s < src2_s) ? 32'b1 : 32'b0);
	wire [XLEN - 1:0] sltu_res = (use_imm) ? ((src1 < imm) ? 1'b1 : 1'b0) : ((src1 < src2) ? 32'b1 : 32'b0);
	
	wire [XLEN - 1:0] lui_res = imm; // immediate already set up in decode
	wire [XLEN - 1:0] auipc_res = lui_res + pc;
	
	// this isn't clocked, but the downside is computing every operation all
	// the time.
	assign dest = 
		(op == `ADD_SUB) ? ((op_choice) ? sub_res : add_res) :
		(op == `SLL) ? sll_res :
		(op == `SRL_SRA) ? ((op_choice) ? sra_res : srl_res) :
		(op == `AND) ? and_res :
		(op == `OR) ? or_res :
		(op == `XOR) ? xor_res :
		(op == `SLT) ? slt_res :
		(op == `SLTU) ? sltu_res :
		(op == `LUI) ? lui_res :
		(op == `AUIPC) ? auipc_res : {32{1'bx}}; // all branches require the ALU to do a pc-relative add for the target
endmodule

