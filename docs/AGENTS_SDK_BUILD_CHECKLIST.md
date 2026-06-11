# Agents SDK Build Checklist

## 1. Goal
Build a library-first, provider-gated Agents SDK that reuses the existing AI SDK for model/provider primitives and adds deterministic runtime primitives for agents, tools, sessions, memory, approvals, guardrails, tracing, artifacts, budgets, handoffs, streaming, and integration hooks.

## 2. Repository Assessment Summary
Assessment date: 2026-05-22

Findings:
- The target repository for Agents SDK is currently empty, so foundational module layout, package metadata, docs, and tests must be created.
- Agents SDK AI SDK already provides normalized chat, streaming, embeddings, provider presets, retries, timeout controls, budget-related knobs, and structured error contracts.
- Agents SDK AI SDK follows explicit exported function contracts from `src/` modules and deterministic normalized result shapes.
- Agents SDK AI SDK uses checklist-driven execution and contract-oriented tests with offline fixtures by default.
- Dispatch already contains agent/workflow concepts and trace state handling that should inform interface compatibility, but Agents SDK must remain a separate reusable layer.
- RAG repository already has retrieval and citation shapes that can be adapted through interface boundaries instead of direct hard dependencies.
- Scout repository is currently a single-runtime entrypoint and should be integrated through adapter interfaces (code context providers), not hard links.
- Watchdog repository expects stable trace/event contracts and can consume sinks/adapters once interfaces are defined.

Constraints from assessment:
- Do not duplicate AI SDK provider/model/embeddings/streaming implementations.
- Keep all runtime failure paths structured and deterministic.
- Keep tests local and no-network by default.
- Keep module boundaries explicit for future hosted/commercial layers to consume without forks.

## 3. Existing AI SDK Integration Findings
Confirmed reusable AI SDK primitives:
- Client/provider creation and capability checks.
- Chat completion and streaming completion entrypoints.
- Embeddings entrypoint.
- Structured output schema option support.
- Retry, timeout, and observability hooks.
- Normalized success/error contracts with stable keys.
- Token usage and optional governance metadata fields.

Integration rules for Agents SDK:
- Agents SDK must call AI SDK exports for model interactions.
- Agents SDK must not define provider-specific logic.
- Agents SDK must normalize agent-level results around AI SDK normalized responses.
- Agent streaming must wrap AI SDK streaming into typed agent runtime events.
- Token/cost budget accounting must consume AI SDK usage metadata when available.

## 4. Architecture Decision Summary
Decisions:
- Use `src/` as canonical implementation root with explicit package exports.
- Separate interface modules from in-memory/default implementations.
- Implement a deterministic `AgentRunner` loop first in non-streaming mode, then add typed streaming mode.
- Use adapter boundaries for external systems (MCP/MCT, Dispatch, Watchdog, Scout, RAG) with no hard runtime dependency in core modules.
- Keep default runtime local-first and synchronous unless explicitly configured for stream/cancellation.
- Represent all major lifecycle actions as structured events with stable event kinds.
- Keep error kinds centralized and test-covered.

Proposed initial module map:
- `src/agents/core_types.kujo`
- `src/agents/errors.kujo`
- `src/agents/events.kujo`
- `src/agents/runner.kujo`
- `src/agents/tools/*.kujo`
- `src/agents/security/*.kujo`
- `src/agents/sessions/*.kujo`
- `src/agents/memory/*.kujo`
- `src/agents/retrieval/*.kujo`
- `src/agents/handoffs/*.kujo`
- `src/agents/tracing/*.kujo`
- `src/agents/artifacts/*.kujo`
- `src/agents/budgets/*.kujo`
- `src/agents/streaming/*.kujo`
- `src/agents/integrations/*.kujo`

## 5. Status Legend
- Todo: Not started.
- In Progress: Currently being implemented.
- Done: Implemented, validated, and documented.
- Blocked: Cannot proceed due to dependency or external blocker.

## 6. How Agents Must Work This Checklist
Execution protocol:
1. Select the first unchecked actionable item in top-to-bottom order.
2. Complete exactly one actionable item per loop unless it is blocked.
3. Before editing, create a concise todo list for the selected item.
4. Inspect only files needed for the selected item.
5. Add or update tests first when practical.
6. Implement the smallest complete change for that item.
7. Run smallest relevant validation commands for that item family.
8. Update docs only when directly required by the selected item.
9. Mark item complete only after implementation, tests, and docs are finished.
10. Add a Work Log entry using the Completion Template.
11. If blocked, keep item unchecked and append a blocker note under that item.
12. Continue to the next unchecked item only when current item is done or blocked.

Checklist-first rule:
- This file is the source of truth for sequencing and completion status.
- Do not perform broad implementation outside the currently selected item.

## 7. Actionable Backlog (Grouped by Item Family)

### ARCH-001 Create module layout and package exports
- [x] Create the initial `src/agents` module tree and package export map so all public Agents SDK entrypoints resolve deterministically.
Dependencies: None.
Implementation details: Add package metadata, export stubs, and compatibility aliases only where necessary.
Validation: Module load/build check and public export smoke test.
Docs: Add module map to README when created.

### ARCH-002 Define core agent runtime types
- [x] Implement core public type contracts for agent identity, config, request, context, steps, events, statuses, and run results in a dedicated core module.
Dependencies: ARCH-001.
Implementation details: Include `Agent`, `AgentConfig`, `AgentRunRequest`, `AgentRunResult`, `AgentRunStatus`, `AgentStep`, and message role kinds.
Validation: Unit tests validating default values and required field guards.
Docs: Add type overview section.

### ARCH-003 Define deterministic error model and error kinds
- [x] Implement centralized `AgentError` and `AgentErrorKind` contracts with stable structured payload fields for all normal failure paths.
Dependencies: ARCH-002.
Implementation details: Include all required error kinds from specification and normalization helpers.
Validation: Unit tests mapping representative failures to expected error kinds.
Docs: Add error model table.

### ARCH-004 Define runtime event kind registry
- [x] Implement stable `AgentEventKind` and event payload shape contracts for lifecycle observability across model, tool, guardrail, memory, handoff, artifact, and completion paths.
Dependencies: ARCH-002.
Implementation details: Event constants and payload helper constructors with deterministic fields.
Validation: Contract tests for required event keys and kind values.
Docs: Add event taxonomy reference.

### ARCH-005 Add clock and id generator abstraction
- [x] Introduce injectable clock and id-generator interfaces so run IDs, timestamps, and step IDs are deterministic in tests.
Dependencies: ARCH-002.
Implementation details: Provide default runtime implementation and deterministic test fake.
Validation: Unit tests verifying deterministic outputs under fake clock/id sources.
Docs: Brief testing note.

### AI-001 Add AI SDK adapter boundary module
- [x] Implement an adapter that maps Agents SDK model requests to AI SDK `chat_completion` and `chat_completion_stream` calls without reimplementing provider logic.
Dependencies: ARCH-001.
Implementation details: Adapter functions for non-stream and stream with options passthrough.
Validation: Unit tests with fake AI SDK transport callbacks.
Docs: Document adapter boundary and non-goals.

### AI-002 Map AI SDK normalized responses into agent model results
- [x] Convert AI SDK normalized success and error payloads into agent-run internal model result contracts while preserving provider metadata and usage fields.
Dependencies: AI-001, ARCH-003.
Implementation details: Preserve request_id, model, usage, error code/message, and retryable hints.
Validation: Contract tests for success, provider error, and timeout-like error mapping.
Docs: Update response mapping doc.

### AI-003 Integrate structured output schema passthrough
- [x] Support optional agent final-output schema by forwarding structured-output options to AI SDK and returning deterministic `structured_output_invalid` errors on mismatch.
Dependencies: AI-002.
Implementation details: Schema option mapping and validation result bridge.
Validation: Tests for valid schema output and invalid output failure paths.
Docs: Structured output usage section.

### AI-004 Integrate AI SDK usage metadata for budgets
- [x] Consume AI SDK usage/token/cost metadata fields where available so budget accounting can enforce token and cost limits without provider-specific code.
Dependencies: AI-002.
Implementation details: Parse usage.input_tokens/output_tokens/total_tokens and optional cost hints.
Validation: Unit tests for missing and present usage metadata.
Docs: Budget metadata note.

### AI-005 Preserve AI SDK observability hooks compatibility
- [x] Expose a pass-through hook strategy so agent runtime instrumentation can coexist with AI SDK request lifecycle hooks without double counting.
Dependencies: AI-001.
Implementation details: Hook wrapper strategy and observability event merge behavior.
Validation: Tests confirming hook invocation order and event counts.
Docs: Observability integration note.

