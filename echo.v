`include "IF/fetch.v"
`include "ID/decode.v"
`include "EX/execute.v"
`include "MEM/memory.v"
`include "WB/writeback.v"
`timescale 1ns / 1ns

//`define VERBOSE
`define DEBUG

module echo (
`ifdef DEBUG
	output reg debug_write_enabled,
	output reg [4:0] debug_write_addr,
	output reg [XLEN - 1:0] debug_write_data,
`endif

	input clk,
	input run,
	input rst

	// no actual IO implemented until I work out a realistic memory bus.  The
	// current architecture assumes memory can respond in a single cycle.
);
	parameter XLEN = 32;
	parameter IMEM_PATH = "imemb.mem";
	parameter IS_BIN = 1; // our processor is always executing real opcodes
	parameter SIZE = 32;

	// this is a lot of wires, I know.  Right now it's easier to get the
	// design working with a lot of typing and then read the _whole_ SV book
	// later.

	wire [XLEN - 1:0] instr;
	wire [XLEN - 1:0] pc_if_id;
	wire [XLEN - 1:0] pcp4_if_id;
	
	wire decode_en;

	wire taken;
	wire [XLEN - 1:0] taken_addr;

	wire [4:0] rd;
	wire [XLEN - 1:0] rd_val;

	wire en_ex;
	wire [3:0] op;
	wire is_signed;
	wire use_imm;
	wire [XLEN - 1:0] rs1_val;
	wire [XLEN - 1:0] rs2_val;
	wire [XLEN - 1:0] rs2_ex_mem;
	wire op_choice;
	wire [XLEN - 1:0] imm;
	wire [XLEN - 1:0] pc_id_ex;
	wire en_mem_id_ex;
	wire mem_write_id_ex;
	wire mem_read_unsigned_id_ex;
	wire [1:0] mem_size_id_ex;
	wire en_wb_id_ex;
	wire [4:0] reg_write_id_ex;
	wire [XLEN - 1:0] pcp4_id_ex;
	wire use_pcp4_id_ex;
	
	wire [XLEN - 1:0] result_ex_mem;
	wire en_mem_ex_mem;
	wire mem_write_ex_mem;
	wire mem_read_unsigned_ex_mem;
	wire [1:0] mem_size_ex_mem;
	wire en_wb_ex_mem;
	wire [4:0] reg_write_ex_mem;
	wire [XLEN - 1:0] pcp4_ex_mem;
	wire use_pcp4_ex_mem;
	
	wire [XLEN - 1:0] mem_data_mem_wb;
	wire en_wb_mem_wb;
	wire en_wb_wb_id;
	wire [XLEN - 1:0] pcp4_mem_wb;
	wire use_pcp4_mem_wb;
	wire [4:0] reg_write_mem_wb;

	wire [4:0] rs1_addr_out;
	wire [4:0] rs2_addr_out;
	wire [6:0] opcode_out;
	
	fetch #(.XLEN(XLEN), .PC_RST(0), .SIZE(SIZE), .IMEM_PATH(IMEM_PATH), .IS_BIN(IS_BIN)) i0 (
		.clk(clk),
		.en(run), // controlled by hazard detection in the future
		
		.rst(rst),
		
		.jmp(taken),
		.jmp_addr(taken_addr),
		
		.instr(instr),

		.pc(pc_if_id),
		.pcp4(pcp4_if_id),
		.decode_en(decode_en)
	);
	
	decode #(.XLEN(XLEN)) d0 (
		.clk(clk),
		.en(decode_en),
		.rst(rst),

		.instr(instr),
		.pc(pc_if_id),
		.pcp4(pcp4_if_id),
		
		.write_en(en_wb_mem_wb), // regfile write coming from WB stage
		.rd(rd),
		.rd_val(rd_val),

		.taken(taken),
		.taken_addr(taken_addr),
		
		.en_ex(en_ex),
		.op(op),
		.is_signed(is_signed),
		.use_imm(use_imm),

		.rs1_val(rs1_val),
		.rs2_val(rs2_val),

		.op_choice(op_choice),
		.imm(imm),
		.pc_out(pc_id_ex),
		
		.en_mem(en_mem_id_ex),
		.mem_write(mem_write_id_ex),
		.mem_read_unsigned(mem_read_unsigned_id_ex),
		.mem_size(mem_size_id_ex),

		.en_wb(en_wb_id_ex),
		.pcp4_out(pcp4_id_ex),
		.reg_write(reg_write_id_ex),
		.use_pcp4(use_pcp4_id_ex),

		.rs1_addr_out(rs1_addr_out),
		.rs2_addr_out(rs2_addr_out),
		.opcode_out(opcode_out)
	);

	execute #(.XLEN(XLEN)) e0 (
		.clk(clk),
		.en(en_ex),
		.rst(rst),
		
		.op(op),
		.use_imm(use_imm),
		.op_choice(op_choice),

		.imm(imm),
		.src1(rs1_val),
		.src2(rs2_val),
		.src2_out(rs2_ex_mem),

		.pc(pc_id_ex),

		.dest(result_ex_mem),
		
		.en_mem(en_mem_id_ex), // kill the instruction after a jump, because RISC-V doesn't have branch delay slots.
		.en_mem_out(en_mem_ex_mem),
		.mem_write(mem_write_id_ex),
		.mem_write_out(mem_write_ex_mem),
		.mem_read_unsigned(mem_read_unsigned_id_ex),
		.mem_read_unsigned_out(mem_read_unsigned_ex_mem),
		.mem_size(mem_size_id_ex),
		.mem_size_out(mem_size_ex_mem),
		
		.en_wb(en_wb_id_ex),
		.en_wb_out(en_wb_ex_mem),
		.reg_write(reg_write_id_ex),
		.reg_write_out(reg_write_ex_mem),
		.pcp4(pcp4_id_ex),
		.pcp4_out(pcp4_ex_mem),
		.use_pcp4(use_pcp4_id_ex),
		.use_pcp4_out(use_pcp4_ex_mem)
	);

	memory #(.XLEN(XLEN)) m0 (
		.clk(clk),
		.en(en_mem_ex_mem),
		.rst(rst),
		
		.addr(result_ex_mem),
		.write_data(rs2_ex_mem),
		.write(mem_write_ex_mem),
		.read_data(mem_data_mem_wb),
		
		.load_unsigned(mem_read_unsigned_ex_mem),
		.size(mem_size_ex_mem),

		.en_wb(en_wb_ex_mem),
		.en_wb_out(en_wb_mem_wb),
		.reg_write(reg_write_ex_mem),
		.reg_write_out(reg_write_mem_wb),
		.pcp4(pcp4_ex_mem),
		.pcp4_out(pcp4_mem_wb),
		.use_pcp4(use_pcp4_ex_mem),
		.use_pcp4_out(use_pcp4_mem_wb)
	);
	
	writeback #(.XLEN(XLEN)) w0 (
		.clk(clk),
		.en(en_wb_mem_wb),
		.en_out(en_wb_wb_id),
		.rst(rst),
		
		.rd(reg_write_mem_wb),
		.res(mem_data_mem_wb),

		.pcp4(pcp4_mem_wb),
		.use_pcp4(use_pcp4_mem_wb),
		
		.rd_out(rd),
		.rd_val(rd_val)
	);

// if enabled, these always blocks will capture the output of the WB stage and
// send it outside of the module.  This makes it easy to test that
// instructions are executing correctly without requiring all instructions to
// work properly.
`ifdef DEBUG
	always @(posedge rst) begin
		debug_write_enabled <= 1'bz;
		debug_write_addr <= 5'bz;
		debug_write_data <= 32'bz;
	end
	
	always @(posedge clk) begin
		debug_write_enabled <= en_wb_wb_id;
		debug_write_addr <= rd;
		debug_write_data <= rd_val;
	end
