# Integration and Product Boundaries

This document defines what belongs inside the open, local-first Agents SDK and what belongs in optional hosted or commercial layers.

## Principles

- Keep core runtime primitives local-first and offline-capable by default.
- Keep provider and product integrations behind explicit adapter contracts.
- Keep hosted/team/commercial features additive and out of core runtime contracts.
- Preserve deterministic behavior for tests and local development.

## Boundary Matrix

| Capability Area | In-SDK Responsibility (Local/Open) | Hosted/Commercial Responsibility (Optional) |
| --- | --- | --- |
| Agent execution | Deterministic runner contracts, lifecycle state, stop conditions, and event schemas | Fleet scheduling, multi-tenant orchestration, hosted run management |
| Model access | AI adapter boundary contracts, normalized model result mapping, and additive agent-side routing metadata | Managed provider routing, hosted credential brokerage, dynamic model policy controls |
| Tooling | Tool registry contracts, validation, approval/guardrail policy hooks, and pinned canonical Ability-to-Tool projection | Centralized Ability catalogs, team-level policy distribution, remote execution gateways, hosted audit dashboards |
| Sessions and memory | Session/memory interfaces and local in-memory implementations | Cross-organization persistence, hosted retention policy automation, account-level backups |
| Retrieval and context | Retrieval provider contracts, mock fixtures, context/citation schemas | Hosted index lifecycle, enterprise corpus sync, managed retrieval ranking pipelines |
| Observability | Trace/event schema contracts and local sinks/adapters | Hosted aggregation, alerting, incident dashboards, long-term analytics |
| Integrations | Adapter boundaries (MCP/MCT, Dispatch, Watchdog, Scout) | Managed connectors, proprietary orchestration logic, tenant-specific routing rules |
| Security controls | Approval, guardrail, redaction, and budget policy contracts | Organization policy governance UI, SSO/RBAC, compliance automation and attestations |

## Anti-Goals for Core SDK

- No hard dependency on hosted backends for default test or runtime paths.
- No embedding of product billing, tenancy, or account lifecycle logic in core modules.
- No hidden network requirements for baseline contract/integration tests.

## Extension Guidance

- Add new hosted capabilities through adapter interfaces, not direct imports into core modules.
- Keep hosted-only metadata additive and optional in payloads.
- When adding fields, preserve backward compatibility and deterministic defaults.
- Local orchestrators may make deterministic route decisions, but provider catalogs remain AI SDK/platform inputs and must not be embedded into Agents SDK runtime policy.

## Explicit Integration Contracts

### MCP/MCT Tool Providers

- Core boundary: `src/agents/integrations/adapters.kujo` via external tool provider adapter contracts.
- In-SDK role: normalize catalog/invocation contracts and preserve deterministic error mapping. MCP `2026-07-28` support is limited to stateless JSON-RPC request envelopes, required per-request metadata, Streamable HTTP routing headers, tool-list cache metadata, input-required tool-call normalization, unsupported-version error envelopes, and lossless tool schema/display metadata mapping into registry contracts.
- Out-of-SDK role: connector auth, hosted tool routing, tenant-level catalog management.

### Dispatch

- Core boundary: dispatch integration hooks contract in `src/agents/integrations/adapters.kujo`.
- In-SDK role: receive hook payloads and preserve runner/tool lifecycle semantics.
- Out-of-SDK role: workflow orchestration UX, hosted schedule/queue control, cross-tenant operations.

### Watchdog

- Core boundary: watchdog trace adapter in `src/agents/integrations/adapters.kujo`.
- In-SDK role: deterministic event-to-trace transformation contracts.
- Out-of-SDK role: hosted monitoring dashboards, alerting, retention/compliance analytics.

### Scout

- Core boundary: scout code-context provider and retrieval enrichment mapping.
- In-SDK role: context ingestion contract shape and retrieval enrichment mapping.
- Out-of-SDK role: managed indexing, repository federation, hosted ranking/tuning services.

### Hosted/Commercial Product Layers

- Must remain additive and optional.
- Must not be required by default runner/test flows.
- Must use adapter contracts rather than direct core-runtime coupling.

Examples:

- Hosted policy control planes should write policy payloads consumed by approval/guardrail interfaces.
- Hosted run managers should orchestrate `run_agent` boundaries externally, not modify runner internals.
- Hosted observability should ingest trace/event outputs from sink contracts rather than bypassing contracts.
