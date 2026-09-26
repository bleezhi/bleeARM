# bleeARM

experimental ARM OS for the Lenovo TB-8505F, developed on Linux and tested first with QEMU.

## base

bleeARM currently uses a small BusyBox root filesystem so the boot chain can be developed independently of a desktop distribution. The long-term userspace can be based on Debian or Fedora once hardware boot works.

## targets

- QEMU `aarch64/virt` for development
- Lenovo TB-8505F for real hardware

## build

`./build.sh` creates an aarch64 Linux kernel, initramfs, bootable QEMU disk image and test ISO in `out/`.
