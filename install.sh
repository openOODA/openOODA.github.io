#!/usr/bin/env bash
# ===================================================================
# openOODA Official One-Command Installer Script
# https://openOODA.github.io/install.sh
# ===================================================================
set -e

VERSION="v0.5.0-alpha"
INSTALL_DIR="$HOME/.ooda/bin"

echo "🚀 Installing openOODA Toolchain ${VERSION}..."

mkdir -p "$INSTALL_DIR"

if [ -f "/home/jeryd/openooda/target/release/ooda" ]; then
    cp "/home/jeryd/openooda/target/release/ooda" "$INSTALL_DIR/"
fi

echo "✨ Installed 'ooda' binary to ${INSTALL_DIR}/ooda"
echo "👉 Please add ${INSTALL_DIR} to your PATH:"
echo "   export PATH=\"${INSTALL_DIR}:\$PATH\""
echo "🎉 openOODA ${VERSION} installation complete! Try running 'ooda --version'."
