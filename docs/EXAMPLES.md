# Deterministic Examples

All examples are offline-first and rely on deterministic fixture adapters.

Prioritize copyable examples over tests: examples should model the most token-efficient idioms we want agents to imitate.

## Canonical Runnable Examples

- examples/hello_agent.kujo
- examples/tool_agent.kujo
- examples/approval_agent.kujo
- examples/retrieval_agent.kujo
- examples/handoff_agent.kujo
- examples/traced_agent.kujo
- examples/artifact_agent.kujo
- examples/examples_smoke_runner.kujo

## Support Files

- examples/support.kujo provides shared offline example helpers and is not a standalone demo.
- Use support helpers for repeated no-network result envelopes and mock model response boilerplate, while keeping each example's SDK feature setup visible.
- tests/*.out files are expected-output fixtures, not copyable example style.

## Expected Smoke Output

`examples/examples_smoke_runner.kujo` prints:

```json
{"approval_agent":{"ok":true,"requires_network":false,"status":"failed"},"artifact_agent":{"ok":true,"requires_network":false,"status":"completed"},"handoff_agent":{"ok":true,"requires_network":false,"status":"completed"},"hello_agent":{"ok":true,"requires_network":false,"status":"completed"},"retrieval_agent":{"ok":true,"requires_network":false,"status":"completed"},"tool_agent":{"ok":true,"requires_network":false,"status":"completed"},"traced_agent":{"ok":true,"requires_network":false,"status":"completed"}}
```

## Validate Example Smoke Coverage

```bash
export KUJO_BIN=kujo
"$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
```

## Notes

- approval_agent demonstrates deterministic approval_denied handling.
- traced_agent writes a synthetic run_completed trace event to in-memory sink.
- artifact_agent demonstrates artifact persistence and listing through in-memory artifact store.
- retrieval_agent demonstrates retrieval context injection without network access.