### RUN-001 Implement basic non-stream AgentRunner loop
- [x] Implement deterministic non-stream run loop that takes an `Agent` plus `AgentRunRequest`, calls model, processes steps, and returns stable `AgentRunResult`.
Dependencies: ARCH-002, AI-002.
Implementation details: Initialize context, track step index, append messages, stop on final output.
Validation: Integration test for successful basic run with mock model adapter.
Docs: Runner lifecycle overview.

### RUN-002 Implement deterministic stop conditions
- [x] Enforce run termination on success, failure, cancellation, max-iterations, timeout, and budget exhaustion with explicit final status values.
Dependencies: RUN-001, BUDGET-001.
Implementation details: Single stop-reason resolver and explicit status transitions.
Validation: Integration tests for each stop condition.
Docs: Stop conditions reference.

### RUN-003 Add resumable run-state snapshot contract
- [x] Define and persist minimal resumable run-state snapshot fields so interrupted runs can be resumed by compatible session stores.
Dependencies: RUN-001, MEM-001.
Implementation details: Snapshot schema includes run/session/step/message/tool and budget counters.
Validation: Integration test pause/resume with in-memory session store.
Docs: Resume semantics note.

### RUN-004 Add cancellation token interface
- [x] Introduce cancellation token checks in loop boundaries and tool/model execution boundaries so cancellation exits cleanly with `cancelled` status.
Dependencies: RUN-001.
Implementation details: Checkpoints before/after model calls and tool runs.
Validation: Tests that cancellation mid-run yields deterministic result and events.
Docs: Cancellation usage section.

### RUN-005 Add retry policy handling at runner level
- [x] Implement bounded runner-level retry behavior for retryable model/tool phases without masking structured terminal errors.
Dependencies: RUN-001, ARCH-003.
Implementation details: Separate retry counters for model and tool paths.
Validation: Integration tests for retry success and retry exhaustion.
Docs: Retry behavior note.

### TOOL-001 Define Tool and ToolRegistry contracts
- [x] Implement first-class tool contracts and registry operations for register, resolve, list, and immutable metadata retrieval.
Dependencies: ARCH-001.
Implementation details: Include id, name, description, input schema, output schema, permissions, risk, and timeout metadata.
Validation: Unit tests for registration, duplicate detection, and lookup.
Docs: Tool contract guide.

### TOOL-002 Enforce tool input schema validation
- [x] Validate requested tool inputs against declared schema before execution and return deterministic `tool_input_invalid` errors on mismatch.
Dependencies: TOOL-001, ARCH-003.
Implementation details: Schema validation helper with explicit field-level violations.
Validation: Unit tests for valid, missing-required, and unknown-field inputs.
Docs: Tool input validation section.

### TOOL-003 Enforce unknown-tool rejection
- [x] Reject unknown tool names deterministically before execution with `tool_not_found` and trace event emission.
Dependencies: TOOL-001.
Implementation details: Registry resolve failure path in runner.
Validation: Integration test unknown tool call request.
Docs: Error behavior note.

### TOOL-004 Implement ToolExecutionContext contract
- [x] Provide structured execution context to tool handlers including run IDs, session IDs, agent metadata, cancellation token, and scoped policy handles.
Dependencies: TOOL-001, RUN-001.
Implementation details: Immutable context object passed to all handlers.
Validation: Unit tests verifying context fields and immutability expectations.
Docs: Tool handler API reference.

### TOOL-005 Enforce tool timeout and structured failure mapping
- [x] Enforce per-tool timeout where feasible and map handler failures to deterministic `tool_execution_failed` errors.
Dependencies: TOOL-004, ARCH-003.
Implementation details: Timeout wrapper and exception-safe normalization.
Validation: Tests for timeout, thrown errors, and returned error payloads.
Docs: Timeout and failure behavior.

### TOOL-006 Add optional tool output sanitizer hook
- [x] Support optional sanitizer callback on tool outputs before they are appended to context or events.
Dependencies: TOOL-004, SEC-006.
Implementation details: Sanitizer result contract and fallback on sanitizer failure.
Validation: Unit tests for sanitization applied and sanitizer-error handling.
Docs: Sanitization note.

### SEC-001 Implement approval policy contract
- [x] Implement approval policy decision contracts covering always-allow, always-deny, write-tool, high-risk, and permission-based requirements.
Dependencies: TOOL-001.
Implementation details: Policy evaluator independent of provider/UI.
Validation: Unit tests for all policy modes.
Docs: Approval policy matrix.

### SEC-002 Implement approval provider interfaces and defaults
- [x] Implement `ApprovalProvider` plus `AutoApprovalProvider` and `DenyAllApprovalProvider` with a stubbed manual-provider interface for external integrations.
Dependencies: SEC-001.
Implementation details: Request/decision/status contracts with deterministic decision IDs.
Validation: Unit tests for allow, deny, and pending/manual-style paths.
Docs: Approval provider extension section.

### SEC-003 Enforce approval gates in tool execution
- [x] Require and resolve approvals before executing gated tools and return `approval_required` or `approval_denied` statuses without running handlers when not approved.
Dependencies: SEC-001, SEC-002, TOOL-004.
Implementation details: Approval check before tool handler invocation.
Validation: Integration tests for approved and denied tool calls.
Docs: Approval flow diagram.

### SEC-004 Implement guardrail contracts and stages
- [x] Implement guardrail interfaces with stage-aware checks for before-model, after-model, before-tool, after-tool, and before-final-output.
Dependencies: ARCH-002.
Implementation details: Guardrail result supports pass, warn, and block.
Validation: Unit tests for each stage and action type.
Docs: Guardrail stage reference.

### SEC-005 Add built-in minimal guardrails
- [x] Add built-in guardrails for max input length, blocked terms, tool-risk block, and final-output size limits.
Dependencies: SEC-004.
Implementation details: Configurable defaults with deterministic violation payloads.
Validation: Integration tests showing pass, warn, and block behavior.
Docs: Built-in guardrails guide.

### SEC-006 Add redaction policy hooks for events and traces
- [x] Add redaction hooks so sensitive fields in events, trace payloads, and tool IO can be sanitized before persistence or export.
Dependencies: TRACE-001, SEC-004.
Implementation details: Redaction policy interface and default basic implementation.
Validation: Tests proving sensitive keys are masked deterministically.
Docs: Redaction policy section.

### SEC-007 Enforce memory write policy controls
- [x] Apply policy checks on memory writes so restricted scopes or data classes can be denied with structured errors.
Dependencies: MEM-003, SEC-001.
Implementation details: Memory policy evaluator and denial error mapping.
Validation: Unit tests for allowed and denied writes by scope.
Docs: Memory security constraints.

### MEM-001 Implement Session types and SessionStore interface
- [x] Define `Session`, `SessionId`, `SessionMessage`, `SessionState`, and `SessionStore` contracts including CRUD and run-continuity operations.
Dependencies: ARCH-002.
Implementation details: Session schema includes metadata and resumable fields.
Validation: Unit tests for interface conformance via in-memory store.
Docs: Session model section.

### MEM-002 Implement InMemorySessionStore
- [x] Implement deterministic in-memory session store supporting create/get/update/list and run-state persistence operations.
Dependencies: MEM-001.
Implementation details: Stable ordering and deterministic IDs for tests.
Validation: Unit tests for persistence and retrieval behavior.
Docs: Default session store docs.

### MEM-003 Implement Memory interfaces and stores
- [x] Implement `MemoryStore` abstractions with `NoopMemory` and `InMemoryMemoryStore` supporting read, write, query, delete, and provenance fields.
Dependencies: ARCH-002.
Implementation details: Scope-aware operations for session/user/project namespaces.
Validation: Unit tests for each operation and scope isolation.
Docs: Memory abstraction docs.

### MEM-004 Add memory query/result contracts with provenance
- [x] Define structured memory query/result contracts that include source/provenance metadata suitable for citations and audits.
Dependencies: MEM-003.
Implementation details: Include entry IDs, timestamps, source tag, and confidence where applicable.
Validation: Unit tests for query filtering and provenance shape.
Docs: Provenance fields reference.

### MEM-005 Integrate session and memory lifecycle into runner
- [x] Wire runner lifecycle to read prior session state and persist new messages, tool outputs, and memory interactions deterministically.
Dependencies: RUN-001, MEM-002, MEM-003.
Implementation details: Explicit save points after model/tool/final steps.
Validation: Integration test for multi-turn continuity and resume behavior.
Docs: Runner state persistence note.

