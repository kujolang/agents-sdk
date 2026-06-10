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

"$KUJO_BIN" test-run tests/no_network_harness_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
"$KUJO_BIN" test

echo "Offline no-network enforcement checks passed."
