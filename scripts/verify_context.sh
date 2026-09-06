#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
KUJO_BIN="${KUJO_BIN:-kujo}"
mkdir -p .tmp/context-evaluation
for test_file in tests/context_*_tests.kujo; do
  "$KUJO_BIN" test-run "$test_file" --untrusted --allow-fs-read --allow-fs-write --allow-fs-delete --allow-clock > ".tmp/context-evaluation/${test_file##*/}.log" 2>&1 || {
    cat ".tmp/context-evaluation/${test_file##*/}.log"
    exit 1
  }
done
"$KUJO_BIN" run scripts/context_evaluation.kujo --interpreter --untrusted --allow-fs-read --allow-fs-write -- --sources
for source in .tmp/context-evaluation/*-current.kujo .tmp/context-evaluation/*-optimized.kujo; do
  "$KUJO_BIN" run "$source" --untrusted > "${source}.vm.log" 2> "${source}.vm.stderr"
  "$KUJO_BIN" run "$source" --interpreter --untrusted > "${source}.interpreter.log" 2> "${source}.interpreter.stderr"
  cmp "${source}.vm.log" "${source}.interpreter.log"
done
"$KUJO_BIN" run scripts/context_evaluation.kujo --interpreter --untrusted --allow-fs-read -- --report > .tmp/context-evaluation/report.json
printf 'Context contracts, 20 paired repetitions, and 14 VM/interpreter source executions passed.\n'