### RAG-001 Define RetrievalProvider and retrieval contracts
- [x] Implement retrieval provider interfaces and request/response contracts including retrieved documents, context blocks, and citations.
Dependencies: ARCH-002.
Implementation details: Include `RetrievalQuery`, `RetrievedDocument`, `RetrievedContext`, and `RetrievalPolicy`.
Validation: Unit tests validating retrieval payload schema.
Docs: Retrieval hook contract doc.

### RAG-002 Integrate retrieval pre-model context injection
- [x] Add optional runner step that queries retrieval provider and injects retrieved context before model invocation.
Dependencies: RUN-001, RAG-001.
Implementation details: Controlled by agent policy and retrieval config.
Validation: Integration test proving context insertion changes model prompt context fields.
Docs: Retrieval lifecycle section.

### RAG-003 Add citation propagation to outputs and events
- [x] Propagate retrieval citations into run result metadata, artifacts, and trace events using stable citation schemas.
Dependencies: RAG-002, TRACE-001, ART-001.
Implementation details: Include citation IDs, path/doc IDs, and score metadata.
Validation: Contract test for citation shape in result and trace payloads.
Docs: Citation contract reference.

### RAG-004 Provide mock retrieval provider for no-network tests
- [x] Add deterministic mock retrieval provider fixture for integration tests and examples to avoid network dependencies.
Dependencies: RAG-001.
Implementation details: Seeded responses by query string.
Validation: Integration tests rely on mock provider only.
Docs: Testing guidance note.

### HANDOFF-001 Implement handoff core contracts
- [x] Implement core handoff contracts for targets, policy, request, result, and depth/loop metadata.
Dependencies: ARCH-002.
Implementation details: Explicit target references and handoff reasons.
Validation: Unit tests for contract creation and validation.
Docs: Handoff concepts section.

### HANDOFF-002 Implement explicit handoff execution path
- [x] Add runner support for explicit handoff execution from one agent to configured target agents with deterministic result merging.
Dependencies: RUN-001, HANDOFF-001.
Implementation details: Target agent registry and handoff invocation path.
Validation: Integration test planner-to-writer handoff flow.
Docs: Handoff execution guide.

### HANDOFF-003 Enforce handoff depth and loop prevention
- [x] Prevent infinite handoff recursion using max-depth and visited-target guards with structured `handoff_failed` errors on violation.
Dependencies: HANDOFF-002, BUDGET-001.
Implementation details: Track depth and target history in run context.
Validation: Integration test for loop detection and depth exhaustion.
Docs: Handoff safety note.

### HANDOFF-004 Emit handoff lifecycle trace events
- [x] Emit deterministic handoff started/completed/failed events including source/target agent metadata.
Dependencies: TRACE-001, HANDOFF-002.
Implementation details: Event payload includes handoff request ID and depth.
Validation: Contract tests for event kinds and payload keys.
Docs: Handoff observability reference.

### TRACE-001 Implement trace event schema and sink interface
- [x] Define trace schema and `TraceSink` interface with stable required fields including run ID, agent ID, event kind, timestamp, and payload.
Dependencies: ARCH-004.
Implementation details: Use injected clock for deterministic timestamps in tests.
Validation: Unit tests for schema and sink method behavior.
Docs: Trace schema section.

### TRACE-002 Implement InMemoryTraceSink
- [x] Implement in-memory trace sink with deterministic append/list/filter operations and ordering guarantees.
Dependencies: TRACE-001.
Implementation details: Stable sequence numbers and bounded option support.
Validation: Unit tests for order, filtering, and limits.
Docs: Default trace sink docs.

### TRACE-003 Implement optional JsonlTraceSink
- [x] Implement JSONL trace sink for local persistence with safe path handling and deterministic serialization format.
Dependencies: TRACE-001.
Implementation details: Append-only write mode and path validation.
Validation: Tests for file output lines and parseability.
Docs: JSONL sink usage note.

### TRACE-004 Emit full runner lifecycle events
- [x] Wire runner to emit all required lifecycle events for run/model/tool/memory/guardrail/handoff/artifact/completion paths.
Dependencies: TRACE-002, RUN-001, TOOL-004, SEC-004, MEM-003, HANDOFF-002, ART-001.
Implementation details: Central event emitter utility with consistent payload builders.
Validation: Integration tests asserting required event sequence.
Docs: Event lifecycle diagram.

### TRACE-005 Apply trace payload redaction metadata
- [x] Attach redaction metadata and sensitivity markers to trace events where payloads were sanitized or truncated.
Dependencies: TRACE-004, SEC-006.
Implementation details: Include redaction flags and transformed-field counts.
Validation: Unit tests for redaction metadata presence.
Docs: Trace redaction notes.

### ART-001 Implement Artifact contracts and in-memory store
- [x] Implement artifact contracts and `InMemoryArtifactStore` with create/get/list operations for typed outputs.
Dependencies: ARCH-002.
Implementation details: Include `Artifact`, `ArtifactId`, `ArtifactKind`, metadata, producer IDs, and timestamps.
Validation: Unit tests for artifact creation and retrieval.
Docs: Artifact model overview.

### ART-002 Implement optional file artifact store
- [x] Implement optional file-backed artifact store with safe root path constraints and deterministic reference metadata.
Dependencies: ART-001.
Implementation details: Enforce root path and reject traversal-like writes.
Validation: Tests for safe writes, rejects, and metadata references.
Docs: File artifact store guide.

### ART-003 Integrate artifact creation in runner lifecycle
- [x] Allow runner and tool handlers to emit artifacts during execution and include artifact references in final run result.
Dependencies: RUN-001, ART-001.
Implementation details: Artifact creation API in execution context.
Validation: Integration test generating markdown/report artifacts.
Docs: Artifact creation usage section.

### ART-004 Enforce artifact size and kind constraints
- [x] Enforce configurable artifact byte limits and allowed kinds with deterministic `budget_exceeded` or validation errors.
Dependencies: ART-001, BUDGET-001.
Implementation details: Size accounting on create operations.
Validation: Unit tests for allowed and rejected artifact writes.
Docs: Artifact limits note.

### BUDGET-001 Implement budget and usage core contracts
- [x] Define `AgentBudget`, `BudgetUsage`, and limit policy contracts covering model calls, tool calls, steps, handoffs, memory operations, artifact bytes, tokens, cost, and elapsed time.
Dependencies: ARCH-002.
Implementation details: Counter schema and limit-check helpers.
Validation: Unit tests for counter increment and threshold checks.
Docs: Budget contract reference.

### BUDGET-002 Integrate budget enforcement into runner
- [x] Enforce budget limits at each lifecycle boundary so exceeded limits stop runs deterministically with structured errors.
Dependencies: BUDGET-001, RUN-001.
Implementation details: Pre/post checks around model/tool/handoff/memory/artifact steps.
Validation: Integration tests for each limit category.
Docs: Budget enforcement section.

### BUDGET-003 Enforce timeout and elapsed-time limits
- [x] Enforce max elapsed time and configured timeout deadlines with deterministic `timeout` results independent of provider errors.
Dependencies: BUDGET-002, ARCH-005.
Implementation details: Deadline tracking with injected clock.
Validation: Tests for timeout cutoff behavior.
Docs: Timeout semantics section.

### BUDGET-004 Emit budget telemetry events
- [x] Emit structured budget usage and budget-exceeded events so external tooling can monitor run spend and limit triggers.
Dependencies: TRACE-004, BUDGET-002.
Implementation details: Event payload includes counters and limit snapshots.
Validation: Contract tests for budget event fields.
Docs: Budget observability note.

### STREAM-001 Define typed agent stream event contracts
- [x] Define typed streaming event contracts for model deltas, tool lifecycle, approvals, handoffs, artifacts, and run terminal events.
Dependencies: ARCH-004.
Implementation details: Stable stream event kinds and payload shape helpers.
Validation: Unit tests for stream event schema validity.
Docs: Streaming event reference.

### STREAM-002 Implement streaming runner path via AI SDK stream
- [x] Implement runner streaming mode that consumes AI SDK streaming and emits typed agent stream events while maintaining deterministic final result state.
Dependencies: AI-001, RUN-001, STREAM-001.
Implementation details: Adapter from AI SDK `on_event` callbacks to agent stream events.
Validation: Integration test for streaming run with token deltas and completion.
Docs: Streaming usage guide.

