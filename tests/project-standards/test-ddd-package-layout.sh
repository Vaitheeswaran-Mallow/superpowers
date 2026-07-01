#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
fail() { echo "FAIL: $1"; exit 1; }

LAYOUT=docs/standards/stacks/rails8/ddd/rails-package-layout.md
test -f "$LAYOUT" || fail "missing layout doc"
grep -q 'app/domains/' "$LAYOUT" || fail "missing app/domains"
grep -q 'interface/' "$LAYOUT" || fail "missing interface layer"
grep -q 'Zeitwerk' "$LAYOUT" || fail "missing zeitwerk"
grep -q 'ddd-first' "$LAYOUT" || fail "missing mode table"

echo "PASS: ddd package layout"
