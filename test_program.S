addi x0, x0, 0
lui x3, 0xFFFFF
lui x2, 0x1
auipc x1, 0x1
addi x1, x0, -1
addi x0, x0, 0 # I'm calling this a "fat nop" that flushes the pipeline with nops.
addi x0, x0, 0
addi x0, x0, 0
sw x1, 0(x0)
lw x2, 0(x0)
addi x1, x0, 0x1F
slti x1, x0, -2048
sltiu x1, x0, -2048 # (0x800)
xori x1, x0, 0xFA
xori x1, x0, -1528
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
xori x1, x1, -1528
ori x1, x0, 0xFA
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
andi x1, x1, 0xFC
slli x1, x3, 1
srli x1, x3, 1
srai x1, x3, 3
addi x4, x0, -675
addi x5, x0, 871
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
add x1, x4, x5
sub x1, x4, x5
addi x6, x0, 0x4AF
addi x3, x0, 0x5
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
sll x31, x6, x3
addi x9, x0, -849
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
srl x30, x9, x3
sra x30, x9, x3
addi x9, x0, -941
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
or x29, x9, x6
and x28, x9, x6
fence
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jal x2, L0
addi x1, x0, 0xAA # NOT EXECUTED
addi x2, x0, 0xAB # NOT EXECUTED
addi x3, x0, 0xAC # NOT EXECUTED
L0:	addi x27, x0, 0x2
addi x1, x0, 0x114
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
jalr x26, x1, 0x0
addi x1, x0, 0xBA # NOT EXECUTED
addi x2, x0, 0xBB # NOT EXECUTED
addi x3, x0, 0xBC # NOT EXECUTED
L1: addi x25, x0, 0x4
addi x1, x0, 0x1
addi x2, x0, 0x2
addi x0, x0, 0
addi x0, x0, 0
addi x0, x0, 0
beq x1, x2, L2
bne x1, x2, L3
addi x1, x0, 0xCA # NOT EXECUTED
addi x2, x0, 0xCB # NOT EXECUTED
addi x3, x0, 0xCC # NOT EXECUTED
L2: addi x1, x0, 0xFE # NOT EXECUTED
L3: addi x1, x0, 0x2
.dword 0x0 # no support for standard "unimp" pseudoinstruction yet, so we'll use c.unimp instead which is all zeroes.