### STREAM-003 Ensure stream and non-stream result parity
- [x] Guarantee that streaming and non-streaming runs produce equivalent terminal `AgentRunResult` shape for the same deterministic fixture inputs.
Dependencies: STREAM-002.
Implementation details: Shared terminal result builder.
Validation: Contract test comparing stream/non-stream terminal outputs.
Docs: Parity guarantee note.

### STREAM-004 Add stream failure-path coverage
- [x] Add tests for stream callback failure, guardrail block during stream, and tool-call stream event ordering.
Dependencies: STREAM-002, SEC-004, TOOL-004.
Implementation details: Deterministic failure fixtures and expected event order assertions.
Validation: Integration tests for stream failure modes.
Docs: Streaming troubleshooting section.

### INTEG-001 Define external tool provider adapter boundary (MCP/MCT)
- [x] Define external-tool-provider interfaces and adapter contracts so MCP/MCT tool catalogs can be mapped into ToolRegistry entries without core coupling.
Dependencies: TOOL-001.
Implementation details: Map permissions/risk/approval metadata and schema contracts.
Validation: Unit tests using fake external provider adapter.
Docs: MCP/MCT integration boundary docs.

### INTEG-002 Define Dispatch integration hooks
- [x] Define boundary interfaces and example adapter patterns for running an agent as a Dispatch step and invoking Dispatch workflows as tools.
Dependencies: RUN-001, TOOL-001, TRACE-001.
Implementation details: Interface-only core with no direct Dispatch dependency.
Validation: Contract tests for adapter payload conversions.
Docs: Dispatch integration boundary docs.

### INTEG-003 Define Watchdog trace sink adapter hook
- [x] Define a trace sink adapter contract that lets Watchdog consume agent lifecycle events and metadata without modifying core runner logic.
Dependencies: TRACE-001.
Implementation details: Adapter maps core trace event schema to watchdog-ingest-friendly records.
Validation: Unit tests for adapter event transformation.
Docs: Watchdog observability integration note.

### INTEG-004 Define Scout code-context provider hook
- [x] Define a code-context provider interface that allows Scout-produced intelligence to feed retrieval/context enrichment without hard dependency in core modules.
Dependencies: RAG-001.
Implementation details: Interface and adapter payload expectations.
Validation: Unit tests with fake Scout context provider.
Docs: Scout integration boundary docs.

### INTEG-005 Document hosted/commercial product boundaries
- [x] Document explicit extension boundaries for hosted/team/commercial features while keeping Agents SDK local-first and free/open.
Dependencies: DOC-001.
Implementation details: Boundary table listing in-SDK versus out-of-SDK responsibilities.
Validation: Docs review checklist entry.
Docs: Dedicated architecture boundary section.

### TEST-001 Create no-network test harness and fixtures
- [x] Create deterministic mock model/retrieval/tool fixtures so all default tests run without external API keys or network access.
Dependencies: ARCH-001.
Implementation details: Fixture adapters and fake responses for chat/stream/retrieval.
Validation: Test run in offline environment.
Docs: Test harness docs.

### TEST-002 Add unit tests for core contracts
- [x] Add unit tests for config validation, error mapping, event schemas, and ID/time determinism.
Dependencies: ARCH-002, ARCH-003, ARCH-004, ARCH-005.
Implementation details: Focus on schema defaults and invalid input handling.
Validation: Unit suite passes locally.
Docs: None unless behavior is user-facing.

### TEST-003 Add unit tests for tools, approvals, guardrails, budgets
- [x] Add unit tests covering tool registry, tool validation, approval decisions, guardrail outcomes, and budget counters.
Dependencies: TOOL-001, TOOL-002, SEC-001, SEC-004, BUDGET-001.
Implementation details: Deterministic input/output assertions.
Validation: Unit suite pass with no-network guarantee.
Docs: None.

### TEST-004 Add unit tests for session, memory, artifacts, trace stores
- [x] Add unit tests for in-memory session, memory, artifact, and trace implementations including CRUD and ordering behaviors.
Dependencies: MEM-002, MEM-003, ART-001, TRACE-002.
Implementation details: Explicit data lifecycle and isolation checks.
Validation: Unit suite pass.
Docs: None.

### TEST-005 Add integration tests for core runner flows
- [x] Add integration tests for basic run, tool-call run, approval-denied run, guardrail-blocked run, retrieval-enriched run, handoff run, and budget/iteration stop paths.
Dependencies: RUN-001, TOOL-004, SEC-003, RAG-002, HANDOFF-002, BUDGET-002.
Implementation details: Mock adapters only.
Validation: Integration suite pass offline.
Docs: Mention tested flows.

### TEST-006 Add contract tests for deterministic result and event shapes
- [x] Add contract tests asserting stable `AgentRunResult` and event payload schemas for success and failure scenarios.
Dependencies: TRACE-004, RUN-002.
Implementation details: Snapshot-like schema assertion helpers with deterministic IDs/time.
Validation: Contract suite pass.
Docs: Contract stability statement.

### TEST-007 Add example smoke tests
- [x] Add smoke tests ensuring examples compile/run or parse according to repository conventions with deterministic outputs.
Dependencies: DOC-007.
Implementation details: Minimal assertions for each example entrypoint.
Validation: Example smoke suite pass offline.
Docs: Example validation command section.

### TEST-008 Add CI no-network enforcement checks
- [x] Add CI/test harness checks that fail if default suites require network access or missing external provider keys.
Dependencies: TEST-001.
Implementation details: Guard env checks and fixture defaults.
Validation: CI run with no provider keys succeeds.
Docs: CI policy note.

### DOC-001 Create Agents SDK README and overview
- [x] Add top-level README describing purpose, architecture boundary with AI SDK, quickstart path, and stability/experimental notes.
Dependencies: ARCH-001, AI-001.
Implementation details: Include API surface summary and local-first principles.
Validation: README lint/manual review.
Docs: This is the doc output.

### DOC-002 Add architecture and module map documentation
- [x] Add architecture docs describing module responsibilities, data flow, and extension interfaces.
Dependencies: ARCH-001.
Implementation details: Include runner lifecycle diagram and component relationships.
Validation: Docs reviewed against implemented modules.
Docs: Architecture page.

### DOC-003 Add developer guide for defining and running agents
- [x] Add developer guide showing how to define an agent, register tools, and run non-stream and stream modes.
Dependencies: RUN-001, TOOL-001, STREAM-002.
Implementation details: Use deterministic mock-first snippets.
Validation: Snippets validated in tests where feasible.
Docs: Developer guide.

### DOC-004 Add docs for sessions, memory, guardrails, approvals, artifacts, tracing, handoffs, retrieval
- [x] Add dedicated docs for each major runtime primitive with examples and policy notes.
Dependencies: MEM-005, SEC-005, ART-003, TRACE-004, HANDOFF-002, RAG-002.
Implementation details: One focused page per primitive.
Validation: Docs cross-links resolve.
Docs: Primitive reference set.

### DOC-005 Add security and production guidance
- [x] Add production guidance for safe defaults, dangerous tool controls, redaction, timeout/iteration limits, and policy hardening.
Dependencies: SEC-005, BUDGET-003.
Implementation details: Threat-aware checklists and recommended defaults.
Validation: Guidance reviewed against actual defaults.
Docs: Security/operations guide.

### DOC-006 Add integration boundary docs for MCP/MCT, Dispatch, Watchdog, Scout, and commercial hosted layers
- [x] Add explicit boundary docs that describe adapter contracts and clearly separate local SDK responsibilities from hosted/commercial product features.
Dependencies: INTEG-001, INTEG-002, INTEG-003, INTEG-004, INTEG-005.
Implementation details: Include anti-goals and future extension examples.
Validation: Boundary matrix completeness review.
Docs: Integrations boundary guide.

### DOC-007 Add deterministic examples set
- [x] Add example programs for hello agent, tool agent, approval agent, retrieval agent, handoff agent, traced agent, and artifact agent using mock/no-network defaults.
Dependencies: RUN-001, TOOL-004, SEC-003, RAG-004, HANDOFF-002, TRACE-002, ART-003.
Implementation details: Keep examples minimal and reproducible.
Validation: Example smoke tests pass.
Docs: Example index page.

### REL-001 Add package metadata, scripts, and test commands
- [x] Add package metadata and standard scripts for build/test/example validation aligned with Agents SDK ecosystem conventions.
Dependencies: ARCH-001, TEST-001.
Implementation details: Provide deterministic command list in metadata.
Validation: Commands execute successfully in local runtime.
Docs: README command section.

