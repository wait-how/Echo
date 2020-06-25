`timescale 1ns / 1ns

module imem_pc(
	input clk,
	input en,
	input rst,

	input jmp,
	input [XLEN - 1:0] jmp_addr,

	output reg [XLEN - 1:0] instr,
	output reg [XLEN - 1:0] pc_out, // program counter value when the instruction was fetched, going to decode
	output reg [XLEN - 1:0] pcp4_out, // next instruction, used with JAL and JALR.
	
	output reg decode_en
	);
	parameter XLEN = 32;
	parameter SIZE = 128;
	parameter IMEM_PATH = "imemb.mem";
	parameter IS_BIN = 0; // 1 if the file is binary, 0 if a regular verilog mem file
	parameter PC_RST = 32'h0; // may want the PC to reset to some specific address

	reg [7:0] imem[SIZE - 1:0];
	
	integer file_handle;
	integer result;
	
	initial begin
		$display("loading binary %s of size %0d.", IMEM_PATH, SIZE);
		if (IS_BIN) begin
			file_handle = $fopen(IMEM_PATH, "rb");
			result = $fread(imem, file_handle);
		end else begin
			$readmemb(IMEM_PATH, imem, 0, SIZE - 1);
		end
	end
	
	reg [XLEN - 1:0] pc;
	wire [XLEN - 1:0] pcp4 = pc + 4;
	wire [XLEN - 1:0] new_pc = (jmp) ? jmp_addr + 4 : pcp4;
	
	// assigning wires directly is likely faster than a seperate add...
	// TODO: this program counter does not support exceptions for misaligned
	// counter addresses.
	wire [XLEN - 1:0] new_or_current_pc = (jmp) ? jmp_addr : pc;
	wire [XLEN - 1:0] new_pc_0 = {new_or_current_pc[XLEN - 1:2], 2'b00};
	wire [XLEN - 1:0] new_pc_1 = {new_or_current_pc[XLEN - 1:2], 2'b01};
	wire [XLEN - 1:0] new_pc_2 = {new_or_current_pc[XLEN - 1:2], 2'b10};
	wire [XLEN - 1:0] new_pc_3 = {new_or_current_pc[XLEN - 1:2], 2'b11};

	always @(posedge clk) begin
		decode_en <= en;
		if (en) begin
			pc_out <= pc;
			pc <= new_pc;
			
			pcp4_out <= pcp4;

			instr <= {imem[new_pc_3], imem[new_pc_2], imem[new_pc_1], imem[new_pc_0]}; // having imem fetch instructions that are possibly from jump_addr makes things faster down the line since we only have to deal with one incorrectly fetched instruction instead of two.
		end
	end

	always @(posedge rst) begin
		instr <= {imem[PC_RST + 3], imem[PC_RST + 2], imem[PC_RST + 1], imem[PC_RST]};
		pc <= PC_RST;
		// pc_out assigned at first clock
		decode_en <= 1'b0;
	end
endmodule

