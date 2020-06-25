`timescale 1ns / 1ns

`define SIZE_8 2'b00
`define SIZE_16 2'b01
`define SIZE_32 2'b10

module dmem(
	input clk,
	input en,
	input write,
	input [1:0] size, // writes can be 8, 16, or 32-bit.

	input [XLEN - 1:0] addr,
	input [XLEN - 1:0] data_in,
	output reg [XLEN - 1:0] data_out // reads are always 32-bit, cpu sign-extends.
);
	parameter XLEN = 32;
	parameter SIZE = 512;
	
	reg [7:0] memfile[SIZE * 4 - 1:0];
	
	// in order to make things simple, any memory we use has to have single-cycle access.
	always @(negedge clk) begin
		if (en) begin
			if (write) begin
				case (size)
					`SIZE_32: begin
						memfile[addr] <= data_in[7:0];
						memfile[addr + 1] <= data_in[15:8];
						memfile[addr + 2] <= data_in[23:16];
						memfile[addr + 3] <= data_in[31:24];
					end
					`SIZE_16: begin
						memfile[addr] <= data_in[7:0];
						memfile[addr + 1] <= data_in[15:8];
					end
					`SIZE_8: begin
						memfile[addr] <= data_in[7:0];
					end
					default: begin
						$error("illegal memory size!");
						$finish;
					end
				endcase
				data_out <= {XLEN{1'bZ}};
			end else begin
				data_out <= {memfile[addr + 3], memfile[addr + 2], memfile[addr + 1], memfile[addr]};
			end
		end
	end
endmodule
