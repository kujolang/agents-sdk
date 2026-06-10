# Release Notes

## Summary

This release delivers a library-first, provider-gated Agents SDK runtime with deterministic no-network defaults, structured contracts, and validated example coverage.

## Highlights

- Deterministic runner lifecycle and terminal result contracts.
- Typed tool, approval, guardrail, memory, session, retrieval, handoff, trace, artifact, budget, and streaming primitives.
- Adapter boundaries for MCP/MCT, Dispatch, Watchdog, Scout, and hosted/commercial extension layers.
- Offline-first examples with smoke coverage.

## Validation Evidence

- "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v (pass)
- "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter (pass)
- bash scripts/ci_no_network_enforcement.sh (pass)
- "$KUJO_BIN" test (pass 23/23)

## Known Limitations

- Package status remains experimental while integration metadata expansion remains additive and intentionally flexible.
