# Security and Operational Guidance

## Safe Defaults

- Use no-network fixtures in development and CI by default.
- Prefer explicit allowlists for tools and permissions.
- Keep approval policies active for write/high-risk tool paths.
- Keep deterministic timeout and budget limits configured.

## Dangerous Tool Controls

- Mark write-capable tools with write/delete/update permissions.
- Apply approval mode write_tool or permission_based for mutation flows.
- Use deny_all providers in locked-down environments.
- Keep unknown tool rejection enabled (default runner behavior).
- An omitted approval mode retains `always_allow` for compatibility. An
  explicitly invalid mode denies execution; spell policy modes exactly.
- Failed/throwing approval providers never authorize handlers. Malformed or
  throwing configured guardrail matchers block their evaluated stage.
- External tool `risk` (or legacy `risk_level`) maps to registry risk. Metadata
  annotations alone do not grant permissions or constitute an approval policy.

## Redaction and Trace Hygiene

- Configure redaction policy for sensitive fields in payloads.
- Avoid logging raw secrets in tool outputs or trace payloads.
- Persist only minimal metadata needed for debugging/auditing.

## Timeout and Iteration Hardening

- Set timeout_ms for all deployed runs.
- Keep max_iterations bounded to prevent runaway loops.
- Enforce budget limits for tokens, cost, steps, and elapsed time.
- Tool-call/step budgets are checked against the next tool before invocation.
  Timeouts remain cooperative boundary checks, not preemption of callbacks.
  Model retries run within their configured retry ceiling; transport callbacks
  must enforce per-attempt deadlines and cancellation themselves.

## Session and Memory Hardening

- Restrict memory write scopes by policy.
- Keep memory provenance metadata for auditability.
- Validate session restore/save boundaries in integration tests.
- In-memory stores are process-local and retain records until reset/deletion;
  deploy bounded host-managed stores for long-running or multi-tenant services.
- Use private, application-owned directories for files and JSONL logs. Leaf
  validation does not defend against an attacker who can replace the root or
  its filesystem entries concurrently.
- Retrieval context is injected as a system message by the established runner
  contract. Providers must select trusted context; retrieved content is not an
  authorization source. Tool permissions remain host-controlled.
- The optional output sanitizer retains original output on failure for backward
  compatibility. Use an enforcing host boundary for mandatory redaction.

## Operational Checklist

- Validate full offline test suite passes with provider keys unset.
- Validate example smoke tests pass in isolated environment.
- Validate artifacts/traces do not contain sensitive fields.
- Validate release notes and API stability markers are updated.
