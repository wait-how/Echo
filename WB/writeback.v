`timescale 1ns / 1ns

module writeback(
	input clk,
	input en,
	output reg en_out,
	input rst,
	
	input [4:0] rd,
	input [XLEN - 1:0] res,
	
	input [XLEN - 1:0] pcp4,
	input use_pcp4,
	
	output reg [4:0] rd_out,
	output reg [XLEN - 1:0] rd_val
	);
	parameter XLEN = 32;

	always @(posedge clk) begin
		en_out <= en;
		if (en) begin
			rd_out <= rd;
			if (use_pcp4) begin
				rd_val <= pcp4;
			end else begin
				rd_val <= res;
			end
		end
	end
	
	always @(posedge rst) begin
		en_out <= 1'b0;
		rd_out <= {5{1'bx}};
		rd_val <= {XLEN{1'bx}};
	end
endmodule