### REL-002 Run full validation and fix regressions
- [x] Run full unit/integration/contract/example suites and resolve regressions while preserving no-network defaults.
Dependencies: TEST-008.
Implementation details: Capture executed commands and outcomes.
Validation: All required suites pass.
Docs: Validation report summary.

### REL-003 Perform public API stability review
- [x] Review exported API names/contracts for clarity and backwards compatibility with planned future versions and document any experimental surfaces.
Dependencies: ARCH-001 through STREAM-004.
Implementation details: API inventory and stability markers.
Validation: API review checklist complete.
Docs: Public API stability section.

### REL-004 Update changelog and release notes
- [x] Update changelog/release notes with implemented features, known limitations, and migration notes where needed.
Dependencies: REL-002.
Implementation details: Summarize by item-family IDs.
Validation: Release notes reviewed for completeness.
Docs: Changelog/release entry.

### REL-005 Complete final acceptance review
- [x] Verify final acceptance criteria against this checklist and record objective evidence for each criterion before marking the project release-ready.
Dependencies: REL-001, REL-002, REL-003, REL-004.
Implementation details: Evidence table mapped to criteria.
Validation: Final acceptance checklist fully checked.
Docs: Acceptance report section.

## 8. Completion Template
Use this template when closing an item in the Work Log:

- Date: YYYY-MM-DD
- Item ID: <ID>
- Summary: <what was implemented>
- Files changed: <paths>
- Tests/validation run: <commands and outcomes>
- Docs updated: <paths or N/A>
- Follow-ups: <none or list>

## 9. Work Log
- Date: 2026-05-22
- Item ID: CHECKLIST-BOOTSTRAP
- Summary: Created initial Agents SDK build checklist after repository assessment of AI SDK and related Agents SDK ecosystem repositories.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: N/A (planning-only change).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Start implementation from first unchecked actionable item (ARCH-001).

- Date: 2026-05-22
- Item ID: ARCH-001
- Summary: Added the foundational `src/agents` module layout, package export map, and public index export stubs with deterministic module descriptors.
- Files changed: README.md, agents-sdk.toml, kennel.toml, examples/module_exports_smoke.kujo, tests/arch_module_layout_tests.kujo, src/agents/index.kujo, src/agents/core_types.kujo, src/agents/errors.kujo, src/agents/events.kujo, src/agents/runner.kujo, src/agents/tools/registry.kujo, src/agents/security/approval.kujo, src/agents/sessions/store.kujo, src/agents/memory/store.kujo, src/agents/retrieval/provider.kujo, src/agents/handoffs/handoff.kujo, src/agents/tracing/sink.kujo, src/agents/artifacts/store.kujo, src/agents/budgets/limits.kujo, src/agents/streaming/events.kujo, src/agents/integrations/adapters.kujo
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 2/2).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with ARCH-002 core runtime type contracts.

- Date: 2026-05-22
- Item ID: ARCH-002
- Summary: Implemented core type constructors and validators for agent config, messages, steps, run requests, contexts, and run results with stable status/role/kind helpers.
- Files changed: src/agents/core_types.kujo, tests/arch_core_types_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v` (passed: 7/7).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with ARCH-003 deterministic error model.

- Date: 2026-05-22
- Item ID: ARCH-003
- Summary: Implemented the centralized error model with required `AgentErrorKind` values, retryability classification, normalization helpers, and structured error-result constructors.
- Files changed: src/agents/errors.kujo, tests/arch_error_model_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v` (passed: 12/12).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with ARCH-004 runtime event kinds and event payload contracts.

- Date: 2026-05-22
- Item ID: ARCH-004
- Summary: Implemented event-kind and required-field registries, deterministic event constructors, lifecycle helper wrappers, and event-shape validation contracts.
- Files changed: src/agents/events.kujo, tests/arch_event_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v` (passed: 18/18).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with ARCH-005 clock and id generator abstraction.

- Date: 2026-05-22
- Item ID: ARCH-005
- Summary: Added injectable runtime clock/id services with fixed test fakes and wired run-id, step-id, event-id, and event timestamp generation through runtime service propagation.
- Files changed: src/agents/runtime/clock_ids.kujo, src/agents/core_types.kujo, src/agents/events.kujo, tests/arch_runtime_clock_ids_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v` (passed: 22/22).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with AI-001 AI SDK adapter boundary module.

- Date: 2026-05-22
- Item ID: AI-001
- Summary: Added AI adapter boundary module with injected chat/stream callback contracts, request option builder, normalized response mapping, and deterministic invalid-config/model-error handling.
- Files changed: src/agents/ai/adapter.kujo, tests/ai_adapter_boundary_tests.kujo, README.md, kennel.toml, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v` (passed: 27/27).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with AI-002 response mapping into runner-facing model result contracts.

- Date: 2026-05-22
- Item ID: AI-002
- Summary: Exposed and validated `to_agent_model_result` mapping contract to preserve provider/model/request/usage metadata and normalize provider/timeout errors into agent error kinds.
- Files changed: src/agents/ai/adapter.kujo, tests/ai_adapter_boundary_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v` (passed: 28/28).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with AI-003 structured output schema passthrough.

- Date: 2026-05-22
- Item ID: AI-003
- Summary: Added structured-output schema enforcement during AI result mapping so success payloads missing required structured fields return deterministic `structured_output_invalid` errors.
- Files changed: src/agents/ai/adapter.kujo, tests/ai_adapter_boundary_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v` (passed: 29/29).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with AI-004 usage metadata integration for budgets.

- Date: 2026-05-22
- Item ID: AI-004
- Summary: Added token/cost usage normalization and `extract_usage_metrics` so AI model results carry budget-ready usage metadata even when providers return mixed token field formats.
- Files changed: src/agents/ai/adapter.kujo, tests/ai_adapter_boundary_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v` (passed: 30/30).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with AI-005 observability hook compatibility.

- Date: 2026-05-22
- Item ID: AI-005
- Summary: Added adapter/agent observability hook composition with de-dup wrappers and option-merge helpers, then wired call paths to pass merged hooks into AI callback execution.
- Files changed: src/agents/ai/adapter.kujo, tests/ai_adapter_boundary_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v` (passed: 32/32).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RUN-001 basic non-stream AgentRunner loop.

- Date: 2026-05-22
- Item ID: RUN-001
- Summary: Replaced the runner stub with a deterministic non-stream execution loop that validates config, builds context/messages, invokes the AI adapter, records model/final steps, emits lifecycle events, and returns stable completed/failed run results.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `KUJO_BIN=/path/to/kujo/target/debug/kujo "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && "$KUJO_BIN" test-run tests/ai_adapter_boundary_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 35/35).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RUN-002 deterministic stop conditions.

- Date: 2026-05-22
- Item ID: RUN-002
- Summary: Marked RUN-002 blocked pending dependency BUDGET-001, which remains unchecked; recorded blocker evidence inline under the item per checklist protocol.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: N/A (dependency-gated planning update).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Resume RUN-002 once BUDGET-001 is implemented.

- Date: 2026-05-22
- Item ID: RUN-003
- Summary: Marked RUN-003 blocked pending dependency MEM-001, which remains unchecked; recorded blocker evidence inline under the item per checklist protocol.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: N/A (dependency-gated planning update).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Resume RUN-003 once MEM-001 is implemented.

- Date: 2026-05-22
- Item ID: RUN-004
- Summary: Added runtime cancellation token contracts and runner loop cancellation checkpoints before/after model execution, with deterministic `cancelled` status, structured cancellation errors, and `run_cancelled` event emission.
- Files changed: src/agents/runtime/cancellation.kujo, src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v` (passed: 5/5).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RUN-005 retry policy handling.

- Date: 2026-05-22
- Item ID: RUN-005
- Summary: Added bounded runner-level model retry handling with retryability checks, per-attempt request metadata, and deterministic retry counter reporting without masking terminal structured errors.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v` (passed: 7/7).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-001 tool and registry contracts.

- Date: 2026-05-22
- Item ID: TOOL-001
- Summary: Replaced the tool registry stub with active Tool/ToolRegistry contracts including normalized tool creation, contract validation, duplicate-safe registration, deterministic resolve/list operations, and immutable metadata retrieval views.
- Files changed: src/agents/tools/registry.kujo, tests/tool_registry_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v && /path/to/kujo/target/debug/kujo test-run tests/tool_registry_tests.kujo -v` (passed: 11/11).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-002 tool input schema validation.

- Date: 2026-05-22
- Item ID: TOOL-002
- Summary: Added schema-driven tool input validation contracts (`validate_tool_input` and `validate_registered_tool_input`) with deterministic field-level violations for missing required and unknown fields mapped to `tool_input_invalid` errors.
- Files changed: src/agents/tools/registry.kujo, tests/tool_registry_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v && /path/to/kujo/target/debug/kujo test-run tests/tool_registry_tests.kujo -v` (passed: 14/14).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-003 unknown-tool rejection in runner flow.

