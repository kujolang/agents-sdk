# Agents SDK

Library-first agent workflow primitives for Agents SDK, built on top of the AI SDK.

Current status: foundational agent runtime primitives, offline fixtures, and contract coverage scaffolded.

## Quickstart

1. Use a pinned Agents SDK runtime binary for deterministic behavior:

```bash
export KUJO_BIN=/path/to/kujo/target/debug/kujo
```

2. Run the offline example smoke runner:

```bash
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
```

Expected output:

```json
{"approval_agent":{"ok":true,"requires_network":false,"status":"failed"},"artifact_agent":{"ok":true,"requires_network":false,"status":"completed"},"handoff_agent":{"ok":true,"requires_network":false,"status":"completed"},"hello_agent":{"ok":true,"requires_network":false,"status":"completed"},"retrieval_agent":{"ok":true,"requires_network":false,"status":"completed"},"tool_agent":{"ok":true,"requires_network":false,"status":"completed"},"traced_agent":{"ok":true,"requires_network":false,"status":"completed"}}
```

3. Run the full offline test suite:

```bash
"$KUJO_BIN" test
```

Agent/contributor notes: see `AGENTS.md` for canonical example labels, fixture boundaries, and search hygiene.

## Relationship to AI SDK

- [AI SDK](https://github.com/kujolang/ai-sdk/) owns provider calls, transport normalization, and provider-gated model behavior.
- Agents SDK builds higher-level agent workflows on top of those controlled boundaries.
- The bundled examples and tests default to offline fixtures so local validation does not require real provider keys.
- There is no separate user-facing CLI; use the library modules or bundled examples/tests.

## Architecture Boundary

The Agents SDK is intentionally runtime-focused and local-first:

- AI model/provider execution is delegated through `src/agents/ai/adapter.kujo` boundary callbacks.
- Core orchestration remains in the Agents SDK (`runner`, `tools`, `security`, `memory`, `retrieval`, `handoffs`, `tracing`, `artifacts`, `budgets`).
- Product-specific integrations (for example external provider adapters or workflow orchestrators) stay behind integration contracts instead of being hard-coded in core modules.

## Stability Notes

- Stable surface: contract constructors, runner/tool/security/session/memory/retrieval/handoff/trace/artifact/budget primitives, and integration adapter boundaries.
- Experimental surface: higher-level integration payload conventions that may evolve as upstream systems (for example Scout/Dispatch/Watchdog providers) add capabilities.
- Compatibility intent: preserve backwards-compatible contract keys where possible and introduce new fields additively.

## Contract Stability Statement

`tests/runner_result_event_contract_tests.kujo` asserts stable `AgentRunResult` top-level shape and validates lifecycle event payload contracts (success and failure scenarios) using deterministic runtime services.

## Core Type Contracts

`src/agents/core_types.kujo` provides baseline constructors and validators for:

- agent config and validation
- agent/message/step contracts
- run request, run context, and run result contracts
- supported message roles, step kinds, and run statuses

## Error Contracts

`src/agents/errors.kujo` provides the centralized error model with:

- stable `AgentErrorKind` values for normal runtime failure categories
- deterministic `create_agent_error` and `normalize_agent_error` helpers
- `create_error_result` for structured failed result payloads

## Runtime Event Contracts

`src/agents/events.kujo` provides:

- stable `AgentEventKind` values for runner lifecycle observability
- required event-field registry for schema checks
- deterministic event constructors and shape validation helpers

## Runtime Clock and ID Services

`src/agents/runtime/clock_ids.kujo` provides injectable runtime services for:

- deterministic `run-*`, `step-*`, and `evt-*` ID generation
- deterministic clock values for timestamp fields in tests
- fixed runtime service fixtures for contract/integration test scenarios

## Runtime Cancellation Token

`src/agents/runtime/cancellation.kujo` provides deterministic cancellation helpers for:

- normalized `CancellationToken` construction for manual and stage-targeted cancellation
- explicit `cancellation_requested` checks at runner loop boundaries
- callback-compatible cancellation predicate support for advanced runtime integrations

## AI SDK Adapter Boundary

`src/agents/ai/adapter.kujo` provides the integration boundary that:

- delegates chat and streaming calls to injected AI SDK callback functions
- maps normalized AI SDK responses into agent-level model result contracts via `to_agent_model_result`
- normalizes token/cost usage metadata for future budget enforcement via `extract_usage_metrics`
- enforces optional structured-output schema requirements with deterministic `structured_output_invalid` failures
- composes adapter and agent request hooks with dedupe guards via `build_observability_hooks`
- keeps provider/model logic outside the Agents SDK runtime

## Non-Streaming Runner

`src/agents/runner.kujo` provides a baseline non-stream runner that:

- validates agent config and builds run context
- composes model messages from instructions and user input
- invokes the AI adapter and records deterministic model/final steps
- applies bounded model retry policy handling with explicit retry counter metadata
- checks cancellation token boundaries before and after model execution
- rejects unknown requested tool names deterministically before model execution
- persists final output artifacts to an optional configured `ArtifactStore` and returns artifact references in `AgentRunResult.artifacts`
- enforces configured budget policies at lifecycle boundaries (before model, after model, after artifact, after memory) with deterministic `budget_exceeded` terminal results
- enforces elapsed-time deadlines using injected runtime clock services with deterministic `timeout` terminal results independent of provider/model timeout responses
- enforces explicit max-iteration termination with deterministic `max_iterations` terminal status when configured step ceilings are reached before completion
- emits run lifecycle events and returns stable completed/failed/cancelled run result contracts

## Tool Registry Contracts

`src/agents/tools/registry.kujo` provides first-class tool and registry contracts for:

- deterministic tool contract validation and normalization (`id`, `name`, schemas, permissions, risk, timeout)
- schema-level input validation with deterministic `tool_input_invalid` violations for missing required and unknown fields
- immutable registry operations for register, resolve, and list behavior
- timeout-aware tool execution wrappers with deterministic `tool_execution_failed` mapping for handler/runtime failures
- deterministic duplicate-name rejection and unknown-tool error mapping
- immutable metadata retrieval helpers for tool contract introspection
- structured `ToolExecutionContext` construction and invocation helpers carrying run/session/agent/cancellation/policy context
- approval gate enforcement before handler invocation with deterministic `approval_required` and `approval_denied` statuses when policies/providers block execution
- optional tool output sanitizer callback support with deterministic fallback-to-original output when sanitizer callbacks fail or reject output
- artifact-aware execution contexts via `artifact_handles` plus persisted handler-emitted artifact references when an `ArtifactStore` is provided

## Approval Policy Contracts

`src/agents/security/approval.kujo` provides deterministic approval policy primitives for:

- policy modes for always-allow, always-deny, write-tool, high-risk, and permission-based enforcement
- structured approval request and decision contracts for runner/tool integration boundaries
- deterministic policy evaluation outcomes (`allow`, `deny`, `require_approval`) with mode-specific metadata
- provider contracts for `ApprovalProvider` flows including `auto`, `deny_all`, and `manual_stub` strategies
- deterministic provider decision IDs and statuses (`approved`, `denied`, `pending`) for external/manual integration paths
- guardrail contracts with stage-aware evaluation for `before_model`, `after_model`, `before_tool`, `after_tool`, and `before_final_output`
- deterministic guardrail outcomes (`pass`, `warn`, `block`) for rule-level and policy-level evaluation paths
- built-in minimal guardrails for max input length, blocked terms, tool-risk blocking, and final-output size limits via `create_minimal_guardrail_policy`
- redaction policy hooks for event payloads, trace payloads, and tool IO with deterministic masked-field counts and configurable replacement rules
- memory write policy controls with scope/data-class registries and structured denial error mapping for restricted write paths

## Session Store Contracts

`src/agents/sessions/store.kujo` provides foundational session contracts for:

- `SessionId`, `SessionMessage`, `SessionState`, and `Session` constructors with normalized fields
- `SessionStore` interface shape covering create/get/update/list/delete operations
- explicit run-continuity wrappers for `save_run_state` and `get_run_state`
- deterministic `create_in_memory_session_store` factory with stable list ordering and run-state persistence helpers
- deterministic wrapper behavior that delegates to configured store callbacks

## Memory Store Contracts

`src/agents/memory/store.kujo` provides foundational memory abstractions for:

- `MemoryScope`, `MemoryProvenance`, `MemoryEntry`, and `MemoryQuery` contract constructors
- `MemoryQueryResult` contracts with provenance summaries and total-count metadata
- `MemoryStore` interface wrappers for `write`, `read`, `query`, and `delete`
- `create_noop_memory_store` for deterministic non-persistent operation paths
- `create_in_memory_memory_store` for scope-aware in-memory persistence across `session`, `user`, and `project` namespaces

## Runner Session/Memory Lifecycle

`src/agents/runner.kujo` includes lifecycle save points that can:

- restore prior session run-state at run start when a `session_store` is configured
- persist deterministic run-state snapshots on run start, cancellation, failure, and completion
- persist final output memory entries when a `memory_store` is configured
- expose session/memory persistence telemetry under run result metadata for integration diagnostics

## Retrieval Contracts

`src/agents/retrieval/provider.kujo` provides baseline retrieval contracts for:

- `RetrievalQuery`, `RetrievedDocument`, `RetrievalCitation`, `RetrievedContext`, and `RetrievalResult` payloads
- `RetrievalPolicy` options for enablement, document limits, and citation inclusion
- `RetrievalProvider` interface wrappers and normalized retrieve responses via `retrieval_provider_retrieve`
- `create_mock_retrieval_provider` for deterministic seeded retrieval responses in no-network tests

## Retrieval Lifecycle Injection

`src/agents/runner.kujo` supports optional pre-model retrieval context injection when retrieval is enabled via agent policy or run options and a retrieval provider is configured:

- resolves retrieval config from options, run request, or `agent.policy.retrieval`
- queries the retrieval provider before model invocation and builds a deterministic retrieval context message
- appends retrieved context as a system message before the model step
- records retrieval injection state/result metadata under `result.metadata.retrieval`
- propagates normalized citation references (citation ID, document ID, path, score) into `result.metadata.retrieval`, `result.artifacts[*].metadata`, and `run_completed` event payloads with deterministic document-derived fallback references

Testing guidance: Use `create_mock_retrieval_provider` for integration tests so retrieval-enriched flows stay deterministic and offline by default.

## Handoff Contracts

`src/agents/handoffs/handoff.kujo` provides foundational handoff contracts for:

- `HandoffTarget` and `HandoffPolicy` constructors
- `HandoffLoopState` depth/visited-target metadata for loop and recursion safety checks
- `HandoffRequest` payloads linking source agent, target, reason, and loop state, including `create_handoff_request_from_parts` for explicit request assembly
- `HandoffResult` payloads with deterministic status normalization and outcome metadata

## Handoff Execution

`src/agents/runner.kujo` supports explicit handoff execution to configured target agents:

- resolves handoff intent from run options, run request fields, request metadata, and agent policy hints
- resolves target agents through configured handoff registries
- appends deterministic handoff metadata under `result.metadata.handoff` (`requested`, `executed`, request payload, and normalized result)
- invokes the target agent as a nested run and merges target output text into the parent run output when handoff succeeds
- returns structured `handoff_failed` errors when target resolution fails or handoff target run is not completed

## Trace Sink Contracts

`src/agents/tracing/sink.kujo` provides baseline trace contracts for:

- `TraceEvent` constructors with deterministic `trc-*` identifiers and injected clock timestamps
- required-field validation helpers for stable trace schema checks
- `TraceSink` interface wrappers for append/list operations with deterministic `not_implemented` mapping when callbacks are absent
- deterministic `create_in_memory_trace_sink` and `reset_in_memory_trace_sink` helpers for offline append/list/filter test paths

## Artifact Store Contracts

`src/agents/artifacts/store.kujo` provides baseline artifact contracts for:

- stable `ArtifactKind` values and `ArtifactId` constructors
- normalized `Artifact` payloads with producer IDs, timestamps, metadata, and byte estimates
- `ArtifactStore` interface wrappers for create/get/list operations with deterministic `not_implemented` mapping
- deterministic `create_in_memory_artifact_store` and `reset_in_memory_artifact_store` helpers for offline typed output persistence and filtered listing

## Budget Contracts

`src/agents/budgets/limits.kujo` provides baseline budget and usage contracts for:

- stable budget counter and limit key registries covering model/tool calls, steps, handoffs, memory operations, artifact bytes, tokens, cost, and elapsed time
- normalized `AgentBudget`, `BudgetUsage`, and `BudgetLimitPolicy` constructors
- deterministic `increment_budget_usage` helper for counter accumulation
- deterministic `evaluate_budget_limits` contract that reports `within_limits`, `budget_exceeded`, or `exceeded_observe` with structured exceeded-limit details

## Integration Adapter Contracts

`src/agents/integrations/adapters.kujo` provides integration boundaries for:

- external tool-provider adapters (`create_external_tool_provider_adapter`) for MCP/MCT-style catalog and invocation mapping
- Dispatch hooks (`create_dispatch_integration_hooks`) for step execution and workflow-as-tool invocation
- Watchdog trace transformation adapters (`create_watchdog_trace_adapter`) for core-to-watchdog event mapping
- Scout code-context providers (`create_scout_code_context_provider`) plus deterministic retrieval-enrichment mapping (`map_scout_context_to_retrieval_enrichment`) so Scout intelligence can feed retrieval/context flows without introducing a hard core dependency

Hosted/commercial product capabilities must remain outside core runtime modules and integrate through adapters documented in `docs/INTEGRATION_BOUNDARIES.md`.

## No-Network Test Fixtures

`src/agents/testing/no_network.kujo` provides deterministic fixture builders for offline-first test and example flows:

- `create_no_network_model_adapter` for mock chat and stream responses
- `create_no_network_retrieval_provider` for seeded retrieval context/citation payloads
- `create_no_network_tool_fixture` for deterministic offline tool behavior
- `create_no_network_harness` for a composed model/retrieval/tool fixture bundle

## Module Map

- `src/agents/index.kujo` (public index exports)
- `src/agents/core_types.kujo`
- `src/agents/errors.kujo`
- `src/agents/events.kujo`
- `src/agents/runner.kujo`
- `src/agents/tools/registry.kujo`
- `src/agents/security/approval.kujo`
- `src/agents/sessions/store.kujo`
- `src/agents/memory/store.kujo`
- `src/agents/retrieval/provider.kujo`
- `src/agents/handoffs/handoff.kujo`
- `src/agents/tracing/sink.kujo`
- `src/agents/artifacts/store.kujo`
- `src/agents/budgets/limits.kujo`
- `src/agents/streaming/events.kujo`
- `src/agents/integrations/adapters.kujo`
- `src/agents/runtime/clock_ids.kujo`
- `src/agents/runtime/cancellation.kujo`
- `src/agents/ai/adapter.kujo`

## Quick Validation

Core runner integration coverage in `tests/run_basic_runner_tests.kujo` includes: basic run success, model-emitted tool-call execution, approval-denied tool execution, stream guardrail terminal blocking, retrieval context injection, explicit handoff execution, and deterministic budget/iteration stop paths.

Extended docs:

- docs/ARCHITECTURE.md
- docs/DEVELOPER_GUIDE.md
- docs/PRIMITIVES_REFERENCE.md
- docs/SECURITY_PRODUCTION_GUIDE.md
- docs/INTEGRATION_BOUNDARIES.md
- docs/EXAMPLES.md
- docs/PUBLIC_API_STABILITY.md
- docs/RELEASE_NOTES.md
- docs/FINAL_ACCEPTANCE_REPORT.md

```bash
"$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
"$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v
"$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v
"$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v
"$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v
"$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v
"$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v
"$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v
"$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v
"$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v
"$KUJO_BIN" test-run tests/retrieval_provider_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/handoff_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/trace_sink_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/artifact_store_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/budget_limits_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v
"$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/no_network_harness_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/runner_result_event_contract_tests.kujo -v
"$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
bash scripts/ci_no_network_enforcement.sh
```
