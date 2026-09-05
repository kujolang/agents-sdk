#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

KUJO_BIN="${KUJO_BIN:-kujo}"

unset OPENAI_API_KEY
unset ANTHROPIC_API_KEY
unset GOOGLE_API_KEY
unset AZURE_OPENAI_API_KEY
unset COHERE_API_KEY

mkdir -p .tmp
LOG_DIR="$(mktemp -d "$ROOT_DIR/.tmp/offline-checks.XXXXXX")"
checks=0
failures=0

run_check() {
  local label="$1"
  shift
  checks=$((checks + 1))
  if "$@" > "$LOG_DIR/$label.log" 2>&1; then
    return 0
  else
    local result=$?
    failures=$((failures + 1))
    printf 'FAIL %s (exit %s): %s\n' "$label" "$result" "$LOG_DIR/$label.log"
  fi
}

# Fixture snapshots do not execute test blocks. Run every contract explicitly.
# Host effects needed for local persistence are allowed; network/AI/process are not.
for test_file in tests/*_tests.kujo; do
  run_check "${test_file##*/}" "$KUJO_BIN" test-run "$test_file" -v \
    --untrusted --allow-fs-read --allow-fs-write --allow-fs-delete --allow-clock
done
run_check fixtures "$KUJO_BIN" test
printf 'Offline checks: %s total, %s failed. Logs: %s\n' "$checks" "$failures" "$LOG_DIR"
test "$failures" -eq 0
