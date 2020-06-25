`include "execute.v"
`timescale 1ns / 1ns

module tbalu();
	parameter XLEN = 32;
	parameter XLENM1 = XLEN - 1;
	parameter CLK_PERIOD = 10;

	reg clk, en, rst;

	reg [3:0] op;
	reg use_imm, op_choice;

	reg [XLENM1:0] imm;
	reg [XLENM1:0] src1;
	reg [XLENM1:0] src2;
	reg [XLENM1:0] pc;
	reg [XLENM1:0] pcp4;
	
	wire [XLENM1:0] dest;
	wire taken;

	// needed in MEM and WB.
	reg mem_write;
	reg mem_read_unsigned;
	reg [1:0] mem_size;
	reg [4:0] reg_write;
	reg write_pc;
	wire mem_write_out;
	wire mem_read_unsigned_out;
	wire [1:0] mem_size_out;
	wire [4:0] reg_write_out;
	wire write_pc_out;

	reg en_wb;
	reg en_mem;
	wire en_wb_out;
	wire en_mem_out;

	execute #(.XLEN(32)) e0 (
		.clk(clk),
		.en(en),
		.rst(rst),
		
		.op(op),

		.op_choice(op_choice),

		.use_imm(use_imm),
		.imm(imm),
		
		.src1(src1),
		.src2(src2),
		.pc(pc),
		.pcp4(pcp4),
		
		.dest(dest),
		.taken(taken),
		
		.en_mem(en_mem),
		.en_wb(en_wb),
		.en_mem_out(en_mem_out),
		.en_wb_out(en_wb_out),
		.mem_write(mem_write),
		.mem_read_unsigned(mem_read_unsigned),
		.mem_size(mem_size),
		.reg_write(reg_write),
		.mem_write_out(mem_write_out),
		.mem_read_unsigned_out(mem_read_unsigned_out),
		.reg_write_out(reg_write_out),
		.write_pc(write_pc),
		.write_pc_out(write_pc_out)
	);
	
	always #(CLK_PERIOD / 2.0) begin
		clk <= ~clk;
	end
	
	integer test_number = 0;
	task test_dest_eq;
		input [31:0] val;
		begin
			#1;
			if (dest != val) begin
				$display("Test %0d failed: dest = %0d, expected %0d.", test_number, dest, val);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask
	
	task test_taken;
		input val;
		begin
			#1;
			if (val != taken) begin
				$display("Test %0d failed: taken = %0d, expected %0d.", test_number, taken, val);
				$finish;
			end
			test_number = test_number + 1;
		end
	endtask

	initial begin
		$dumpfile("dump.lxt");
		$dumpvars(0, tbalu);
		$display("\n\nstarting alu simulation...");
		clk <= 0;
		en <= 0;
		rst <= 1;
		op <= `ADD_SUB;
		use_imm <= 1'b0;
		op_choice <= 1'b1;
		imm <= 32'h0;
		src1 <= 32'h0;
		src2 <= 32'h0;
		pc <= 32'h0;

		en_mem <= 1'b0;
		en_wb <= 1'b0;
		@(posedge clk);
		en <= 1;
		rst <= 0;

		src1 <= 32'h5;
		src2 <= 32'h4;
		imm <= 32'h4;
		@(posedge clk);
		test_dest_eq(9);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(9);
		
		use_imm <= 1'b0;
		op_choice <= 1'b0;
		@(posedge clk);
		test_dest_eq(1);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(1);
		
		use_imm <= 1'b0;
		op <= `SLL;
		@(posedge clk);
		test_dest_eq(32'h50);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'h50);
		
		use_imm <= 1'b0;
		op <= `SRL_SRA;
		@(posedge clk);
		test_dest_eq(0);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(0);

		src1 <= 32'h800000F0;
		op <= `SRL_SRA;
		use_imm <= 1'b0;
		op_choice <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'hF800000F);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'hF800000F);

		src1 <= 32'h5A;
		src2 <= 32'h55;
		imm <= 32'h55;
		op <= `AND;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(32'h50);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'h50);

		op <= `OR;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(32'h5F);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'h5F);

		op <= `XOR;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(32'hF);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(32'hF);

		src1 <= 32'h80000000;
		src2 <= 32'h5;
		imm <= 32'h5;
		op <= `SLT;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(1);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(1);

		op <= `SLTU;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(0);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(0);

		src1 <= 32'h2;
		use_imm <= 1'b0;
		@(posedge clk);
		test_dest_eq(1);
		
		use_imm <= 1'b1;
		@(posedge clk);
		test_dest_eq(1);
		
		src1 <= 32'h0;
		src2 <= 32'h1;
		op <= `BEQ;
		@(posedge clk);
		test_taken(1'b0);

		imm <= 32'hC;
		pc <= 32'h4;
		op <= `BNE;
		@(posedge clk);
		test_taken(1'b1);
		test_dest_eq(32'h10);

		op <= `BLT;
		@(posedge clk);
		test_taken(1'b1);

		op <= `BGE;
		@(posedge clk);
		test_taken(1'b0);

		src1 <= 32'h1;
		@(posedge clk);
		test_taken(1'b1);
		
		src1 <= -4;
		src2 <= -1;
		op <= `BLT;
		@(posedge clk);
		test_taken(1'b1);
		
		op <= `BLTU;
		@(posedge clk);
		test_taken(1'b1);
		
		src2 <= -4;
		op <= `BGEU;
		@(posedge clk);
		test_taken(1'b1);

		$display("alu simulation finished %0d tests.\n\n", test_number);
		$finish;
	end
endmodule
