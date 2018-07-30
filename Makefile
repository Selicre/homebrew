
ASM=/home/x10a94/Projects/Rust/piped-asm/target/release/piped-asm

OUTPUT=build/out.sfc

$(OUTPUT): *.asm *.bin
	$(ASM) main.asm $(OUTPUT)

all: $(OUTPUT)

clean:
	rm build/*


