#
# mykernel/zig/Makefile
#
# Copyright (C) 2023 binarycraft
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
# This file is part of the BOOTBOOT Protocol package.
# @brief An example Makefile for sample kernel
#
#

all: zig-out/bin/mykernel.x86_64.elf

run.x86_64: boot.iso
	qemu-system-x86_64.exe -no-reboot -cdrom .\boot.iso  -serial stdio -m 1G -smp 4 -d int

boot.iso:zig-out/bin/mykernel.x86_64.elf
	cp zig-out/bin/mykernel.x86_64.elf iso_root/boot
	cp lib/limine/limine-bios.sys lib/limine/limine-bios-cd.bin lib/limine/limine-uefi-cd.bin iso_root/boot/limine/
	cp lib/limine/BOOTX64.EFI lib/limine/BOOTIA32.EFI iso_root/EFI/BOOT/
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
        -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        iso_root -o boot.iso

SRC = $(wildcard src/*) $(wildcard src/*/*) $(wildcard src/*/*/*) $(wildcard src/*/*/*/*)

zig-out/bin/mykernel.x86_64.elf: $(SRC) build.zig Makefile
	zig build -Dtarget=x86_64-freestanding-none -Doptimize=ReleaseFast -freference-trace=10 
	objdump -d ./zig-out/bin/mykernel.x86_64.elf -Mintel -l > dis.asm

clean:
	rm -rf *.elf zig-cache || true