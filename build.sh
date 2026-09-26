#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/out"
ROOTFS="$OUT/rootfs"
IMAGE="$OUT/bleeARM-rootfs.tar.gz"
rm -rf "$OUT"
mkdir -p "$ROOTFS"/{bin,sbin,etc,proc,sys,dev,tmp,root,usr/bin,var,run}
cat > "$ROOTFS/etc/os-release" <<'EOF'
NAME="bleeARM"
ID=bleearm
PRETTY_NAME="bleeARM experimental ARM OS"
VERSION="0.1-dev"
VERSION_ID="0.1"
EOF
cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
echo
echo "bleeARM 0.1-dev"
echo "target: Lenovo TB-8505F"
echo
exec /bin/sh
EOF
chmod +x "$ROOTFS/init"
if command -v busybox >/dev/null 2>&1; then
  cp "$(command -v busybox)" "$ROOTFS/bin/busybox"
  for cmd in sh mount echo cat ls; do ln -sf busybox "$ROOTFS/bin/$cmd"; done
else
  echo "warning: busybox not found; installing it is recommended"
fi
tar -C "$ROOTFS" -czf "$IMAGE" .
printf 'built: %s\n' "$IMAGE"
