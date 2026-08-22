#!/usr/bin/env bash
# openOODA first-boot install.
# This is a host script. It is not .oo. You cannot run .oo until ooda exists.
# Pin: v0.209.0
# Linux x86_64 only. Needs git and gcc.
#
#   curl -fsSL https://openooda.org/install.sh | bash
#   curl -fsSL https://openooda.org/install.sh -o ooda-install && bash ooda-install
#   Old URL /install redirects to /install.sh
#
# Optional: OODA_CHECKOUT=/path/to/ooda  (use a tree you already have; do not reset it)
# Optional: OODA_FS_WRITEDIR=$HOME       (write root; default $HOME)

set -euo pipefail

PIN="v0.209.0"
REPO="https://github.com/openOODA/ooda.git"

die() {
  echo "openOODA install: $*" >&2
  exit 1
}

say() {
  echo "openOODA install: $*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "need $1"
}

is_compiler() {
  local p="$1"
  [[ -x "$p" ]] || return 1
  grep -a -q 'oodac: usage:' "$p" 2>/dev/null || return 1
  if grep -a -q 'pure .oo product CLI' "$p" 2>/dev/null; then
    return 1
  fi
  return 0
}

is_cli() {
  local p="$1"
  [[ -x "$p" ]] || return 1
  grep -a -q 'pure .oo product CLI' "$p" 2>/dev/null
}

OS="$(uname -s)"
ARCH="$(uname -m)"
if [[ "$OS" != "Linux" ]]; then
  die "this script installs Linux x86_64 only. This machine is ${OS} ${ARCH}. No Mac or Windows pack yet."
fi
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  die "this script installs Linux x86_64 only. This machine is ${OS} ${ARCH}. No ARM pack or ARM seed yet."
fi

need_cmd git
need_cmd gcc
need_cmd bash

HOME_USER="${OODA_FS_WRITEDIR:-${HOME:?need HOME}}"
[[ -n "$HOME_USER" ]] || die "need HOME or OODA_FS_WRITEDIR"
[[ -d "$HOME_USER" ]] || die "write root is not a directory: $HOME_USER"

OODA_HOME="${HOME_USER}/.local/share/ooda"
OODA_BIN="${HOME_USER}/.local/bin"
OODA_CONFIG="${HOME_USER}/.config/ooda"
OODA_CACHE="${HOME_USER}/.cache/ooda"
OODA_STD="${OODA_HOME}/std"

if [[ -n "${OODA_CHECKOUT:-}" ]]; then
  SRC="${OODA_CHECKOUT}"
  [[ -d "$SRC" ]] || die "OODA_CHECKOUT is not a directory: $SRC"
  say "using checkout $SRC"
else
  SRC="${OODA_CACHE}/src"
  mkdir -p "${OODA_CACHE}"
  if [[ ! -d "${SRC}/.git" ]]; then
    say "clone ${REPO}"
    git clone --depth 1 --branch main "${REPO}" "${SRC}"
  else
    say "update ${SRC}"
    git -C "${SRC}" fetch --depth 1 origin main
    git -C "${SRC}" checkout -q main
    git -C "${SRC}" reset --hard origin/main
  fi
fi

[[ -d "${SRC}/std" ]] || die "missing ${SRC}/std"
[[ -d "${SRC}/runtime" ]] || die "missing ${SRC}/runtime"
[[ -x "${SRC}/bootstrap/oodac_pure_build" ]] || die "missing ${SRC}/bootstrap/oodac_pure_build"

CC=""
if is_compiler "${SRC}/oodac/oodac"; then
  CC="${SRC}/oodac/oodac"
elif is_compiler "${SRC}/oodac_bin"; then
  CC="${SRC}/oodac_bin"
elif [[ -x "${SRC}/bootstrap/seed/oodac" ]]; then
  say "rebuild compiler from seed (slow)"
  ( cd "${SRC}" && OODAC_BIN="${SRC}/bootstrap/seed/oodac" bash bootstrap/oodac_pure_build oodac/main.oo oodac/oodac )
  is_compiler "${SRC}/oodac/oodac" || die "seed rebuild did not write a compiler"
  CC="${SRC}/oodac/oodac"
else
  die "no compiler in checkout (need oodac/oodac, oodac_bin, or bootstrap/seed/oodac)"
fi
say "compiler ${CC}"

mkdir -p "${SRC}/bin"
if ! is_cli "${SRC}/bin/ooda"; then
  say "build CLI"
  ( cd "${SRC}" && OODA_SRC_ROOT="${SRC}" OODA_STD="${SRC}/std" OODAC_BIN="${CC}" OODA_COMPILER="${CC}" \
      "${CC}" build cli/main.oo bin/ooda )
fi
is_cli "${SRC}/bin/ooda" || die "CLI build did not write bin/ooda"
if is_compiler "${SRC}/bin/ooda"; then
  die "bin/ooda looks like the compiler (refusing to copy)"
fi

say "place toolchain under ${HOME_USER}"
mkdir -p "${OODA_HOME}/share/fixtures" "${OODA_HOME}/install" "${OODA_HOME}/oodac" \
  "${OODA_BIN}" "${OODA_CONFIG}" "${OODA_CACHE}/downloads"

cp -f "${SRC}/bin/ooda" "${OODA_BIN}/ooda"
cp -f "${CC}" "${OODA_BIN}/oodac"
cp -f "${SRC}/bin/ooda" "${OODA_BIN}/oo"
chmod +x "${OODA_BIN}/ooda" "${OODA_BIN}/oodac" "${OODA_BIN}/oo"

if is_cli "${OODA_BIN}/oodac"; then
  die "oodac on PATH looks like the CLI (refusing)"
fi
if is_compiler "${OODA_BIN}/ooda"; then
  die "ooda on PATH looks like the compiler (refusing)"
fi

rm -rf "${OODA_STD}"
cp -a "${SRC}/std" "${OODA_STD}"
rm -rf "${OODA_HOME}/runtime"
cp -a "${SRC}/runtime" "${OODA_HOME}/runtime"
cp -f "${CC}" "${OODA_HOME}/oodac/oodac"
chmod +x "${OODA_HOME}/oodac/oodac"
if [[ -f "${SRC}/fixtures/hello.oo" ]]; then
  cp -f "${SRC}/fixtures/hello.oo" "${OODA_HOME}/share/fixtures/hello.oo"
fi
if [[ -f "${SRC}/install/BOOTSTRAP_PIN" ]]; then
  PIN="$(tr -d ' \t\r\n' < "${SRC}/install/BOOTSTRAP_PIN")"
fi

cat > "${OODA_CONFIG}/env" <<EOF
# openOODA XDG env — source from your shell profile
export OODA_HOME="${OODA_HOME}"
export OODA_SRC_ROOT="${OODA_HOME}"
export OODA_STD="${OODA_STD}"
export OODA_CONFIG="${OODA_CONFIG}"
export OODA_CACHE="${OODA_CACHE}"
export PATH="${OODA_BIN}:\$PATH"
EOF

cat > "${OODA_HOME}/share/INSTALL_RECEIPT.txt" <<EOF
openOODA install receipt
version=${PIN}
source=host-script
os=Linux
arch=x86_64
oodac=${OODA_BIN}/oodac
ooda=${OODA_BIN}/ooda
EOF

say "pin ${PIN}"
say "ooda  ${OODA_BIN}/ooda"
say "oodac ${OODA_BIN}/oodac"
say "std   ${OODA_STD}"
say "next:"
echo "  . ${OODA_CONFIG}/env"
echo "  ooda version"
echo "  ooda run ${OODA_HOME}/share/fixtures/hello.oo"
say "PASSED"
