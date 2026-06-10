# Agents SDK Architecture

## Purpose

This document describes module responsibilities, runtime data flow, and extension boundaries for the Agents SDK.

## Design Principles

- Keep default execution local-first and deterministic.
- Keep provider logic outside core runtime modules.
- Keep contracts explicit, additive, and test-covered.
- Keep no-network fixtures available for all core paths.

## Module Responsibilities

| Module | Responsibility |
| --- | --- |
| src/agents/core_types.kujo | Core contracts for agents, messages, steps, requests, contexts, results |
| src/agents/errors.kujo | Structured error model and deterministic error kinds |
| src/agents/events.kujo | Lifecycle event schema, creation, and shape validation |
| src/agents/runner.kujo | Orchestration loop, stop conditions, retries, streaming, handoffs, lifecycle integration |
| src/agents/ai/adapter.kujo | Boundary to AI SDK chat/stream primitives and response normalization |
| src/agents/tools/registry.kujo | Tool registry contracts, input validation, execution context, approval/sanitizer hooks |
| src/agents/security/approval.kujo | Approval policies, guardrails, redaction, memory write policy controls |
| src/agents/sessions/store.kujo | Session and run-state persistence contracts and in-memory implementation |
| src/agents/memory/store.kujo | Memory contracts, scope handling, query/write/delete behaviors |
| src/agents/retrieval/provider.kujo | Retrieval provider contracts, context/citation schemas, mock retrieval fixtures |
| src/agents/handoffs/handoff.kujo | Handoff request/result contracts and loop/depth controls |
| src/agents/tracing/sink.kujo | Trace-event schema plus in-memory/JSONL sinks |
| src/agents/artifacts/store.kujo | Artifact contracts plus in-memory/file-backed stores |
| src/agents/budgets/limits.kujo | Budget contracts, usage counters, deterministic limit evaluation |
| src/agents/streaming/events.kujo | Stream-event contracts and AI stream-event mapping |
| src/agents/integrations/adapters.kujo | Boundary adapters for external systems (MCP/MCT, Dispatch, Watchdog, Scout) |
| src/agents/testing/no_network.kujo | Deterministic offline fixture builders for model/retrieval/tool harnessing |

## Runner Lifecycle

1. Validate agent and runtime configuration.
2. Build run context, start lifecycle event stream, and resolve policies/providers.
3. Inject retrieval context when enabled.
4. Execute model request (stream or non-stream) through AI adapter boundary.
5. Resolve and execute model-emitted tool calls through registry contracts.
6. Apply approval and guardrail decisions before sensitive operations.
7. Optionally execute handoff to a target agent.
8. Persist output artifacts/session state/memory writes.
9. Enforce timeout and budget checks at lifecycle boundaries.
10. Emit deterministic terminal status and structured run result.

## Data Flow

- Input:
  Agent + AgentRunRequest + options
- Processing:
  Runner -> AI adapter -> model result -> tool/retrieval/handoff hooks -> lifecycle persistence
- Output:
  AgentRunResult with stable metadata (events, budgets, retrieval, handoff, artifacts, stream telemetry)

## Extension Interfaces

- Model/provider extensions: src/agents/ai/adapter.kujo callbacks.
- External tool catalogs: src/agents/integrations/adapters.kujo tool provider adapter.
- Workflow orchestration handoffs: src/agents/handoffs/handoff.kujo + runner handoff registry.
- Observability and auditing: src/agents/tracing/sink.kujo and event contracts.
- Retrieval extensions: src/agents/retrieval/provider.kujo provider interface.

## Compatibility Notes

- Contract keys are intended to evolve additively.
- Experimental integration payloads remain explicitly marked in docs.
- No hosted/commercial assumptions are required for default runtime/test execution.
