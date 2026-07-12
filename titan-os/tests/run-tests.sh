#!/bin/sh
# TitanOS test suite — no root, no network. Safe to run in CI.
# Lints every shell script and exercises titan-mode / winstall logic in a
# sandbox so we know the tools behave before they ever hit a real ISO.
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
BIN="config/includes.chroot/usr/local/bin"
fails=0

ok()   { echo "  PASS $1"; }
bad()  { echo "  FAIL $1" >&2; fails=$((fails + 1)); }

echo "== 1. shellcheck (if available) =="
if command -v shellcheck >/dev/null 2>&1; then
	for f in build.sh tests/run-tests.sh "$BIN/titan-mode" "$BIN/winstall" "$BIN/titan-mem" \
		"$BIN/titan-cap" config/hooks/normal/9000-titan-setup.hook.chroot; do
		if shellcheck -s sh --severity=warning "$f" >/dev/null 2>&1; then ok "shellcheck $f"; else
			shellcheck -s sh --severity=warning "$f" || true; bad "shellcheck $f"; fi
	done
else
	echo "  SKIP shellcheck not installed"
fi

echo "== 2. config validates =="
if sh build.sh --check >/dev/null 2>&1; then ok "build.sh --check"; else bad "build.sh --check"; fi

echo "== 3. titan-mode behaviour =="
sh "$BIN/titan-mode" --help  | grep -q "gaming" && ok "help mentions gaming"  || bad "help gaming"
sh "$BIN/titan-mode" status  | grep -qi "mode"   && ok "status prints mode"    || bad "status"
if sh "$BIN/titan-mode" bogus >/dev/null 2>&1; then bad "bad arg should fail"; else ok "rejects bad arg"; fi

echo "== 4. winstall behaviour (sandboxed) =="
sandbox="$(mktemp -d)"
export HOME="$sandbox" XDG_DATA_HOME="$sandbox/data"
sh "$BIN/winstall" --help | grep -q "prefix" && ok "help mentions prefix" || bad "winstall help"
sh "$BIN/winstall" --list | grep -qi "no prefixes" && ok "empty list message" || bad "winstall list"
if sh "$BIN/winstall" /no/such/file.exe >/dev/null 2>&1; then bad "missing file should fail"; else ok "rejects missing file"; fi
if sh "$BIN/winstall" --bogus >/dev/null 2>&1; then bad "bad option should fail"; else ok "rejects bad option"; fi
rm -rf "$sandbox"

echo "== 5. titan-mem behaviour =="
sh "$BIN/titan-mem" | grep -qi "free for games" && ok "reports free-for-games" || bad "titan-mem report"
TITAN_OS_BUDGET_MB=999999 sh "$BIN/titan-mem" --budget >/dev/null 2>&1 && ok "budget check passes when generous" || bad "titan-mem budget"
if TITAN_OS_BUDGET_MB=0 sh "$BIN/titan-mem" --budget >/dev/null 2>&1; then bad "budget 0 should fail"; else ok "budget check fails when tiny"; fi

echo "== 6. titan-cap ceiling math =="
# The cap = 20% of RAM, clamped to [2048, 5120] MB, never above real RAM.
check_cap() { # $1=total_mb  $2=expected_mb  $3=label
	got="$(TITAN_TOTAL_MB="$1" sh "$BIN/titan-cap" compute)"
	if [ "$got" = "$2" ]; then ok "$3 ($1 MB -> $got MB)"; else bad "$3 expected $2 got $got"; fi
}
check_cap 2048 2048 "2 GB machine capped at 2 GB"
check_cap 8192 2048 "8 GB machine floors at 2 GB"
check_cap 24576 4915 "24 GB machine ~4.8 GB"
check_cap 32768 5120 "32 GB machine ceils at 5 GB"
sh "$BIN/titan-cap" show | grep -qi "ceiling" && ok "show prints ceiling" || bad "titan-cap show"
if sh "$BIN/titan-cap" set >/dev/null 2>&1; then bad "set without size should fail"; else ok "set requires size"; fi

echo
if [ "$fails" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "$fails TEST(S) FAILED" >&2; exit 1; fi
