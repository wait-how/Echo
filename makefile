VCC := iverilog
FLAGS := -Wall -Winfloop -g2005 -gio-range-error
# don't print pseudoinstructions
ASMFLAGS := -march=rv32i -mabi=ilp32

.PHONY: pc gpc dec gdec alu galu dmem gdmem echo gecho clean

%.v:
	touch -c $@

tb%.v:
	touch -c $@

pc:
	$(VCC) -IIF IF/tbpc.v -s tb$@ $(FLAGS) -o proc.vvp
	vvp proc.vvp -lxt

gpc:
	@make pc
	gtkwave -f dump.lxt IF/config.gtkw

dec:
	$(VCC) -IID ID/tbregfile.v -s tbregfile $(FLAGS) -o proc.vvp
	vvp proc.vvp -lxt

gdec:
	@make dec
	gtkwave -f dump.lxt ID/config.gtkw

alu:
	$(VCC) -IEX EX/tbalu.v -s tb$@ $(FLAGS) -o proc.vvp
	vvp proc.vvp -lxt

galu:
	@make alu
	gtkwave -f dump.lxt EX/config.gtkw

dmem:
	$(VCC) -IMEM MEM/tbdmem.v -s tb$@ $(FLAGS) -o proc.vvp
	vvp proc.vvp -lxt

gdmem:
	@make dmem
	gtkwave -f dump.lxt MEM/config.gtkw

as:
	@riscv64-unknown-elf-as $(ASMFLAGS) test_program.S -o test.out
	@riscv64-unknown-elf-objcopy -O binary test.out test.bin
	@riscv64-unknown-elf-objdump -d -Mno-aliases,numeric test.out

echo:
	@make as
	$(VCC) -IIF -IID -IEX -IMEM -IWB tbecho.v -s tb$@ $(FLAGS) -o proc.vvp
	vvp proc.vvp -lxt

gecho:
	@make echo
	gtkwave -f dump.lxt config.gtkw

clean:
	@rm -f test.*
	@rm -f proc.vvp
	@rm -f dump.lxt
