# Agents SDK

[![Version](https://img.shields.io/badge/version-1.1.3-black)](https://github.com/kujolang/agents-sdk/releases/tag/v1.1.3)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

Build Kujo agents with tools, approvals, handoffs, retrieval, stores, and budgets.
Agents SDK coordinates the run; your application supplies model callbacks,
credentials, permissions, and persistence backends.

**1.1.3** fixes approval and handoff boundaries, state recovery, storage collisions,
source-text preservation, retries, and token accounting. It keeps the public API
and result shapes. See the [release notes](docs/RELEASE_NOTES.md) for behavior
changes and upgrade guidance.

## Install

Use Kujo **1.6.0 or newer** and Kennel **1.1.0 or newer**:

```bash
kennel add agents-sdk@1.1.3
kennel install
```

The package pins Ability 1.0.1 to an exact Git commit. Installing that dependency
requires Git and GitHub access. Model calls use application callbacks; the SDK
does not install an unpinned AI SDK dependency. Offline examples need no provider
credentials.

## Try the examples

From an Agents SDK source checkout with its dependencies installed:

```bash
kujo run examples/examples_smoke_runner.kujo --interpreter
```

The runner checks seven offline examples: a basic agent, tools, approval denial,
retrieval, handoffs, tracing, and artifacts. Every example reports `ok: true`;
the approval example deliberately returns `status: failed` to prove denial.

Start with [hello_agent.kujo](examples/hello_agent.kujo), then follow the
[developer guide](docs/DEVELOPER_GUIDE.md) to connect model callbacks and tools.
The [example guide](docs/EXAMPLES.md) lists the runnable examples. There is no
separate Agents SDK CLI.

## Runtime and contracts

| Area | What it does | Source |
| --- | --- | --- |
| Core types and errors | Validates agent, message, request, step, and result shapes; returns structured errors | [Core types](src/agents/core_types.kujo), [errors](src/agents/errors.kujo) |
| Runner | Runs chat or streaming callbacks, tools, handoffs, lifecycle events, bounded retries, and stop conditions | [Runner](src/agents/runner.kujo), [stream events](src/agents/streaming/events.kujo) |
| Tools | Registers named tools, checks required/unknown input fields, applies approval gates, and records outputs and artifacts | [Registry](src/agents/tools/registry.kujo) |
| Safety | Evaluates approval policies and guardrails; supports redaction and memory-write policies | [Approval](src/agents/security/approval.kujo) |
| State | Saves and restores run state; stores messages and scoped memory with provenance | [Sessions](src/agents/sessions/store.kujo), [memory](src/agents/memory/store.kujo) |
| Retrieval | Loads context before the model call and carries citations into results and artifacts | [Retrieval](src/agents/retrieval/provider.kujo) |
| Handoffs | Resolves registered targets, bounds depth, and returns child-run evidence | [Handoffs](src/agents/handoffs/handoff.kujo) |
| Artifacts and traces | Stores typed outputs and trace events through replaceable interfaces | [Artifacts](src/agents/artifacts/store.kujo), [tracing](src/agents/tracing/sink.kujo) |
| Budgets | Counts calls, steps, tokens, storage operations, and elapsed time; reports exceeded limits | [Budgets](src/agents/budgets/limits.kujo) |
| Runtime services | Injects clocks and IDs for repeatable tests; checks cancellation at run boundaries | [Clock/IDs](src/agents/runtime/clock_ids.kujo), [cancellation](src/agents/runtime/cancellation.kujo), [events](src/agents/events.kujo) |

The [public index](src/agents/index.kujo) exposes the library modules. Read the
[primitive reference](docs/PRIMITIVES_REFERENCE.md) for constructors, interfaces,
and individual store guides. The runner records session/memory writes, retrieval,
retry counters, budgets, and lifecycle evidence in result metadata.

## Model and integration boundaries

[AI SDK](https://github.com/kujolang/ai-sdk/) owns provider calls and transport
behavior. The [adapter](src/agents/ai/adapter.kujo) maps injected chat/stream
callbacks into model results, validates requested structured output, normalizes
usage, and composes observation hooks.

Agent configs can declare `handler_id`, a versioned `execution_contract`, and
`model_candidates`. These describe compatible handlers and model choices;
provider selection stays with the host or external coordinator.

[Integration adapters](src/agents/integrations/adapters.kujo) cover:

- MCP `2026-07-28` stateless request helpers, routing metadata, tool schemas,
  catalog caching metadata, and input-required results.
- Dispatch hooks and conversion into declarative model-agent definitions.
- Watchdog trace mapping, plus [v2 lifecycle telemetry](docs/WATCHDOG_TELEMETRY.md).
- Scout retrieval enrichment and optional [RAG preferences](docs/RETRIEVAL_PREFERENCES.md).

Hosted operations, authentication, durable backends, and provider permissions
remain application responsibilities. See [integration boundaries](docs/INTEGRATION_BOUNDARIES.md).

## Portable Abilities and context

The [Ability adapter](src/agents/abilities/contract.kujo) projects canonical
`kujo.ability/v1` definitions into tools. Local handlers and gateway tools retain
identity, schemas, definition digests, and receipts. The wrapper validates input
and output JSON Schemas; the application owns permissions, approvals, credentials,
idempotency, and execution policy. Contracts come from the pinned
[Ability package](https://github.com/kujolang/ability), not a copied schema.

[Context contracts](docs/CONTEXT_CONTRACTS.md) describe opt-in content hashes,
context manifests, scoped tools, progressive skill loading, typed handoffs,
verified resume state, and token regression checks. Default payloads remain
unchanged unless these features are enabled.

[Controlled Ability handoffs](docs/CONTROLLED_ABILITY.md) remain experimental
alpha and opt-in. Dispatch owns review and replay admission; SDK correlation
never grants replay permission. Standalone gateway tools remain available.
The separate TypeScript/Python participant SDKs are private and unpublished.

## Limits and compatibility

The local runtime API is stable; integration metadata may gain compatible fields.
The [stability policy](docs/PUBLIC_API_STABILITY.md) and result/event contract tests
cover public shapes and lifecycle behavior.

Budgets, timeouts, and cancellation use cooperative lifecycle checks. Callbacks
must enforce their own per-attempt deadlines and cancellation. Token budgets
include reported usage from failed attempts and retries; missing usage is not
estimated. Cost telemetry uses `cost_cents`, while the generic budget counter
uses `cost_microunits`; automatic conversion is undefined. Enforce monetary
limits in the host/provider layer.

File roots, retention, multiwriter coordination, deployment security, and
provider validation remain host responsibilities. Read the
[security guide](docs/SECURITY_PRODUCTION_GUIDE.md) before connecting live tools.
Offline tests establish local behavior, not live-provider or deployment readiness.

## Verify and contribute

From the source checkout, run the same offline and context gates used by CI:

```bash
export KUJO_BIN=/path/to/kujo
"$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter
bash scripts/ci_no_network_enforcement.sh
bash scripts/verify_context.sh
"$KUJO_BIN" run scripts/context_token_ratchet.kujo --interpreter -- --check
```

The offline gate runs every contract file and expected-output fixture with
network, AI, and process capabilities disabled. This release passes **277 contract
cases and 42 fixtures** on Kujo 1.6.0. Context checks include 20 paired repetitions
and 14 VM/interpreter source executions.

Implementation lives in `src/`, runnable examples in `examples/`, and contracts
in `tests/`. Follow [AGENTS.md](AGENTS.md) for search and fixture rules, and the
[architecture guide](docs/ARCHITECTURE.md) for module responsibilities. Detailed
hardening evidence is indexed in the [audit report](docs/audits/repository-hardening.md).
