`include "dmem.v"
`timescale 1ns / 1ns

module memory(
	input clk,
	input en,
	input rst,
	
	input [XLEN - 1:0] addr, // output of ALU is effective address - reg + imm.
	input [XLEN - 1:0] write_data,

	input write,

	output reg [XLEN - 1:0] read_data,
	
	input load_unsigned,
	input [1:0] size,
	
	// needed in WB.
	input en_wb,
	input [XLEN - 1:0] pcp4,
	input use_pcp4,
	output reg en_wb_out,
	output reg [XLEN - 1:0] pcp4_out,
	output reg use_pcp4_out,
	input [4:0] reg_write,
	output reg [4:0] reg_write_out
	);
	parameter XLEN = 32;
	
	wire [XLEN - 1:0] read;
	
	wire [XLEN - 1:0] read_se8 = {{24{read[7]}}, read[7:0]};
	wire [XLEN - 1:0] read_se16 = {{16{read[15]}}, read[15:0]};
	
	wire [XLEN - 1:0] read_ze8 = {24'b0, read[7:0]};
	wire [XLEN - 1:0] read_ze16 = {16'b0, read[15:0]};
	
	dmem #(.SIZE(64)) d0 (
		.clk(clk),
		.en(en),
		.write(write),
		.size(size),
		.addr(addr),
		.data_in(write_data),
		.data_out(read)
	);
	
	always @(posedge clk) begin
		if (en) begin
			if (write) begin
				// nothing to do - handled by dmem
			end else begin
				case (size)
					`SIZE_8: read_data <= (load_unsigned) ? read_ze8 : read_se8;
					`SIZE_16: read_data <= (load_unsigned) ? read_ze16 : read_se16;
					`SIZE_32: read_data <= read;
					default: begin
						$error("Illegal memory access size!");
						$finish;
					end
				endcase
			end
		end else begin
			read_data <= addr;
		end

		// passthrough
		en_wb_out <= en_wb;
		pcp4_out <= pcp4;
		reg_write_out <= reg_write;
		use_pcp4_out <= use_pcp4;
	end

	always @(posedge rst) begin
		read_data <= {XLEN{1'b0}};
		en_wb_out <= 1'b0;
		reg_write_out <= 1'b0;
		use_pcp4_out <= 1'b0;
	end
endmodule

