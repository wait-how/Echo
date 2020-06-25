`timescale 1ns / 1ns

`define LUI 	7'b0110111
`define AUIPC 	7'b0010111
`define JAL 	7'b1101111
`define JALR	7'b1100111
`define BCC		7'b1100011
`define LOAD 	7'b0000011
`define STORE 	7'b0100011
`define ARITH_I	7'b0010011
`define ARITH	7'b0110011
`define FENCE	7'b0001111
`define SYS		7'b1110011

`define ERROR_UNSUP $error("This instruction is not yet supported."); $finish;

module instr(
	input clk,
	input en,
	input rst,

	input [XLEN - 1:0] instr,
	
	output reg [4:0] rs1_addr,
	output reg [4:0] rs2_addr,
	
	output reg en_ex,
	output reg [3:0] op,
	output reg is_signed,
	output reg use_imm,
	// source register values come from regfile on negedge
	output reg op_choice,
	output reg uncond_jmp,
	output reg [XLEN - 1:0] imm,

	output reg en_mem,
	output reg mem_write,
	output reg mem_read_unsigned,
	output reg [1:0] mem_size,
	
	output reg en_wb,
	output reg use_pcp4,
	output reg [4:0] reg_write
	);
	parameter XLEN = 32;
	
	wire [6:0] opcode = instr[6:0];
	
	wire [4:0] rs1 = instr[19:15];
	wire [4:0] rs2 = instr[24:20];
	wire [4:0] rd = instr[11:7];
	
	wire [2:0] funct3 = instr[14:12];
	wire [6:0] funct7 = instr[31:25];
	
	// NOTE: immediates are sign-extended to 32 bits when used.
	wire [11:0] imm_12_I = instr[31:20];
	wire [11:0] imm_12_S = {instr[31:25], instr[11:7]};
	wire [19:0] imm_20_U = instr[31:12];
	
	wire [11:0] imm_12_B = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // lsb is ignored
	wire [19:0] imm_20_J = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
	
	always @(posedge clk) begin
		// both registers are read, even though they might not be used.
		rs1_addr <= rs1;
		rs2_addr <= rs2;
		
		if (en) begin
			casex (opcode) // casex is helpful for testing, since fetching opcodes past the end of test memory won't fail
				`LUI: begin
					en_ex <= 1'b1;
					op <= 4'b1011;
					op_choice <= 1'bx;
					uncond_jmp <= 1'b0;
					use_imm <= 1'b1;
					imm <= {imm_20_U, 12'b0};
					
					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b0;
					reg_write <= rd;
				end
				`AUIPC: begin
					en_ex <= 1'b1;
					op <= 4'b1010;
					op_choice <= 1'bx;
					uncond_jmp <= 1'b0;
					use_imm <= 1'b1;
					imm <= {imm_20_U, 12'b0};
					
					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b0;
					reg_write <= rd;
				end
				`JAL: begin
					en_ex <= 1'b1;
					op <= 4'b1010;
					op_choice <= 1'bx;
					uncond_jmp <= 1'b1;
					use_imm <= 1'b1;
					imm <= {{12{imm_20_J[19]}}, imm_20_J};
					
					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b1;
					reg_write <= rd;
				end
				`JALR: begin
					en_ex <= 1'b1;
					op <= 4'b0000;
					op_choice <= 1'b0;
					uncond_jmp <= 1'b1;
					use_imm <= 1'b1;
					imm <= {{20{imm_12_I[11]}}, imm_12_I};
					
					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b1;
					reg_write <= rd;
				end
				`BCC: begin
					// if src1 < src2, branch to offset + pc
					en_ex <= 1'b1;
					op <= {1'b1, funct3};
					op_choice <= 1'bx;
					uncond_jmp <= 1'b0;
					use_imm <= 1'b1;
					imm <= {{11{imm_20_J[19]}}, imm_20_J, 1'b0};
					
					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b0;
					use_pcp4 <= 1'bx;
					reg_write <= {5{1'bx}};
				end
				`LOAD: begin
					en_ex <= 1'b1;
					op <= 4'b0000;
					op_choice <= 1'b1;
					uncond_jmp <= 1'b0;
					use_imm <= 1'b1;
					imm <= {{20{imm_12_I[11]}}, imm_12_I[11:0]};

					en_mem <= 1'b1;
					mem_write <= 1'b0;
					mem_read_unsigned <= instr[14];
					mem_size <= instr[13:12];
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b0;
					reg_write <= rd;
				end
				`STORE: begin
					en_ex <= 1'b1;
					op <= 4'b0000;
					op_choice <= 1'b1;
					uncond_jmp <= 1'b0;
					use_imm <= 1'b1;
					imm <= {{20{imm_12_S[11]}}, imm_12_S[11:0]};

					en_mem <= 1'b1;
					mem_write <= 1'b1;
					mem_read_unsigned <= instr[14];
					mem_size <= instr[13:12];
					
					en_wb <= 1'b0;
					use_pcp4 <= 1'bx;
					reg_write <= {5{1'bx}};
				end
				`ARITH, `ARITH_I: begin
					en_ex <= 1'b1;
					op <= {1'b0, funct3};
					op_choice <= (opcode == `ARITH_I && funct3 == 3'b0) ? 1'b0 : instr[30]; // subi does not exist
					uncond_jmp <= 1'b0;
					use_imm <= (opcode == `ARITH_I) ? 1'b1 : 1'b0;
					imm <= (opcode == `ARITH_I) ? {{20{imm_12_I[11]}}, imm_12_I[11:0]} : {XLEN{1'bx}};

					en_mem <= 1'b0;
					mem_write <= 1'bx;
					mem_read_unsigned <= 1'bx;
					mem_size <= 2'bx;
					
					en_wb <= 1'b1;
					use_pcp4 <= 1'b0;
					reg_write <= rd;
				end
				`FENCE: begin
					// fence only guarantees the ordering of
					// memory writes and reads.  Since all reads and writes
					// from data memory are not reordered, this is effectively
					// a nop.
					en_ex <= 1'b0;
					en_mem <= 1'b0;
					en_wb <= 1'b0;
				end
				`SYS: begin
					// TODO: need to cause a precise trap to some system call
					// location - write after getting hazards and exceptions
					// working.
					`ERROR_UNSUP;
				end
				default: begin
					// TODO: this should cause some kind of exception
					$error("Encountered unknown opcode!");
					`ERROR_UNSUP;
				end
			endcase
		end
	end

	always @(posedge rst) begin
		rs1_addr <= 5'b0;
		rs2_addr <= 5'b0;

		en_ex <= 1'b0;
		op <= {4{1'b0}}; // jump calculations depend on this, so reset it to not a jump op
		op_choice <= 1'bx;
		uncond_jmp <= 1'b0;
		use_imm <= 1'bx;
		imm <= {XLEN{1'bx}};
		
		en_mem <= 1'b0;
		mem_write <= 1'bx;
		mem_read_unsigned <= 1'bx;
		mem_size <= 2'bxx;
		
		en_wb <= 1'b0;
		use_pcp4 <= 1'bx;
		reg_write <= {5{1'bx}};
	end
endmodule

