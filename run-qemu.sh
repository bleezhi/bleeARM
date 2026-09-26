#!/usr/bin/env bash
set -euo pipefail

exec qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a53 \
  -m 1G \
  -kernel out/Image \
  -initrd out/initramfs.cpio.gz \
  -append "console=ttyAMA0 rdinit=/init" \
  -nographic
