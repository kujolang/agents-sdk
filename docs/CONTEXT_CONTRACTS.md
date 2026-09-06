# Context contracts

These additive, opt-in APIs live in `src/agents/context/`. Existing model
messages, provider options, event shapes, approval gates, and ArtifactStore
ownership remain the defaults. They require Kujo 1.3.1 for exact UTF-8 byte
counts. No language syntax changes are involved.

## Observe-only ledger

Pass `context_observer: func(receipt) { ... }` to `create_ai_sdk_adapter`.
Both chat and stream adapters deliver metadata-only `kujo.context-ledger/v1`
receipts after the callback returns. Disable the observer to roll back.
Sink failures are contained and do not change model results. No content is
written automatically. The sink owns persistence and its existing capability
and redaction policy. Secret-typed content rejects observation; it is never
revealed. Treat hashes of sensitive content as restricted metadata too.

The hash covers canonical adapter messages and tool schemas, **not the final
provider wire encoding**. Component bytes and characters count canonical JSON,
including quotes/escaping; estimates use `ai_count_tokens`, not a tokenizer.
Each message, tool schema collection, and assistant output has a hash, source,
load step/reason, parent/component ID, retry number, classification, cacheability,
provider/model, serialization version, measured-token slot, and estimate.
`context_component` accepts explicit attribution for selected skills, loaded
references, repository context, retrieved documents, handoffs, resume state,
and retry duplication. Adapter attribution uses positional `messages/N` keys;
callers must supply truthful kinds/reasons through `context_observation`.
Absent attribution stays role-based; the observer never guesses hidden context.

Provider usage is aggregate, retained only when `usage.usage_source` explicitly
says `provider`. Missing/fixture usage is null, never zero or an estimated
billing claim. Component estimates must not be summed and described as exact
provider attribution. Provider serialization overhead, internal SDK retries,
cache billing and latency need transport/provider evidence; the adapter ledger
makes no such claim. Runner retry attempts are recorded from existing retry
options without adding model payload fields.

## Canonical manifest

`context_manifest_artifact` extends an existing Artifact's metadata with
`context_manifest` and `context_manifest_hash`; it preserves its content.
Entries reference artifacts by ID, SHA-256 and byte count, with source kind
(Scout, Scent, Spec, skill, repository or other artifact), provenance,
selected/available state, classification and `hash_required` freshness.
Use a commit plus a working-tree fingerprint as the revision when dirty.
Branch names alone are not source fingerprints. Callers supply current trusted
provenance; never accept cached provenance as proof of freshness.

`context_validate_manifest` compares current provenance, recomputes the
manifest hash and fetches every selected reference. Missing, changed or forged
selected artifacts fail closed. Available but unselected entries do not load.
`context_store_value` persists canonical JSON through the existing ArtifactStore
and verifies it by reading it back. `context_fetch` returns exact evidence after
checking ID/hash/bytes; it does not execute source labels or resolve arbitrary
filesystem paths. Full evidence remains in the existing store.

## Typed handoff and structured resume

`context_validate_handoff` checks the complete `kujo.handoff/v1` contract:
task ID, objective, constraints, relevant files, required evidence, decisions,
unresolved questions, produced artifacts, test commands, result hashes, allowed
capabilities and next action. Strings are bounded; large evidence is represented
by verified ArtifactStore references. Capabilities must be a subset of a trusted
caller-supplied ceiling. This validation is not a grant of host permissions.

`context_save_resume` extends SessionStore run state with `context_resume`
and `context_evidence`, retaining full evidence separately in ArtifactStore.
`context_load_resume` validates every referenced outcome/result and compares
all current source hashes before returning compact state. State includes completed
steps, decisions, source hashes, test outcome references, tool result references,
current failure, retry count, remaining steps and next action. It never silently
reuses stale state. A caller must reload/replan on `stale_source` or
`stale_context`. Existing unversioned session state remains readable through
the original SessionStore API; it cannot impersonate verified compact state.

## Scoped tools and repository sources

`context_scope_tools` returns a deterministic registry containing only explicitly
selected names whose declared permissions fit the caller's capability ceiling.
It preserves handlers and approval metadata. `context_tool_catalog` exposes
bounded summaries and stable content-derived schema IDs. `context_tool_schemas`
expands those IDs, rejecting stale or unknown schemas. Full schemas remain the
fallback for providers requiring them. Registry scoping complements existing
runtime/approval gates; it cannot constrain arbitrary effects inside trusted
handlers beyond Kujo's own capabilities.

`context_tool_output` returns a bounded caller-sanitized summary plus a verified
reference to full output. No automatic lossy summarizer is used.
`context_repository_select` consumes a `kujo.repository-index/v1` adapter view
of existing structural outputs: revision plus files keyed by path with symbols,
imports, dependencies and artifact references. It follows forward and reverse
dependencies to a bounded fixed point and validates exact source references.
Paths are data, never shell commands. This module does not replace Scout's
index or create a semantic/vector index; producers supply the structural view.
