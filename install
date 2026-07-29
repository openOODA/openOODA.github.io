#!/usr/bin/env bash
# ===================================================================
# openOODA Chapter 0 — Bootstrap only
# https://openOODA.github.io/install
#
# Shell is unavoidable *before* `ooda` exists. This script's only job:
#   1) fetch the release tarball
#   2) hand control to install/install.oo (the real installer, in OODA)
#
# The story, paths, and policy live in install.oo — not here.
# ===================================================================
set -euo pipefail

REPO="${OODA_REPO:-openOODA/ooda}"
VERSION="${OODA_VERSION:-v0.52.0-alpha}"
ARCH="${OODA_ARCH:-linux-x86_64}"
ASSET="ooda-${VERSION}-${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"

# XDG-correct cache for bootstrap downloads
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ooda/bootstrap"
WORKDIR="${CACHE}/${VERSION}"
mkdir -p "$WORKDIR"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  openOODA · Chapter 0 · Bootstrap (shell)                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "  Shell cannot implement openOODA. It can only fetch the stage-0 host"
echo "  so the *real* installer (install/install.oo) can run under capability"
echo "  security and tell the full story."
echo ""
echo "  Version : ${VERSION}"
echo "  Asset   : ${ASSET}"
echo "  Cache   : ${WORKDIR}"
echo ""

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required for HTTPS download" >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "error: tar is required to extract the release" >&2
  exit 1
fi

TARBALL="${WORKDIR}/${ASSET}"
echo "  Downloading ${URL}"
curl -fsSL --proto '=https' --tlsv1.2 -o "$TARBALL" "$URL"

echo "  Extracting…"
rm -rf "${WORKDIR}/tree"
mkdir -p "${WORKDIR}/tree"
tar -xzf "$TARBALL" -C "${WORKDIR}/tree"

# Prefer packaged layout bin/ooda; fall back to flat ooda
OODA_BIN="$(find "${WORKDIR}/tree" -type f -name ooda | head -n 1 || true)"
if [[ -z "${OODA_BIN}" ]]; then
  echo "error: ooda binary not found in release archive" >&2
  exit 1
fi
chmod +x "$OODA_BIN"

INSTALL_OO="$(find "${WORKDIR}/tree" -type f -path '*/install/install.oo' | head -n 1 || true)"
if [[ -z "${INSTALL_OO}" ]]; then
  echo "error: install/install.oo missing from release — re-run scripts/release.sh" >&2
  echo "  (falling back is not allowed; the installer must be OODA source)" >&2
  exit 1
fi

echo ""
echo "  Stage-0 binary : ${OODA_BIN}"
echo "  Installer (.oo): ${INSTALL_OO}"
echo ""
echo "  Handing off to OODA — Chapter 1 begins inside install.oo …"
echo ""

# Export pin so install.oo resolves the same version
export OODA_VERSION="${VERSION}"
exec "$OODA_BIN" run "$INSTALL_OO"
