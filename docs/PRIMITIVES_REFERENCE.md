# Runtime Primitives Reference

Focused primitive pages:

- docs/primitives/sessions.md
- docs/primitives/memory.md
- docs/primitives/guardrails-and-approvals.md
- docs/primitives/artifacts.md
- docs/primitives/tracing.md
- docs/primitives/handoffs.md
- docs/primitives/retrieval.md

## Sessions

- Module: src/agents/sessions/store.kujo
- Contracts: Session, SessionState, SessionMessage, SessionStore
- Default implementation: in-memory session store with deterministic ordering

## Memory

- Module: src/agents/memory/store.kujo
- Contracts: MemoryEntry, MemoryQuery, MemoryQueryResult, MemoryStore
- Default implementations: noop memory store and in-memory scoped store

## Guardrails and Approvals

- Module: src/agents/security/approval.kujo
- Contracts: ApprovalPolicy, ApprovalRequest, ApprovalDecision, ApprovalProvider
- Guardrail support: stage-aware pass/warn/block outcomes
- Built-ins: blocked terms, max input length, risk thresholds, output size limits

## Artifacts

- Module: src/agents/artifacts/store.kujo
- Contracts: Artifact, ArtifactStore, ArtifactKind
- Implementations: in-memory and file-backed stores

## Tracing

- Module: src/agents/tracing/sink.kujo
- Contracts: TraceEvent, TraceSink
- Implementations: in-memory sink and JSONL sink

## Handoffs

- Module: src/agents/handoffs/handoff.kujo
- Contracts: HandoffRequest, HandoffResult, HandoffPolicy
- Safety: loop-state depth and visited-target controls

## Retrieval

- Module: src/agents/retrieval/provider.kujo
- Contracts: RetrievalQuery, RetrievedContext, RetrievalCitation, RetrievalResult
- Default fixture: deterministic mock retrieval provider

## Budgets and Timeouts

- Module: src/agents/budgets/limits.kujo
- Contracts: AgentBudget, BudgetUsage, BudgetLimitPolicy
- Runner integration: lifecycle checks before/after model, artifact, and memory stages
