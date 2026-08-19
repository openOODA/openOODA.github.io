#!/bin/sh
# Wave 0+1 content check. Reads shipped files on disk. Exit 1 on any miss.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
if [ -f "$ROOT/../registry/index.html" ]; then
  REG="$(CDPATH= cd -- "$ROOT/../registry" && pwd)"
else
  REG=""
fi

fail=0
ok() { printf 'PASS %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

need() {
  if [ ! -f "$1" ]; then
    bad "missing file: $1"
    return 1
  fi
  return 0
}

# 1. These paths must not exist relative to the github.io repo root.
gone() {
  if [ -e "$ROOT/$1" ]; then
    bad "must not exist: $1"
  else
    ok "absent $1"
  fi
}

gone styles.css
gone site.css
gone assets/bg.jpg
gone logo_badge.svg
gone openooda_icon_only.svg
gone openooda_logo_dark.svg
gone update_index.oo
gone update_titles.oo

# 2. guide/index.html PAGES array must not include Research.oot
GUIDE="$ROOT/guide/index.html"
if need "$GUIDE"; then
  pages=$(awk '
    /PAGES[[:space:]]*=/ { grab=1 }
    grab { buf = buf $0 ORS }
    grab && /\]/ { print buf; exit }
  ' "$GUIDE")
  if [ -z "$pages" ]; then
    bad "guide/index.html has no PAGES array"
  elif printf '%s' "$pages" | grep -q 'Research\.oot'; then
    bad "PAGES array includes Research.oot"
  else
    ok "PAGES array has no Research.oot"
  fi
fi

# 3. empty-hash fallback must be Use.oot (not Home.oot)
if [ -f "$GUIDE" ]; then
  if grep -qE 'location\.hash \|\| "#Home\.oot"' "$GUIDE" \
     || grep -qE 'replace\("#Home\.oot"\)' "$GUIDE" \
     || grep -qE '\? h : "Home\.oot"' "$GUIDE"; then
    bad "empty-hash fallback is Home.oot"
  elif grep -q 'location.hash || "#Use.oot"' "$GUIDE" \
     && grep -q '? h : "Use.oot"' "$GUIDE" \
     && grep -q 'replace("#Use.oot")' "$GUIDE"; then
    ok "empty-hash fallback is Use.oot"
  else
    bad "empty-hash fallback is not Use.oot"
  fi
fi

# 4. guide/Home.oot: no load_notes, no greet("World"), no command catalog table
HOME="$ROOT/guide/Home.oot"
if need "$HOME"; then
  if grep -q 'load_notes' "$HOME"; then
    bad "Home.oot contains load_notes"
  else
    ok "Home.oot has no load_notes"
  fi

  if grep -q 'greet("World")' "$HOME"; then
    bad 'Home.oot contains greet("World")'
  else
    ok 'Home.oot has no greet("World")'
  fi

  table=$(awk '
    BEGIN { cmd = 0; c=0; b=0; r=0; t=0; be=0; d=0; o=0 }
    /^[[:space:]]*\|/ {
      if ($0 ~ /^[[:space:]]*\|[[:space:]]*:?-/) next
      if ($0 ~ /^[[:space:]]*\|[[:space:]]*`[A-Za-z0-9_-]+`/) {
        cmd++
        if ($0 ~ /`check`/) c=1
        if ($0 ~ /`build`/) b=1
        if ($0 ~ /`run`/) r=1
        if ($0 ~ /`test`/) t=1
        if ($0 ~ /`bench`/) be=1
        if ($0 ~ /`dump`/) d=1
        if ($0 ~ /`outline`/) o=1
      }
    }
    END {
      if (cmd >= 10) { print "ten"; exit }
      if (c && b && r && t && be && d && o) { print "catalog"; exit }
      print "ok"
    }
  ' "$HOME")
  if [ "$table" = "catalog" ]; then
    bad "Home.oot has a command table with check/build/run/test/bench/dump/outline"
  elif [ "$table" = "ten" ]; then
    bad "Home.oot has a markdown table with 10+ command rows"
  else
    ok "Home.oot has no long command table"
  fi
fi

# 5. Door, guide, store, both 404s: visible nav label store; href is registry
nav_store() {
  label="$1"
  f="$2"
  if [ -z "$f" ] || [ ! -f "$f" ]; then
    bad "nav store missing file: $label"
    return
  fi
  if grep -q '>store</a>' "$f" \
     && grep -Eq '<a[^>]*href="https://registry\.openooda\.org/?"[^>]*>store</a>' "$f"; then
    ok "nav store label: $label"
  else
    bad "nav store label missing: $label"
  fi
}

nav_store "door" "$ROOT/index.html"
nav_store "guide" "$ROOT/guide/index.html"
nav_store "store" "${REG:+$REG/index.html}"
nav_store "door-404" "$ROOT/404.html"
nav_store "store-404" "${REG:+$REG/404.html}"

# 6. registry/index.html title/description must not contain installable
if [ -z "$REG" ]; then
  bad "missing file: registry/index.html"
elif need "$REG/index.html"; then
  if grep -iE '<title>[^<]*installable' "$REG/index.html" >/dev/null \
     || grep -iE 'name="description"[^>]*installable|installable[^>]*name="description"' "$REG/index.html" >/dev/null \
     || grep -iE 'property="og:title"[^>]*installable|installable[^>]*property="og:title"' "$REG/index.html" >/dev/null \
     || grep -iE 'property="og:description"[^>]*installable|installable[^>]*property="og:description"' "$REG/index.html" >/dev/null; then
    bad "registry title/description contains installable"
  else
    ok "registry title/description has no installable"
  fi
fi

# 7. index.html Tokens details has open
DOOR="$ROOT/index.html"
if need "$DOOR"; then
  if awk '
    /<details[^>]*class="drop"[^>]*[[:space:]]open/ { open=1; next }
    /<details[^>]*[[:space:]]open[^>]*class="drop"/ { open=1; next }
    open && /<summary>Tokens<\/summary>/ { found=1; exit }
    open && /<summary>/ { open=0 }
    /<details[^>]*class="drop"[^>]*[[:space:]]open[^>]*>.*<summary>Tokens<\/summary>/ { found=1; exit }
    END { exit found ? 0 : 1 }
  ' "$DOOR"; then
    ok 'Tokens details is <details class="drop" open>'
  else
    bad "Tokens details is not open"
  fi
fi

# 8. index.html contains the first-machine host script command
if [ -f "$DOOR" ]; then
  if grep -Fq 'curl -fsSL https://openooda.org/install | bash' "$DOOR"; then
    ok "door contains curl -fsSL https://openooda.org/install | bash"
  else
    bad "door missing curl -fsSL https://openooda.org/install | bash"
  fi
fi
if [ -f "$ROOT/install" ]; then
  if head -n 1 "$ROOT/install" | grep -Fq '/usr/bin/env bash'; then
    ok "install is a host bash script"
  else
    bad "install is not a host bash script"
  fi
else
  bad "missing install"
fi

# 9. After the install copy button, next element is Tokens details.
#    No lecture <p> between install and first drop.
if [ -f "$DOOR" ]; then
  drop=$(awk '
    BEGIN { out = "missing" }
    /id="copy"/ { after=1; next }
    after && /<p([ >]|$)/ { out = "p"; exit }
    after && /<details/ {
      if ($0 ~ /class="drop"/ && $0 ~ /(^|[[:space:]])open([[:space:]>]|$)/) {
        if ($0 ~ /<summary>Tokens<\/summary>/) { out = "ok"; exit }
        pending=1
        next
      }
      out = "not-tokens"
      exit
    }
    pending && /<summary>Tokens<\/summary>/ { out = "ok"; exit }
    pending && /<summary>/ { out = "not-tokens"; exit }
    END { print out }
  ' "$DOOR")
  if [ "$drop" = "ok" ]; then
    ok "Tokens details follows install copy button"
  elif [ "$drop" = "p" ]; then
    bad "lecture <p> between install copy button and first drop"
  else
    bad "Tokens details does not follow install copy button"
  fi
fi

if [ "$fail" -eq 0 ]; then
  printf 'ALL PASS\n'
  exit 0
fi
printf 'SOME FAILED\n'
exit 1