- Date: 2026-05-22
- Item ID: TOOL-003
- Summary: Added runner preflight checks for requested tools so unresolved names fail deterministically with `tool_not_found`, emit `run_failed`, and return structured metadata before model execution.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/tool_registry_tests.kujo -v && /path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v` (passed: 15/15).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-004 ToolExecutionContext contract.

- Date: 2026-05-22
- Item ID: TOOL-004
- Summary: Added `ToolExecutionContext` contract constructors and invocation helpers carrying run/session/agent IDs, agent metadata, cancellation token, policy handles, and invocation input with immutable payload behavior.
- Files changed: src/agents/tools/registry.kujo, tests/tool_execution_context_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `/path/to/kujo/target/debug/kujo test-run tests/tool_execution_context_tests.kujo -v && /path/to/kujo/target/debug/kujo test-run tests/tool_registry_tests.kujo -v && /path/to/kujo/target/debug/kujo test-run tests/run_basic_runner_tests.kujo -v` (passed: 18/18).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-005 timeout and failure mapping.

- Date: 2026-05-22
- Item ID: TOOL-005
- Summary: Added timeout-aware tool execution wrappers with deterministic `tool_execution_failed` normalization for invalid handler payloads, explicit handler failure responses, and timeout breaches.
- Files changed: src/agents/tools/registry.kujo, tests/tool_registry_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v` (passed: 13/13).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TOOL-006 sanitizer hook once SEC-006 dependency is complete.

- Date: 2026-05-22
- Item ID: SEC-001
- Summary: Implemented approval policy contracts with deterministic request/decision evaluators covering always-allow, always-deny, write-tool, high-risk, and permission-based requirements.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v` (passed: 4/4).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-002 approval provider interfaces and defaults.

- Date: 2026-05-22
- Item ID: SEC-002
- Summary: Added ApprovalProvider contracts with auto, deny-all, and manual-stub defaults plus deterministic provider decision IDs and approved/denied/pending statuses.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 8/8).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-003 approval gate enforcement in tool execution.

- Date: 2026-05-22
- Item ID: SEC-003
- Summary: Enforced approval gates in tool execution so policy/provider requirements return deterministic `approval_required` or `approval_denied` statuses before handler invocation, while approved paths continue normally.
- Files changed: src/agents/tools/registry.kujo, tests/tool_registry_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v` (passed: 22/22).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-004 guardrail contracts and stage checks.

- Date: 2026-05-22
- Item ID: SEC-004
- Summary: Added stage-aware guardrail contracts and evaluators with deterministic `pass`/`warn`/`block` outcomes for rule-level and aggregated policy checks across all required lifecycle stages.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 25/25).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-005 built-in minimal guardrails.

- Date: 2026-05-22
- Item ID: SEC-005
- Summary: Added configurable built-in guardrails for max input length, blocked terms, tool-risk blocking, and final-output size limits with deterministic pass/warn/block outcomes.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 28/28).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-006 redaction policy hooks for events and traces.

- Date: 2026-05-22
- Item ID: SEC-006
- Summary: Added redaction policy contracts and deterministic redaction hooks for event payloads, trace payloads, and tool IO, including masked-field counters and configurable replacement patterns.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 32/32).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-007 memory write policy controls.

- Date: 2026-05-22
- Item ID: MEM-001
- Summary: Replaced the session-store stub with normalized `SessionId`/`SessionMessage`/`SessionState`/`Session` contracts and `SessionStore` CRUD plus run-state continuity wrappers.
- Files changed: src/agents/sessions/store.kujo, tests/session_store_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 4/4).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with MEM-002 deterministic in-memory session store.

- Date: 2026-05-22
- Item ID: MEM-002
- Summary: Added a deterministic `InMemorySessionStore` factory with CRUD and run-state callbacks backed by module-scoped store state and explicit reset support for isolated tests.
- Files changed: src/agents/sessions/store.kujo, tests/session_store_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 30/30).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with MEM-003 memory interfaces and stores.

- Date: 2026-05-22
- Item ID: MEM-003
- Summary: Replaced the memory-store stub with memory contracts, interface wrappers, `NoopMemory`, and deterministic `InMemoryMemoryStore` implementations including scope isolation and reset support.
- Files changed: src/agents/memory/store.kujo, tests/memory_store_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 34/34).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with SEC-007 memory write policy controls.

- Date: 2026-05-22
- Item ID: SEC-007
- Summary: Added memory write policy contracts and evaluator logic that enforce scope and data-class restrictions with structured `memory_write_denied` errors.
- Files changed: src/agents/security/approval.kujo, tests/security_approval_policy_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 36/36).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with MEM-004 provenance-aware memory query/result contracts.

- Date: 2026-05-22
- Item ID: MEM-004
- Summary: Added `MemoryQueryResult` and provenance summary contracts, wrapped query responses in structured result payloads, and expanded tests to cover scope filtering, offset/limit behavior, and provenance metadata shape.
- Files changed: src/agents/memory/store.kujo, tests/memory_store_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 37/37).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with MEM-005 runner lifecycle integration for session/memory persistence.

- Date: 2026-05-22
- Item ID: MEM-005
- Summary: Integrated runner lifecycle persistence with configurable session and memory stores, including run-state restore/save checkpoints and final-output memory writes plus lifecycle telemetry in run metadata.
- Files changed: src/agents/runner.kujo, tests/runner_session_memory_integration_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 38/38).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RAG-001 retrieval provider contracts.

- Date: 2026-05-22
- Item ID: RAG-001
- Summary: Replaced retrieval provider stub with retrieval query/document/context/citation/result contracts plus provider interface wrapping for normalized retrieval responses.
- Files changed: src/agents/retrieval/provider.kujo, tests/retrieval_provider_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/retrieval_provider_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 40/40).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RAG-002 retrieval pre-model context injection.

- Date: 2026-05-22
- Item ID: TOOL-006
- Summary: Added optional output sanitizer callbacks for tool execution with structured sanitizer metadata and deterministic fallback to original output when sanitizer callbacks fail or reject output.
- Files changed: src/agents/tools/registry.kujo, tests/tool_registry_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v` (passed: 26/26).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RAG-002 retrieval pre-model context injection.

- Date: 2026-05-22
- Item ID: RAG-002
- Summary: Added runner retrieval config/provider resolution, pre-model retrieval query step, deterministic retrieval context message injection into model prompts, and retrieval lifecycle metadata on run results.
- Files changed: src/agents/runner.kujo, src/agents/retrieval/provider.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && "$KUJO_BIN" test-run tests/retrieval_provider_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 56/56).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RAG-003 citation propagation to outputs/events.

- Date: 2026-05-22
- Item ID: RAG-003
- Summary: Marked RAG-003 blocked pending TRACE-001 and ART-001 dependencies; recorded blocker evidence inline per checklist protocol.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: N/A (dependency-gated planning update).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Resume RAG-003 after TRACE-001 and ART-001 are complete.

- Date: 2026-05-27
- Item ID: RAG-003
- Summary: Propagated normalized retrieval citation references into run result metadata, artifact metadata, and `run_completed` trace event payloads with deterministic fallback citation derivation from retrieved documents when provider citations are absent.
- Files changed: src/agents/runner.kujo, src/agents/retrieval/provider.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with HANDOFF-002 explicit handoff execution path.

- Date: 2026-05-22
- Item ID: RAG-004
- Summary: Added deterministic `create_mock_retrieval_provider` seeded by query text and updated retrieval/runner integration tests to use mock retrieval fixtures for no-network coverage.
- Files changed: src/agents/retrieval/provider.kujo, tests/retrieval_provider_contract_tests.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/retrieval_provider_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v` (passed: 57/57).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with HANDOFF-001 handoff core contracts.

