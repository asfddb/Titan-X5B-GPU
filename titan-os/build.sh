#!/bin/sh
# build.sh — build the TitanOS bootable ISO with Debian live-build.
#
# Requirements (Debian/Ubuntu host):
#   sudo apt install live-build
#
# Usage:
#   sudo ./build.sh          Build the ISO (needs root: live-build uses chroot).
#   ./build.sh --check       Validate config only — no root, no build (CI-safe).
#   ./build.sh --clean       Remove build artifacts.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

DIST="bookworm" # Debian 12 stable
ARCH="amd64"

check_config() {
	echo "TitanOS: validating configuration..."
	fail=0
	for f in \
		config/package-lists/00-base.list.chroot \
		config/package-lists/10-gaming.list.chroot \
		config/package-lists/20-dev.list.chroot \
		config/includes.chroot/usr/local/bin/titan-mode \
		config/includes.chroot/usr/local/bin/winstall \
		config/hooks/normal/9000-titan-setup.hook.chroot; do
		if [ -f "$f" ]; then
			echo "  ok   $f"
		else
			echo "  MISS $f"
			fail=1
		fi
	done
	if [ "$fail" -eq 0 ]; then
		echo "TitanOS: config OK."
	else
		echo "TitanOS: config incomplete." >&2
		return 1
	fi
}

clean() {
	if command -v lb >/dev/null 2>&1; then
		lb clean --purge 2>/dev/null || true
	fi
	rm -rf .build binary* chroot* live-image-* config/binary config/bootstrap 2>/dev/null || true
	echo "TitanOS: cleaned."
}

do_build() {
	command -v lb >/dev/null 2>&1 ||
		{ echo "live-build not found. Run: sudo apt install live-build" >&2; exit 1; }
	if [ "$(id -u)" -ne 0 ]; then
		echo "build.sh: the real build needs root (live-build uses chroot). Use sudo." >&2
		exit 1
	fi

	echo "TitanOS: configuring live-build ($DIST/$ARCH)..."
	# contrib + non-free-firmware give us Steam, Wine bits, and GPU firmware.
	lb config \
		--distribution "$DIST" \
		--architectures "$ARCH" \
		--archive-areas "main contrib non-free non-free-firmware" \
		--debian-installer none \
		--iso-application "TitanOS" \
		--iso-volume "TitanOS"

	# Steam and 32-bit Wine need i386 multiarch inside the image.
	echo "i386" >config/architectures 2>/dev/null || true

	echo "TitanOS: building ISO (this takes a while and downloads packages)..."
	lb build
	echo "TitanOS: done. ISO is live-image-${ARCH}.hybrid.iso"
}

case "${1:-build}" in
--check) check_config ;;
--clean) clean ;;
build | "") do_build ;;
*) echo "usage: $0 [--check|--clean]" >&2; exit 2 ;;
esac
