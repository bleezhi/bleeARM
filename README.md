# bleeARM

Experimental ARM OS for the Lenovo TB-8505F, developed on Linux and tested first with QEMU.

## base

bleeARM is **Arch Linux ARM based**.

The project uses the official generic AArch64 Arch Linux ARM userspace as its starting point, with a bleeARM-specific init script and branding. The kernel is currently built separately for QEMU during CI.

## current userspace

- Arch Linux ARM AArch64
- bash
- pacman
- systemd and the standard Arch ARM base userspace
- bleeARM custom `/init`
- root shell for early QEMU development

Before using pacman in the development shell, initialize the Arch Linux ARM keyring:

```sh
pacman-key --init
pacman-key --populate archlinuxarm
```

Then the normal Arch package workflow can be used:

```sh
pacman -Syu
```

## targets

- QEMU `aarch64/virt` for development
- Lenovo TB-8505F for real hardware

The QEMU kernel is **not** the Lenovo tablet kernel. Real TB-8505F support will require the appropriate MediaTek kernel/device tree, boot format, firmware and hardware drivers.

## build

`./build.sh` creates:

- an AArch64 Linux kernel
- an Arch Linux ARM based initramfs
- a QEMU test ISO package
- an example `system` and `boot` partition archive

The QEMU test is currently booted with:

```sh
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a53 \
  -m 1G \
  -kernel out/Image \
  -initrd out/initramfs.cpio.gz \
  -append "console=ttyAMA0 rdinit=/init" \
  -nographic
```
