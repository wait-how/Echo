# Echo
A RISC-V processor with a 5-stage pipeline. The name was chosen for several reasons:
  
1. It's very similar to the traditional 5-stage RISC pipeline.
2. It's related to Fives, an earlier attempt at a RISCy processor I worked on.

# Lessons Learned
1. Writing testbenches is mandatory, and having one massive testbench is a nightmare for debugging.
2. Most bugs happen when modules collide - either things are misconnected or I didn't take into account features I needed while designing the module.
3. I need to write the testbench to exercise _every_ aspect of the module and decision I make - otherwise bugs slip through the cracks.

# TODOs
 - add some serious JAL and JALR code to the testbench - encoding is super weird and it needs to be tested.
 - BUG: BCC branches if ops aren't equal and they were on the previous clock, since the combo logic is combo.
 - fix: move branch testing to reg fetch and make sure that imem_pc will accept a jump signal on a negedge.
   - not really a whole lot we can do about jumps occuring on a negedge, because register vals only become available on a negedge.
 - make sure tb's pass for individual pipeline stages.
 - make sure all behavior for stages are covered in testbenches.
 - pass register addr info (rs1, rs2, rd) along every stage - helps with hazard detection.
   - can pass x0 in an addr for no dep - since x0 is constant, there are no deps on it!
 - make sure all the verilog looks good, and write comments.
 - Run everything in Vivado and find out how to start optimizing it, max freq, etc.

# Instructions to test
 - branches
 - ECALL
 - EBREAK
 - FENCE
 - FENCE.I
