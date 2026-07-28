#!/usr/bin/env bash
# ===================================================================
# openOODA Official Installer
# https://openOODA.github.io/install.sh
#
# Downloads the latest published Linux x86_64 release binary from GitHub.
# ===================================================================
set -euo pipefail

REPO="openOODA/ooda"
VERSION="${OODA_VERSION:-v0.20.0-alpha"
INSTALL_DIR="${OODA_INSTALL_DIR:-$HOME/.ooda/bin}"
ASSET="ooda-${VERSION}-linux-x86_64.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"

echo "Installing openOODA toolchain ${VERSION}..."
mkdir -p "$INSTALL_DIR"
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi

echo "Downloading ${URL}"
if ! curl -fsSL "$URL" -o "$TMPDIR/$ASSET"; then
  echo "error: failed to download release asset." >&2
  echo "  Check that ${VERSION} exists at https://github.com/${REPO}/releases" >&2
  echo "  Or set OODA_VERSION=vX.Y.Z-alpha to pin a published release." >&2
  exit 1
fi

tar -xzf "$TMPDIR/$ASSET" -C "$TMPDIR"
# tarball contains a single directory with the ooda binary
BIN="$(find "$TMPDIR" -type f -name ooda | head -n 1)"
if [ -z "$BIN" ] || [ ! -x "$BIN" ]; then
  # also accept non-executable then chmod
  BIN="$(find "$TMPDIR" -type f -name ooda | head -n 1)"
fi
if [ -z "$BIN" ]; then
  echo "error: ooda binary not found inside archive" >&2
  exit 1
fi
chmod +x "$BIN"
cp "$BIN" "$INSTALL_DIR/ooda"

echo "Installed: ${INSTALL_DIR}/ooda"
echo "Add to PATH:"
echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
if "${INSTALL_DIR}/ooda" --version >/dev/null 2>&1; then
  echo "Version: $("${INSTALL_DIR}/ooda" --version)"
else
  echo "Binary installed; run: ${INSTALL_DIR}/ooda --version"
fi
echo "Done."
