#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/out"
ROOTFS="$OUT/rootfs"
KERNEL_VERSION="6.18"
KERNEL_DIR="$OUT/linux-$KERNEL_VERSION"
BUSYBOX_VERSION="1.37.0"
BUSYBOX_DIR="$OUT/busybox-$BUSYBOX_VERSION"

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

echo "building ARM64 BusyBox $BUSYBOX_VERSION..."
curl -L --fail --retry 3   "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"   -o "$OUT/busybox.tar.bz2"
tar -xf "$OUT/busybox.tar.bz2" -C "$OUT"
rm -f "$OUT/busybox.tar.bz2"

make -C "$BUSYBOX_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' "$BUSYBOX_DIR/.config"
make -C "$BUSYBOX_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j"$(nproc)"
make -C "$BUSYBOX_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CONFIG_PREFIX="$ROOTFS" install

echo "verifying BusyBox architecture..."
aarch64-linux-gnu-readelf -h "$ROOTFS/bin/busybox" | grep -E 'Class:.*ELF64|Machine:.*AArch64'

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

printf 'built ARM64 BusyBox rootfs: %s\n' "$ROOTFS"
printf 'built kernel: %s\n' "$OUT/Image"
printf 'built initramfs: %s\n' "$OUT/initramfs.cpio.gz"
