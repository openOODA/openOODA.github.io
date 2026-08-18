#!/bin/sh
# Assert mail row on door/guide/404, absent on store, pin line unchanged.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
REG="/home/jeryd/Projects/openOODA/registry"
fail=0
ok() { printf 'PASS %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

has_form() {
  if grep -q 'collect.openooda.org/v1/emails' "$1" && grep -q 'id="mail"' "$1" && grep -q 'We store the address.' "$1"; then
    ok "mail row: $2"
  else
    bad "mail row missing: $2"
  fi
}

has_form "$ROOT/index.html" door
has_form "$ROOT/guide/index.html" guide
has_form "$ROOT/404.html" "door-404"

if grep -q 'collect.openooda.org' "$REG/index.html" || grep -q 'id="mail"' "$REG/index.html"; then
  bad "store has collect form"
else
  ok "store has no collect form"
fi

if grep -q 'curl -fsSL https://openooda.org/install | oo' "$ROOT/index.html"; then
  ok "pin command unchanged"
else
  bad "pin command missing"
fi

if awk '
  /<div class="install">/ { in_inst=1 }
  in_inst && /<\/div>/ { in_inst=0; after=1; next }
  after && /<details class="drop" open>/ { exit 0 }
  after && /<p[ >]/ { exit 1 }
' "$ROOT/index.html"; then
  ok "no lecture under pin"
else
  bad "lecture under pin"
fi

if grep -q 'subscribe\|newsletter\|we emailed' "$ROOT/index.html" "$ROOT/guide/index.html" "$ROOT/404.html"; then
  bad "forbidden subscribe copy"
else
  ok "no newsletter copy"
fi

if [ "$fail" -eq 0 ]; then
  printf 'ALL PASS\n'
  exit 0
fi
printf 'SOME FAILED\n'
exit 1
