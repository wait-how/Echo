The Echo processor:
	A RISC-V compatible 5-stage processor.
	The name was chosen for several reasons:
		1. It's an echo of the standard 5-stage RISC design
		2. It's related to Fives, an earlier attempt at a RISC-V like processor I worked on.

Things I've Learned:
	1. Writing testbenches is mandatory.
	2. Most bugs happen when modules collide - either things are misconnected or I didn't take into account features I needed while designing the module.
	3. I need to write the testbench to exercise _every_ aspect of the module and decision I make - otherwise bugs slip through the cracks.


cleanups:
	1. instead of using a ton of different wires, just have a giant 32/64/etc. bit wire going from stage to stage.  define signals as indices into said giant wire.

TODO:
	- Add some serious JAL and JALR code to the testbench - encoding is super weird and it needs to be tested.
	
	- BUG: BCC branches if ops aren't equal and they were on the previous clock, since the combo logic is combo.
	 - fix: move branch testing to reg fetch and make sure that imem_pc will accept a jump signal on a negedge.
	 - not really a whole lot we can do about jumps occuring on a negedge, because register vals only become available on a negedge.

	things to test:
		branches
		ECALL
		EBREAK
	
	Easy extensions to add:
		Zifencei - currently can't write to instruction memory. nop.
		Zicsr - several instructions for reading and writing registers:
		 - cycle count
		 - time
		 - instructions retired
	
	Conformance Suite
		- build gnu toolchain for rv32
		- build riscv-tests
		- make sure I can execute code coming from gcc
			- want nostartfiles, nostdlib, etc.
			- likely the same options as with m68k
		- run test suite
		- fix bugs

	make sure tb's pass for individual pipeline stages
	make sure all behavior for stages are covered in testbenches
	
	pass register addr info (rs1, rs2, rd) along every stage - helps with hazard detection.
		can pass x0 in an addr for no dep - since x0 is constant, there are no deps on it!
	
	Misc instructions
		FENCE - nop.
		FENCE.I - not rv32i, but easy nop.
		
	Hazards
		RAW - forwarding from EX to MEM and WB (and from MEM to WB?)
			- stall a dependancy on MEM going to EX
		Exceptions - should be precise
	System Calls
	Performance Counters - defined by the spec.
	
	make sure all the verilog looks good, and write comments.
		try and take out things I don't need, but be really careful about breaking things!
	
	Run this in Vivado and find out how to start optimizing it, max freq, etc.

code:
	replace stage io with SV interfaces
	always blocks on combo logic is a thing

optimizations:
	superscalar execution
		start with multiple basic ALU units, a barrel shifter, etc.
		if EX units take >1 cc: WAR and WAW hazards!
	multiplication / division units
		write them myself.  No using "*" - want control over how expensive this is.
	better memory subsystem
		cache
		SRAM interface
	interrupts
	use specific Artix-7 block ram and DSP blocks
