# Release Notes

## 1.1.3 — 2026-10-13

This patch release hardens the local agent runtime without changing public API
signatures or result shapes. Use Kujo 1.6.0 or newer and Kennel 1.1.0 or newer.
Ability 1.0.1 remains pinned to an exact Git commit.

### Fixes

- Preserve host approval authority through tools and handoffs; enforce step,
  handoff, context, and spool limits at the relevant boundaries.
- Preserve resume state when a store read fails. Delete session snapshots even
  when no session record was created, and release deleted payloads.
- Prevent automatic memory/artifact IDs from replacing existing records.
  Publish automatic file artifacts without overwriting existing files.
- Preserve retrieved source text and tool-emitted artifact content, including
  indentation and trailing newlines. Reject malformed RAG citation identities
  with a structured error.
- Run model retries without growing the call stack. Count reported token usage
  from every attempt, including failed retries, rejected structured output and
  failed stream responses.
- Materialize only requested memory, artifact, and trace pages; avoid pagination
  overflow. Deduplicate skill loads and count artifact bytes directly.

### Upgrade notes

Install with `kennel add agents-sdk@1.1.3`, then `kennel install`.

Corrected checks can reject runs previously admitted through a bug. Preserved
whitespace can increase artifact byte counts; trim at the producer only when
that is intended. Run-level token counters can rise because failed attempts now
count. Final model results retain their own per-response usage. Retry ceilings
and cooperative lifecycle budget checks remain unchanged.

Cost telemetry uses `cost_cents`, while the generic budget counter uses
`cost_microunits`. Automatic conversion is undefined; enforce monetary limits
in the host/provider layer. Controlled Ability handoffs remain experimental
alpha, and Dispatch retains replay/admission authority.

### Verification

On released Kujo 1.6.0: 277 contract cases, 42 fixtures, module exports, canonical
examples, context checks (20 paired repetitions and 14 VM/interpreter source
executions), token/hash ratchets, and artifact guards pass. No fixture or context
baseline was rewritten. See the [audit index](audits/repository-hardening.md)
for measured behavior and before/after evidence. No live-provider claim is made.

Earlier releases are recorded in [CHANGELOG.md](../CHANGELOG.md).