- Date: 2026-05-22
- Item ID: HANDOFF-001
- Summary: Replaced handoff stub with core handoff contracts for targets, policies, requests, results, and loop/depth state metadata plus status registry helpers.
- Files changed: src/agents/handoffs/handoff.kujo, tests/handoff_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/handoff_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/retrieval_provider_contract_tests.kujo -v` (passed: 17/17).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with HANDOFF-002 explicit handoff execution path.

- Date: 2026-05-27
- Item ID: TRACE-001
- Summary: Replaced tracing stub with `TraceEvent` schema contracts, required-field validation, and `TraceSink` interface wrappers for append/list operations with deterministic invalid/not-implemented handling.
- Files changed: src/agents/tracing/sink.kujo, tests/trace_sink_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter && "$KUJO_BIN" test-run tests/trace_sink_contract_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new trace sink tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TRACE-002 in-memory trace sink implementation.

- Date: 2026-05-27
- Item ID: TRACE-002
- Summary: Implemented `InMemoryTraceSink` with deterministic append/list/filter behavior, stable sequencing, reset support, and pagination options for offline deterministic testing.
- Files changed: src/agents/tracing/sink.kujo, tests/trace_sink_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/trace_sink_contract_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including expanded in-memory trace sink tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TRACE-003 JSONL sink or ART-001 based on release priority.

- Date: 2026-05-27
- Item ID: ART-001
- Summary: Replaced artifact store stub with `ArtifactKind`/`ArtifactId`/`Artifact` contracts, `ArtifactStore` interface wrappers, and deterministic `InMemoryArtifactStore` create/get/list/filter helpers plus reset support.
- Files changed: src/agents/artifacts/store.kujo, tests/artifact_store_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/artifact_store_contract_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new artifact store tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with ART-002 file-backed artifact store or ART-003 runner artifact integration based on release priority.

- Date: 2026-05-27
- Item ID: ART-003
- Summary: Integrated artifact creation into runner completion flow and tool execution paths, adding artifact handles to `ToolExecutionContext`, persisting emitted artifacts through configured stores, and returning artifact references in run/tool results.
- Files changed: src/agents/runner.kujo, src/agents/tools/registry.kujo, tests/run_basic_runner_tests.kujo, tests/tool_registry_tests.kujo, tests/tool_execution_context_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new runner/tool artifact integration tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with BUDGET-001 core budget contracts before budget-enforced stop conditions.

- Date: 2026-05-27
- Item ID: BUDGET-001
- Summary: Replaced budget limits stub with core budget contracts (`AgentBudget`, `BudgetUsage`, `BudgetLimitPolicy`), deterministic usage increment helpers, and structured limit evaluation returning exceeded-limit details and `budget_exceeded` errors.
- Files changed: src/agents/budgets/limits.kujo, tests/budget_limits_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/budget_limits_contract_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new budget contract tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with BUDGET-002 runner lifecycle budget enforcement.

- Date: 2026-05-27
- Item ID: BUDGET-002
- Summary: Integrated budget policy resolution and usage tracking into runner lifecycle boundaries, enforcing deterministic `budget_exceeded` stop paths and exposing budget policy/usage/check telemetry in run metadata.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new pre-model and post-model budget enforcement integration tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with BUDGET-003 elapsed-time/timeout deadline enforcement.

- Date: 2026-05-27
- Item ID: BUDGET-003
- Summary: Added injected-clock deadline tracking in runner and enforced deterministic timeout cutoffs at lifecycle boundaries (`before_model`, `after_model`, `after_artifact`, `after_memory`) with structured `timeout` terminal results and timeout telemetry metadata.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new injected-clock timeout cutoff tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with RUN-002 stop-condition unification now that budget and timeout controls are active.

- Date: 2026-05-27
- Item ID: RUN-002
- Summary: Completed deterministic stop-condition coverage by adding explicit `max_iterations` terminal stop handling while preserving existing success/failure/cancelled/budget/timeout paths and lifecycle metadata consistency.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite including new max-iterations stop-condition tests).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with checklist drift cleanup and remove outdated blocker notes now satisfied by completed dependencies.

- Date: 2026-05-27
- Item ID: CHECKLIST-DRIFT-001
- Summary: Removed stale dependency blocker notes under RUN-003 and RAG-003 now that MEM-001, TRACE-001, and ART-001 are complete, restoring checklist dependency/status consistency.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue to next unchecked actionable backlog item.

- Date: 2026-05-27
- Item ID: RUN-003
- Summary: Closed RUN-003 using already-implemented session run-state restore/save contracts and existing multi-turn runner integration coverage validating pause/resume continuity with in-memory session store.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/runner_session_memory_integration_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue to next unchecked actionable backlog item.

- Date: 2026-05-27
- Item ID: HANDOFF-002
- Summary: Implemented runner-level explicit handoff execution with target-registry resolution, child-agent invocation, deterministic handoff metadata emission, and merged final output from the target agent when handoff completes.
- Files changed: src/agents/runner.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && for f in tests/*.kujo; do "$KUJO_BIN" test-run "$f" -v || exit 1; done` (passed: full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with HANDOFF-003 depth and loop prevention guards.

- Date: 2026-05-27
- Item ID: HANDOFF-003..INTEG-003
- Summary: Completed the 15-item handoff/trace/artifact/budget/streaming/integration block by adding handoff loop/depth guards, handoff/model/budget/artifact/memory lifecycle telemetry in runner, JSONL trace sink with redaction metadata, file-backed artifact store plus constraints, typed streaming contracts with AI SDK stream mapping/parity/failure handling, and integration adapter boundaries for external providers, Dispatch hooks, and Watchdog trace transformation.
- Files changed: src/agents/runner.kujo, src/agents/tracing/sink.kujo, src/agents/artifacts/store.kujo, src/agents/streaming/events.kujo, src/agents/integrations/adapters.kujo, tests/run_basic_runner_tests.kujo, tests/trace_sink_contract_tests.kujo, tests/artifact_store_contract_tests.kujo, tests/streaming_events_contract_tests.kujo, tests/integration_adapters_contract_tests.kujo, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/trace_sink_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/artifact_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/streaming_events_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/integration_adapters_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 20/20 full suite).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with INTEG-004 Scout code-context provider hook.

- Date: 2026-05-27
- Item ID: INTEG-004
- Summary: Added a Scout code-context provider boundary with deterministic resolve/query contracts, normalized context-entry payloads, and retrieval-enrichment mapping helpers so Scout intelligence can enrich retrieval context without coupling core runtime modules to Scout.
- Files changed: src/agents/integrations/adapters.kujo, tests/integration_adapters_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/integration_adapters_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_module_layout_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 20/20 full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with INTEG-005 hosted/commercial boundary documentation.

- Date: 2026-05-27
- Item ID: DOC-001
- Summary: Expanded the top-level README with an explicit quickstart flow, clear Agents SDK versus AI SDK architecture boundary guidance, and stability/experimental notes for contract and integration surfaces.
- Files changed: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && /path/to/kujo/target/debug/kujo test` (passed: 20/20 full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with INTEG-005 hosted/commercial boundary documentation.

- Date: 2026-05-27
- Item ID: INTEG-005
- Summary: Added an explicit local/open versus hosted/commercial boundary matrix and anti-goals documentation so product-layer capabilities remain extension-driven and outside core runtime modules.
- Files changed: docs/INTEGRATION_BOUNDARIES.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && /path/to/kujo/target/debug/kujo test` (passed: 20/20 full suite).
- Docs updated: docs/INTEGRATION_BOUNDARIES.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-001 no-network harness and fixture baseline review.

- Date: 2026-05-27
- Item ID: TEST-001
- Summary: Added a dedicated no-network fixture module that composes deterministic mock model, retrieval, and tool fixtures for offline tests/examples, plus contract tests validating composed harness behavior without external keys or network access.
- Files changed: src/agents/testing/no_network.kujo, tests/no_network_harness_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/no_network_harness_contract_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 21/21 full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-002 core contract coverage audit and closure.

- Date: 2026-05-27
- Item ID: TEST-002
- Summary: Verified and closed core-contract unit coverage for config validation, error mapping, event schemas, and deterministic clock/id behavior using dedicated contract suites and full regression evidence.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/arch_core_types_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_error_model_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_event_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/arch_runtime_clock_ids_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 21/21 full suite).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-003 tools/approvals/guardrails/budget coverage closure.

- Date: 2026-05-27
- Item ID: TEST-003
- Summary: Verified and closed tools/approvals/guardrails/budgets unit coverage using dedicated suites for registry/input validation/execution context, approval and guardrail policy outcomes, and budget counter/limit behavior.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/tool_registry_tests.kujo -v && "$KUJO_BIN" test-run tests/tool_execution_context_tests.kujo -v && "$KUJO_BIN" test-run tests/security_approval_policy_tests.kujo -v && "$KUJO_BIN" test-run tests/budget_limits_contract_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 21/21 full suite).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-004 session/memory/artifact/trace store coverage closure.

