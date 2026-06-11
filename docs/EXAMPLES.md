# Deterministic Examples

All examples are offline-first and rely on deterministic fixture adapters.

## Example Index

- examples/hello_agent.kujo
- examples/tool_agent.kujo
- examples/approval_agent.kujo
- examples/retrieval_agent.kujo
- examples/handoff_agent.kujo
- examples/traced_agent.kujo
- examples/artifact_agent.kujo
- examples/examples_smoke_runner.kujo

## Validate Example Smoke Coverage

- export KUJO_BIN=/path/to/kujo/target/debug/kujo
- "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
- "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter

## Notes

- approval_agent demonstrates deterministic approval_denied handling.
- traced_agent writes a synthetic run_completed trace event to in-memory sink.
- artifact_agent demonstrates artifact persistence and listing through in-memory artifact store.
- retrieval_agent demonstrates retrieval context injection without network access.
