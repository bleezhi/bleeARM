#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/out"
ROOTFS="$OUT/rootfs"
KERNEL_VERSION="6.18"
KERNEL_DIR="$OUT/linux-$KERNEL_VERSION"

rm -rf "$OUT"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,root,usr/bin,var,run}

cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="bleeARM"
ID=bleearm
PRETTY_NAME="bleeARM experimental ARM OS"
VERSION="0.3-dev"
VERSION_ID="0.3"
EOF

cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
echo
echo "bleeARM 0.3-dev"
echo "target: Lenovo TB-8505F"
echo "qemu target: aarch64 virt"
echo "userspace: BusyBox (Debian/Fedora userspace planned)"
echo
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"

BUSYBOX="$(command -v busybox || true)"
if [ -z "$BUSYBOX" ]; then
  echo "busybox is required" >&2
  exit 1
fi

cp "$BUSYBOX" "$ROOTFS/bin/busybox"
for cmd in sh mount echo cat ls mkdir uname; do
  ln -sf busybox "$ROOTFS/bin/$cmd"
done

mkdir -p "$ROOTFS/lib/modules"
(cd "$ROOTFS" && find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9) > "$OUT/initramfs.cpio.gz"

echo "downloading Linux $KERNEL_VERSION..."
curl -L --fail --retry 3 "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz" -o "$OUT/linux.tar.xz"
tar -xf "$OUT/linux.tar.xz" -C "$OUT"
rm -f "$OUT/linux.tar.xz"

echo "configuring Linux for aarch64 QEMU virt..."
make -C "$KERNEL_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig

echo "building Linux Image..."
make -C "$KERNEL_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j"$(nproc)" Image
cp "$KERNEL_DIR/arch/arm64/boot/Image" "$OUT/Image"

printf 'built kernel: %s\n' "$OUT/Image"
printf 'built initramfs: %s\n' "$OUT/initramfs.cpio.gz"
