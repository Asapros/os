.PHONY: emulate clean
.ONESHELL:

BUILD := build

BIN := $(BUILD)/bin
BOOTLOADER = $(BIN)/bootloader.efi

EMULATION := $(BUILD)/emulation
DRIVE = $(EMULATION)/drive.img
PARTITIONS := $(EMULATION)/partitions
ESP := $(PARTITIONS)/esp.img
SYSTEM := $(PARTITIONS)/system.img

emulate: $(DRIVE)
	qemu-system-x86_64 \
		-machine q35 \
		-m 128M \
		-bios /usr/share/edk2/x64/OVMF.4m.fd \
		-drive format=raw,file=$< \
		-net none \
		-display gtk

$(DRIVE): $(ESP) $(SYSTEM) | $(EMULATION)
	truncate -s 128M $@
	sfdisk $@ <<-'EOF'
	label: gpt
	unit: sectors

	start=2048, size=126976, type=U
	start=129024, type=12345678-1234-5678-9ABC-123456789ABC
	EOF
	dd if=$(ESP) of=$@ seek=2048 conv=notrunc
	dd if=$(SYSTEM) of=$@ seek=129024 conv=notrunc

$(ESP): $(BOOTLOADER) | $(PARTITIONS)
	truncate -s 62M $@
	mkfs.fat -F 16 $@
	mmd -i $@ ::/EFI
	mmd -i $@ ::/EFI/BOOT
	mcopy -i $@ $< ::/EFI/BOOT/BOOTX64.EFI

$(SYSTEM): | $(PARTITIONS)
	truncate -s 64M $@

$(BOOTLOADER): src/bootloader.asm | $(BIN)
	fasm $< $@

$(BIN): | $(BUILD)
	mkdir -p $@

$(PARTITIONS): | $(EMULATION)
	mkdir -p $@

$(EMULATION): | $(BUILD)
	mkdir -p $@

$(BUILD):
	mkdir -p $@

clean:
	rm -r $(BUILD)