`endif

// print out a description of what each stage is doing, if enabled.
`ifdef VERBOSE
	reg en_decode_delay_1; // this is just to organize the printing of stages properly.

	always @(posedge rst) begin
		$display("echo processor reset asserted.");
	end

	//always @(negedge clk) begin
	//	if (en_decode_delay_1) begin
	//		$display("using registers x%0d (%h) and x%0d (%h).", rs1_addr_out, rs1_val, rs2_addr_out, rs2_val);
	//	end
	//end

	always @(posedge clk) begin
		en_decode_delay_1 <= run;
		if (op == {XLEN{1'b1}}) begin
			$display("reached shutdown opcode, ending simulation.");
			$finish;
		end
		if (run) begin
			$display("fetched instruction at address %h.", pc_if_id);
			if (decode_en) begin
			$display("decoded opcode %b, destination x%0d.", opcode_out, reg_write_id_ex);
			end
			if (en_ex) begin
				$display("executing operation %b (op choice %0b) on %h (src1) and %h (src2), imm is %h, pc is %h.", op, op_choice, rs1_val, rs2_val, imm, pc_id_ex);
			end
			if (en_mem_ex_mem) begin
				if (mem_write_ex_mem) begin
					$write("writing");
				end else begin
					$write("reading");
				end
				$write(" address %h ", result_ex_mem);
				if (mem_write_ex_mem) begin
					$write("with data %0h.\n", rs2_ex_mem);
				end else begin
					$write("into register x%0d.\n", reg_write_ex_mem);
				end
			end
			if (en_wb_mem_wb) begin
				$display("writeback stage enabled, writing %h to register x%0d.", mem_data_mem_wb, reg_write_mem_wb);
			end
			$display("");
		end
	end
`endif
endmodule
