`include "regfile.v"
`include "instr.v"
`timescale 1ns / 1ns

`define BEQ		4'b1000
`define BNE     4'b1001
`define BLT     4'b1100
`define BGE     4'b1101
`define BLTU    4'b1110
`define BGEU    4'b1111
`define JAL		4'b1010

module decode(
	input clk,
	input en,
	input rst,
	
	input [XLEN - 1:0] instr,
	input [XLEN - 1:0] pc,
	input [XLEN - 1:0] pcp4,
    
	// from WB to regfile, which is in decode
    input write_en,
    input [4:0] rd, 
    input [XLEN - 1:0] rd_val,

	output taken,
	output [XLEN - 1:0] taken_addr,

	// EX
	output en_ex,
    output [3:0] op,
    output is_signed,
    output use_imm,

	output [XLEN - 1:0] rs1_val,
    output [XLEN - 1:0] rs2_val,
    
	output op_choice,
	output uncond_jmp,
    output [XLEN - 1:0] imm,
    output reg [XLEN - 1:0] pc_out,
	
	// MEM
    output en_mem,
    output mem_write,
    output mem_read_unsigned,
    output [1:0] mem_size,
    
	// WB
    output en_wb,
	output reg [XLEN - 1:0] pcp4_out,
    output [4:0] reg_write,
	output use_pcp4,
	
	output reg [4:0] rs1_addr_out,
	output reg [4:0] rs2_addr_out,
	output reg [6:0] opcode_out // not required anymore?
	);
	parameter XLEN = 32;
	
	wire [4:0] rs1_addr;
	wire [4:0] rs2_addr;
	
	wire en_mem_int;
	wire en_wb_int;

	reg taken_delay_1;
	
	// gate off writes if we're inside a branch delay slot
	assign en_mem = en_mem_int & ~taken;
	assign en_wb = en_wb_int & ~taken_delay_1;

	instr i0 (
		.clk(clk),
		.en(en),
		.rst(rst),
		.instr(instr),
		.rs1_addr(rs1_addr),
		.rs2_addr(rs2_addr),
		.imm(imm),
		.en_ex(en_ex),
		.op(op),
		.is_signed(is_signed),
		.use_imm(use_imm),
		.op_choice(op_choice),
		.uncond_jmp(uncond_jmp),
		.en_mem(en_mem_int),
		.mem_write(mem_write),
		.mem_read_unsigned(mem_read_unsigned),
		.mem_size(mem_size),
		.en_wb(en_wb_int),
		.reg_write(reg_write),
		.use_pcp4(use_pcp4)
	);
	
    regfile r0 (
        .clk(clk),
        .read_en(en),
        .rst(rst),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .rs1_val(rs1_val),
        .rs2_val(rs2_val),
        .write_en(write_en),
        .rd(rd),
        .rd_val(rd_val)
    );

	wire signed [XLEN - 1:0] rs1_val_s = rs1_val;
	wire signed [XLEN - 1:0] rs2_val_s = rs2_val;

	wire taken_comb = uncond_jmp ? 1'b1 :
					(op == `BEQ) ? ((rs1_val == rs2_val) ? 1'b1 : 1'b0) :
					(op == `BNE) ? ((rs1_val != rs2_val) ? 1'b1 : 1'b0) :
 					(op == `BLT) ? ((rs1_val_s < rs2_val_s) ? 1'b1 : 1'b0) :
					(op == `BGE) ? ((rs1_val_s >= rs2_val_s) ? 1'b1 : 1'b0) :
 					(op == `BLTU) ? ((rs1_val < rs2_val) ? 1'b1 : 1'b0) :
					(op == `BGEU) ? ((rs1_val >= rs2_val) ? 1'b1 : 1'b0) : 1'b0;
	wire taken = taken_comb & en & ~taken_delay_1; // if the instruction after a branch is another branch, make sure not to take that one too.
	
	// using a seperate adder from the EX stage to decrease branch latency to
	// 1 cycle rather than 2. This is an optimization H&P takes, so we'll take it too.
	assign taken_addr = (op == `JAL) ? imm + pc_out : {rs1_val[31:1] + imm[31:1], 1'b0};
	
	always @(posedge clk) begin
		if (en) begin
			taken_delay_1 <= taken;
			pc_out <= pc;
			pcp4_out <= pcp4;
			
			rs1_addr_out <= rs1_addr;
			rs2_addr_out <= rs2_addr;
			opcode_out <= instr[6:0];
		end
	end

	always @(posedge rst) begin
		taken_delay_1 <= 1'b0;
		rs1_addr_out <= 5'b0;
		rs2_addr_out <= 5'b0;
		
		opcode_out <= {7{1'b1}};
	end
endmodule
