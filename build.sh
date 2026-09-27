#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/out"
ROOTFS="$OUT/rootfs"
KERNEL_VERSION="6.18"
KERNEL_DIR="$OUT/linux-$KERNEL_VERSION"
ARCH_ROOTFS_URL="https://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"

rm -rf "$OUT"
mkdir -p "$OUT" "$ROOTFS"

echo "downloading Arch Linux ARM AArch64 userspace..."
curl -L --fail --retry 3 "$ARCH_ROOTFS_URL" -o "$OUT/archlinuxarm.tar.gz"

echo "extracting Arch Linux ARM userspace..."
bsdtar -xpf "$OUT/archlinuxarm.tar.gz" --no-xattrs --no-acls --no-fflags -C "$ROOTFS"
rm -f "$OUT/archlinuxarm.tar.gz"

echo "customizing bleeARM userspace..."
cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="bleeARM"
ID=bleearm
ID_LIKE=arch
PRETTY_NAME="bleeARM - Arch Linux ARM based"
VERSION="0.4-dev"
VERSION_ID="0.4"
BUILD_ID="qemu-aarch64"
EOF

cat > "$ROOTFS/etc/bleearm-release" <<'EOF'
bleeARM 0.4-dev
base: Arch Linux ARM
architecture: aarch64
qemu target: aarch64 virt
hardware target: Lenovo TB-8505F
EOF

printf '%s
' 'bleearm' > "$ROOTFS/etc/hostname"

# Keep the development initramfs small enough for GitHub Actions/QEMU.
rm -rf "$ROOTFS/var/cache/pacman/pkg/"* "$ROOTFS/usr/share/doc/"* "$ROOTFS/usr/share/man/"* "$ROOTFS/usr/share/info/"* "$ROOTFS/usr/lib/debug/"*


cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true

echo
echo "bleeARM 0.4-dev"
echo "base: Arch Linux ARM"
echo "architecture: aarch64"
echo "target: Lenovo TB-8505F"
echo "qemu target: aarch64 virt"
echo
echo "Arch Linux ARM userspace is ready."
echo "Run 'pacman-key --init && pacman-key --populate archlinuxarm' before using pacman."
echo

export HOME=/root
export PS1='bleeARM# '
exec /bin/bash
EOF
chmod +x "$ROOTFS/init"

echo "verifying Arch userspace architecture..."
aarch64-linux-gnu-readelf -h "$ROOTFS/bin/bash" | grep -E 'Class:.*ELF64|Machine:.*AArch64'

echo "creating initramfs..."
mkdir -p "$ROOTFS/lib/modules"
(cd "$ROOTFS" && find . -xdev -print0 | cpio --null -o --format=newc --no-preserve-owner 2>"$OUT/cpio-errors.log" | gzip -1) > "$OUT/initramfs.cpio.gz"
if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  cat "$OUT/cpio-errors.log" >&2
  exit 1
fi

echo "downloading Linux $KERNEL_VERSION..."
curl -L --fail --retry 3 "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz" -o "$OUT/linux.tar.xz"
tar -xf "$OUT/linux.tar.xz" -C "$OUT"
rm -f "$OUT/linux.tar.xz"

echo "configuring Linux for aarch64 QEMU virt..."
make -C "$KERNEL_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig

echo "building Linux Image..."
make -C "$KERNEL_DIR" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j"$(nproc)" Image
cp "$KERNEL_DIR/arch/arm64/boot/Image" "$OUT/Image"

printf 'built Arch Linux ARM rootfs: %s
' "$ROOTFS"
printf 'built kernel: %s
' "$OUT/Image"
printf 'built initramfs: %s
' "$OUT/initramfs.cpio.gz"
