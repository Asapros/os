.PHONY: emulate

BUILD := build
ESP := $(BUILD)/esp
BOOTLOADER := $(ESP)/EFI/BOOT/BOOTX64.EFI

emulate: $(BOOTLOADER)
	qemu-system-x86_64 \
		-machine q35 \
		-m 256M \
		-bios /usr/share/edk2/x64/OVMF.4m.fd \
		-drive format=raw,file=fat:rw:$(ESP) \
		-net none \
		-display gtk

$(BOOTLOADER): src/bootloader.asm | $(ESP)/EFI/BOOT
	fasm $< $@

$(ESP)/EFI/BOOT:
	mkdir -p $@

clean:
	rm -r build
