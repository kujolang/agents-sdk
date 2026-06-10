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

## Redaction and Trace Hygiene

- Configure redaction policy for sensitive fields in payloads.
- Avoid logging raw secrets in tool outputs or trace payloads.
- Persist only minimal metadata needed for debugging/auditing.

## Timeout and Iteration Hardening

- Set timeout_ms for all deployed runs.
- Keep max_iterations bounded to prevent runaway loops.
- Enforce budget limits for tokens, cost, steps, and elapsed time.

## Session and Memory Hardening

- Restrict memory write scopes by policy.
- Keep memory provenance metadata for auditability.
- Validate session restore/save boundaries in integration tests.

## Operational Checklist

- Validate full offline test suite passes with provider keys unset.
- Validate example smoke tests pass in isolated environment.
- Validate artifacts/traces do not contain sensitive fields.
- Validate release notes and API stability markers are updated.
