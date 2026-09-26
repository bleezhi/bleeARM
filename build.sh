#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/out"
ROOTFS="$OUT/rootfs"
rm -rf "$OUT"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,root,usr/bin,var,run}
cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="bleeARM"
ID=bleearm
PRETTY_NAME="bleeARM experimental ARM OS"
VERSION="0.2-dev"
VERSION_ID="0.2"
EOF
cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
echo
echo "bleeARM 0.2-dev"
echo "target: Lenovo TB-8505F"
echo "qemu target: aarch64 virt"
echo
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"
BUSYBOX="$(command -v busybox || true)"
if [ -z "$BUSYBOX" ]; then echo "busybox is required" >&2; exit 1; fi
cp "$BUSYBOX" "$ROOTFS/bin/busybox"
for cmd in sh mount echo cat ls mkdir uname; do ln -sf busybox "$ROOTFS/bin/$cmd"; done
mkdir -p "$ROOTFS/lib/modules"
(cd "$ROOTFS" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9) > "$OUT/initramfs.cpio.gz"
if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1 && [ -d /usr/src/linux ]; then
  echo "cross compiler found; kernel source integration can be added here"
fi
if command -v qemu-img >/dev/null 2>&1; then
  qemu-img create -f raw "$OUT/bleeARM-aarch64.img" 64M >/dev/null
fi
printf 'built initramfs: %s\n' "$OUT/initramfs.cpio.gz"
printf 'kernel source is intentionally supplied separately for now\n'
