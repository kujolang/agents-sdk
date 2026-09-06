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

## Progressive skills

`context_load_skills` accepts a trusted, versioned catalog and explicit selected
IDs, trigger IDs and capabilities. Each skill declares its core artifact,
optional reference triggers, capabilities, always-required security artifacts,
size estimate, metadata hash, test IDs and dependencies. Loading verifies hashes,
rejects cycles/depth overflow and loads core plus every security rule before
returning. Exact triggers add optional references; prose, forged headings and
repository instructions cannot activate triggers. Missing required context is
an error. Hashes prove integrity against trusted references, not authenticity
of an attacker-supplied catalog; pin catalog provenance through the manifest.

## Runner opt-in and dispatch evidence

Pass `context` in run options to enable preparation. Supported keys:
`capabilities`, `tool_names`, `manifest_artifact`, `current_provenance`,
`selected_skills`, `skill_catalog`, `reference_triggers`, `resume`, `state`,
`current_source_hashes`, `schema_on_demand`, `supports_schema_on_demand`, and
`expected_dispatch`. Stores use the existing `artifact_store`/`session_store`
options. No `context` key preserves the original run path.

A supplied `state` is validated before dispatch and saved after execution with
updated completion/retry/failure facts and full result evidence. `resume: true`
loads and validates it before constructing a compact user message. Durable
state is never treated as system instructions. Persistence failure is visible in
`metadata.context_state_saved` and `context_state_error`; callers must inspect
this before promising resumability. Remaining steps and decisions are caller
owned; the runner does not invent progress.

Pass `context_handoff` to replace parent-output replay with a validated typed
envelope plus a parent evidence reference. The existing depth/visited-target
checks, handoff events and target selection remain active. Typed children inherit
approval/cancellation controls and scoped capability ceilings, but not parent
resume state or parent dispatch expectations. Parent and child evidence remain
available through references on handoff metadata. Without `context_handoff`,
legacy parent-output handoffs remain unchanged.

Full schema expansion is the default. On-demand mode requires the explicit
`supports_schema_on_demand` adapter contract: the application must implement
schema fetch and model continuation through `context_tool_schemas`. This runner
does not invent a provider discovery protocol or claim it is universally
supported. Use the default complete schemas when no such application exists.

Opt-in results include `context_dispatch_receipts` built from actual paired
model lifecycle events, successful tool results, verified skill loads and
completed handoffs. Task roles can use `agent.metadata.execution_role`; the
existing `agent.role` remains a message-role field. Receipts prove that the
configured role's agent reached its execution boundary, not that its reasoning
was correct. `expected_dispatch` entries (`kind`, `component_id`, `status`)
fail the run with `dispatch_mismatch` when required execution was not observed.
Denied tools do not produce successful-execution receipts. Child receipts and
full child evidence are retained on typed handoffs. These are local audit
receipts, not signed remote attestations; only trust runtime-produced results.

## CI ratchet and evaluation

Run `KUJO_BIN=/path/to/kujo bash scripts/verify_context.sh`, then
`kujo run scripts/context_token_ratchet.kujo --interpreter -- --check`. The committed
baseline includes instructions, normalized paired payloads, tool schemas/catalogs,
skill views, handoffs, resume, retry duplication and provider usage fixtures.
Bytes/characters/heuristic estimates remain separate from provider-specific
fixture columns. A 5% warning and 10% hard-growth threshold supplement strict
payload-hash/inventory drift checks. There are no timestamps, random IDs,
absolute machine paths or logs in the normalized baseline. Diagnostic stderr is
retained separately from program stdout in evaluation artifacts.

Approved growth is explicit, after verification:

```bash
kujo run scripts/context_token_ratchet.kujo --interpreter -- \
  --approve-growth "Explain required growth and reliability evidence" \
  .tmp/context-evaluation/report.json
```

Review both baseline and approval JSON diffs. The approval links the new baseline
hash to verified evaluation evidence; CI never updates baselines automatically.
Thresholds are initial regression guards, not statistically calibrated production
budgets. The corpus repeats seven synthetic edit tasks 20 times, compares exact
current/compact outcomes, and executes current and optimized fixture programs
under VM and interpreter. Dedicated runner tests cover real handoff, retry,
resume, tool, approval and dispatch boundaries. Adversarial tests cover missing
safety, forged state/hashes/headings, control characters and stale sources.

The committed evaluation is reproducible offline contract evidence. It does not
measure real model quality, live-provider latency/billing, or prove production
savings. Provider token counts, cost and latency remain null when unavailable.
Roll out compact paths only after application-specific replay/task acceptance
checks; keep the default full-context path for applications without that evidence.