- Date: 2026-05-27
- Item ID: TEST-004
- Summary: Verified and closed session/memory/artifact/trace store unit coverage with dedicated contract suites confirming CRUD behavior, deterministic ordering/filtering, and file/in-memory sink/store behavior.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/session_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/memory_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/artifact_store_contract_tests.kujo -v && "$KUJO_BIN" test-run tests/trace_sink_contract_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 21/21 full suite).
- Docs updated: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-005 core runner integration flow coverage closure.

- Date: 2026-05-27
- Item ID: TEST-005
- Summary: Completed core runner integration flow coverage by extending run-basic integration tests for model-emitted tool calls, approval-denied tool execution, and deterministic stream guardrail terminal behavior; hardened runner/tool context handling to avoid uncaught map-wrapper failures in cancellation and stream event replay paths.
- Files changed: src/agents/runner.kujo, src/agents/tools/registry.kujo, tests/run_basic_runner_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: 21/21 full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-006 deterministic result/event contract-shape coverage.

- Date: 2026-05-27
- Item ID: TEST-006
- Summary: Added deterministic contract tests for successful and failed runner outcomes asserting stable `AgentRunResult` top-level shape and validating lifecycle event payload schema compatibility with fixed runtime ID/time services.
- Files changed: tests/runner_result_event_contract_tests.kujo, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/runner_result_event_contract_tests.kujo -v && /path/to/kujo/target/debug/kujo test` (passed: full suite).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-007 example smoke coverage.

- Date: 2026-05-27
- Item ID: TEST-007
- Summary: Added deterministic smoke coverage for all documented examples and fixed traced-example smoke assertion parity while keeping no-network defaults.
- Files changed: tests/example_smoke_tests.kujo, examples/hello_agent.kujo, examples/tool_agent.kujo, examples/approval_agent.kujo, examples/retrieval_agent.kujo, examples/handoff_agent.kujo, examples/traced_agent.kujo, examples/artifact_agent.kujo, examples/examples_smoke_runner.kujo, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v && "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter` (passed).
- Docs updated: docs/EXAMPLES.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with TEST-008 CI no-network enforcement checks.

- Date: 2026-05-27
- Item ID: TEST-008
- Summary: Added an offline CI enforcement script that clears provider keys and executes deterministic no-network harness, example smoke suite, and full test suite.
- Files changed: scripts/ci_no_network_enforcement.sh, kennel.toml, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && bash scripts/ci_no_network_enforcement.sh` (passed).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with documentation closure items DOC-002 through DOC-007.

- Date: 2026-05-27
- Item ID: DOC-002
- Summary: Added architecture and module-map documentation covering module responsibilities, runner lifecycle, data flow, and extension interfaces.
- Files changed: docs/ARCHITECTURE.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/ARCHITECTURE.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with DOC-003.

- Date: 2026-05-27
- Item ID: DOC-003
- Summary: Added developer guide with deterministic snippets for agent definition, tool registration, and non-stream/stream run flows.
- Files changed: docs/DEVELOPER_GUIDE.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/DEVELOPER_GUIDE.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with DOC-004.

- Date: 2026-05-27
- Item ID: DOC-004
- Summary: Added dedicated primitive docs for sessions, memory, guardrails/approvals, artifacts, tracing, handoffs, and retrieval, plus cross-linked primitive reference index.
- Files changed: docs/PRIMITIVES_REFERENCE.md, docs/primitives/sessions.md, docs/primitives/memory.md, docs/primitives/guardrails-and-approvals.md, docs/primitives/artifacts.md, docs/primitives/tracing.md, docs/primitives/handoffs.md, docs/primitives/retrieval.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/PRIMITIVES_REFERENCE.md, docs/primitives/*.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with DOC-005.

- Date: 2026-05-27
- Item ID: DOC-005
- Summary: Added security and production guidance for safe defaults, dangerous tool controls, redaction hygiene, timeout/iteration hardening, and deployment checklist expectations.
- Files changed: docs/SECURITY_PRODUCTION_GUIDE.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/SECURITY_PRODUCTION_GUIDE.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with DOC-006.

- Date: 2026-05-27
- Item ID: DOC-006
- Summary: Expanded integration boundary documentation with explicit adapter contracts and local versus hosted/commercial responsibility separation for MCP/MCT, Dispatch, Watchdog, and Scout.
- Files changed: docs/INTEGRATION_BOUNDARIES.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/INTEGRATION_BOUNDARIES.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with DOC-007.

- Date: 2026-05-27
- Item ID: DOC-007
- Summary: Added deterministic example index and smoke-runner command guidance for all seven no-network example programs.
- Files changed: docs/EXAMPLES.md, examples/examples_smoke_runner.kujo, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v && "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter` (passed).
- Docs updated: docs/EXAMPLES.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with REL-001 metadata/scripts cleanup.

- Date: 2026-05-27
- Item ID: REL-001
- Summary: Updated release metadata/scripts in kennel package config for full suite, contract checks, example smoke, and offline verification command coverage.
- Files changed: kennel.toml, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter && "$KUJO_BIN" test` (passed).
- Docs updated: README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with REL-002 full validation evidence capture.

- Date: 2026-05-27
- Item ID: REL-002
- Summary: Executed full validation passes for module smoke, example smoke, no-network enforcement checks, and full suite regression with all required suites passing offline.
- Files changed: docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v && "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter && bash scripts/ci_no_network_enforcement.sh && "$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter && "$KUJO_BIN" test` (passed).
- Docs updated: docs/RELEASE_NOTES.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with REL-003 public API stability review.

- Date: 2026-05-27
- Item ID: REL-003
- Summary: Completed public API stability inventory and marker review documenting stable-by-contract surfaces, additive evolution expectations, and experimental integration metadata scope.
- Files changed: docs/PUBLIC_API_STABILITY.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/PUBLIC_API_STABILITY.md, README.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with REL-004 changelog/release notes update.

- Date: 2026-05-27
- Item ID: REL-004
- Summary: Added changelog and release notes capturing features, fixes, limitations, and validation evidence for this release pass.
- Files changed: CHANGELOG.md, docs/RELEASE_NOTES.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: CHANGELOG.md, docs/RELEASE_NOTES.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: Continue with REL-005 final acceptance review.

- Date: 2026-05-27
- Item ID: REL-005
- Summary: Completed final acceptance evidence mapping and marked release-readiness checklist items complete with objective documentation references.
- Files changed: docs/FINAL_ACCEPTANCE_REPORT.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Tests/validation run: `export KUJO_BIN=/path/to/kujo/target/debug/kujo && "$KUJO_BIN" test` (passed: 23/23).
- Docs updated: docs/FINAL_ACCEPTANCE_REPORT.md, docs/AGENTS_SDK_BUILD_CHECKLIST.md
- Follow-ups: none.

## 10. Known Blockers/Risks
- The Agents SDK repository starts empty, so initial build/test metadata decisions may require alignment with evolving Agents SDK packaging conventions.
- Streaming, cancellation, and timeout semantics depend on available runtime primitives and may require interface-first implementation before full runtime behavior.
- External integrations (MCP/MCT, Dispatch, Watchdog, Scout) may evolve independently, so adapters must remain boundary-driven and version-tolerant.
- Token/cost budget enforcement depth depends on completeness of AI SDK metadata emitted by model calls.

## 11. Final Acceptance Checklist
- [x] `docs/AGENTS_SDK_BUILD_CHECKLIST.md` exists and remained the source of truth.
- [x] Agents SDK is architecturally separate from AI SDK and reuses AI SDK model/provider primitives.
- [x] Basic agent definition and execution work with deterministic result contracts.
- [x] Tool registration, input validation, and unknown-tool rejection are implemented.
- [x] Approval gating and guardrails are implemented and test-covered.
- [x] Session and memory interfaces plus in-memory implementations are implemented.
- [x] Artifacts and tracing/event contracts are implemented with default sinks/stores.
- [x] Budget/limit controls, cancellation, and timeout behaviors are implemented with deterministic errors.
- [x] Handoff primitives and depth protections are implemented.
- [x] Retrieval/RAG integration hooks are implemented with mock/no-network coverage.
- [x] Streaming interface and implementation (or explicit interface-only contract) are documented and tested appropriately.
- [x] Integration boundaries for MCP/MCT, Dispatch, Watchdog, Scout, and hosted commercial layers are documented.
- [x] Tests run offline by default with no live provider keys required.
- [x] Normal failures return structured errors instead of panics.
- [x] Developer documentation and examples provide a clear first-use path.
