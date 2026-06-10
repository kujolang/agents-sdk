# Public API Stability Review

Date: 2026-05-22

## Scope

Reviewed exported runtime surfaces under src/agents and root index exports for naming clarity, additive evolution, and contract stability.

## Public Surface Inventory

- Core contracts: src/agents/core_types.kujo
- Error contracts: src/agents/errors.kujo
- Event contracts: src/agents/events.kujo
- Runner APIs: src/agents/runner.kujo
- AI adapter boundary: src/agents/ai/adapter.kujo
- Tool contracts: src/agents/tools/registry.kujo
- Security contracts: src/agents/security/approval.kujo
- Session/memory contracts: src/agents/sessions/store.kujo, src/agents/memory/store.kujo
- Retrieval contracts: src/agents/retrieval/provider.kujo
- Handoff contracts: src/agents/handoffs/handoff.kujo
- Trace contracts: src/agents/tracing/sink.kujo
- Artifact contracts: src/agents/artifacts/store.kujo
- Budget contracts: src/agents/budgets/limits.kujo
- Streaming contracts: src/agents/streaming/events.kujo
- Integration boundaries: src/agents/integrations/adapters.kujo
- No-network fixture harness: src/agents/testing/no_network.kujo

## Stability Markers

- Stable-by-contract keys: result status, error kind, lifecycle event kind names, stream event kind names, tool approval decisions.
- Additive-only evolution target: result metadata maps, integration adapter payload extensions, optional budget/cost telemetry fields.
- Experimental surfaces: hosted/commercial integration payload metadata and adapter-specific extension fields.

## Review Outcome

- No breaking export renames introduced in this release pass.
- Contract tests cover deterministic result/event schema stability.
- Remaining risk is additive growth of integration metadata maps; this is documented and marked experimental.
