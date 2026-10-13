# Agents SDK hardening: repeat pass

- Repository: `kujolang/agents-sdk`.
- Branch: `main`.
- Starting SHA: `1b408314f767d5f3e6db8384aad82464118100f7` (the merged first pass).
- Ending implementation SHA: `26830aca6c858e312186c394ac304afe06fc936d`; the report commit
  is discoverable with `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-12-repeat.md`.
- Scope: the tracked repository in the existing managed worktree. The original
  detached checkout and its 11 untracked maintenance-agent files were excluded
  from reads/edits relevant to implementation and remain untouched.

This is a fresh baseline and follow-up implementation review, building on the
[first pass](repository-hardening-2026-10-12.md). It concentrates new experiments
on persistence failure handling, context admission work and memory pagination.
It does not claim exhaustive vulnerability elimination or live-provider testing.

## Ground truth and coverage

Read README, AGENTS, developer/examples, public API stability, security,
integration and context contracts, the previous audit, package/lock files and CI.
Reviewed the runner's approval/store/budget boundaries, memory/session/artifact
stores, context modules, approval/cancellation, AI adapter, controlled Ability,
RAG/MCP/Dispatch adapters, streaming and lifecycle/Watchdog observation, with
existing contract coverage. Canonical examples remain direct and unchanged.
Main sweeps excluded expected-output `tests/*.out`, generated/dependency paths
and the historical `docs/AGENTS_SDK_BUILD_CHECKLIST.md` (absent at this revision).
Fixtures were executed as contracts, not refreshed. No stale TODO/FIXME/HACK
markers were found in the scoped source/script/example sweep.

Released Kujo **1.6.0**, the CI pin, was used throughout. The previously verified
binary and exact Ability package remain installed in the managed worktree.
Ability 1.0.1 is the only declared runtime dependency, pinned in both manifest
and lock at `4aa354da8d02b027c459f692f69b523f96e97056`. No dependency was added,
removed or updated. AI SDK is a callback boundary; Dispatch, Watchdog, Scout,
MCP and RAG remain integration boundaries. Read-only targeted searches found
no direct uses of the changed memory-query/resume functions in the inspected
Dispatch/AI SDK source directories; compatibility does not rely on that absence.

| Verification | Before | After |
| --- | --- | --- |
| Offline gate | 42 checks, zero failures | 42 checks, zero failures |
| Contracts | 41 files, 247 cases, all passed | 41 files, 255 cases, all passed |
| Fixtures | 42/42 passed | 42/42 passed |
| Context evaluation | 20 paired repetitions; 14 VM/interpreter executions passed | Passed unchanged |
| Context token/hash ratchet | Passed, no warnings or regressions | Passed unchanged |

No tracked baseline failures were found. The default shell Kujo is not the CI
runtime; all authoritative commands set `KUJO_BIN` or use `.tmp/runtime/kujo`.
There is no configured standalone native build, lint/formatter/typecheck or live
E2E command. Existing contract/fixture/example/VM-interpreter gates are the
applicable build and behavior checks. No live credentials or endpoints were used.

## Implemented changes

| Problem | Root cause and implementation | Files / regression evidence | Compatibility |
| --- | --- | --- | --- |
| P1: resume save could replace a checkpoint after a reported read failure | Missing state and storage failure were both treated as an empty map. Return an explicit read error before writing evidence or saving replacement state. | `context/state.kujo`; a failing read with write callbacks that throw reproduced an unwanted save. Tests also preserve unrelated host checkpoint fields and verify subsequent resume. | Missing state without an error still supports first save. Adapters must report operational failures with `error`; no new SessionStore interface. |
| P2: oversized handoff/resume triggered evidence reads before rejection | The existing 32,768-byte gate followed the reference loop. Check array shape, JSON serializability and canonical UTF-8 size before any evidence lookup. | `context/state.kujo`; resume and handoff tests throw if a read occurs. Malformed/non-JSON evidence returns structured errors. A 400-reference experiment drops reads from 400 to zero with the same final size error. | Same size ceiling and versioned schemas. Oversized input now reports the size failure before a missing/stale reference; valid evidence still receives full integrity checks. |
| P2: failed memory queries discarded actionable error details | Wrapper reconstructed the result without copying its provider error. Preserve `error` only on failed results. | `memory/store.kujo`; regression retains error kind, message and retryability details. | Additive failed-result field; successful shapes, counts, provenance and metadata unchanged. No callback error is relabeled as success by this change. |
| P2: paginated memory queries copied all matches and repeatedly scanned dictionary keys | Count every match while materializing only the selected page; replace the private interpreted membership loop with native `has_key`. Avoid offset-plus-limit arithmetic. | `memory/store.kujo`, `benchmark_memory_page.kujo`; page tests cover scopes/tags/text, deletion/order, totals, nested value isolation, zero limit and oversized offset. Exact benchmark result hashes match. | Full matching counts and page provenance remain intact; `limit: 0` still means an empty memory page. JSON conversion of selected results is retained. |

Eight regression cases were added to the existing suites; the existing CI glob
runs them automatically. Four initial cases failed on the starting code and
passed after correction. An initial test-only immutable binding/index-assignment
error was corrected before accepting regression evidence. No fixture or token
baseline was changed; no timing threshold was added to CI.

## Measured performance and resource work

The repeatable workload seeds 160 records, each with 1,024 repeats of
`memory 🌍 `, then performs twelve queries with offset 80, page size two and a
tag filter. Seeding is outside the script's query timer. The comparison harness
embeds either the exact starting or final memory module with the same workload,
alternates before/after three times and measures child-process user+system CPU
with Python `resource.getrusage`. CPU includes startup and seeding. Evidence:
`.tmp/audit-repeat/paired-benchmark.json` and `isolated-{before,after}.kujo`.

| Measurement | Before samples | After samples | Median before → after |
| --- | --- | --- | --- |
| Process CPU seconds | 8.728, 6.953, 9.132 | 3.698, 3.803, 3.966 | **8.728 → 3.803** |
| Query wall milliseconds | 11088, 6047, 17269 | 3015, 9255, 5082 | 11088 → 5082 |
| Oversized resume evidence reads | 400 | 0 | Same `resume_too_large` result |

The host had substantial unrelated CPU activity. Wall timings are noisy (one
paired optimized wall sample is slower); these are local workload measurements,
not application latency guarantees. Earlier exploratory timing batches are kept
in `.tmp/audit-repeat/memory-{before,baseline,optimized}*`; they are not pooled
with the alternating comparison. The final benchmark includes both native lookup
and page materialization changes, not pagination alone.

All benchmark results have SHA-256
`3c2d9da82ba7a431cbe48b16e43382815c4685752e0a52737cecbed4df7db8b0`.
Source-supported allocation improvement: the query no longer builds a list of
all matching serialized records or an interpreted keys array per membership
check. No RSS, allocation-count or production-throughput claim is made.

Model payloads, schemas, prompts and estimated-token baselines are unchanged.
No additional model-token savings are claimed. Normal verification still emits
concise receipts with detailed local logs, and no new runtime output was added.
Package/dependency surface and file formats are unchanged. Binary/build-size
measurements are not relevant to this source library's empty build command.

## Trust, state, compatibility and remaining work

- Host-configured callbacks, skill catalogs, tool registrations and capability
  ceilings remain authority; model/retrieval content does not acquire new rights.
  Existing approval, handoff, cancellation, receipt identity, path/extension,
  UTF-8 quota, redaction and corruption regressions remain active.
- Read failures no longer authorize a resume overwrite. Generic SessionStore
  read/merge/write is still not a concurrent compare-and-swap operation; host
  adapters own transaction/serialization policy. Documentation now says so.
- Envelope admission avoids external evidence I/O for over-limit inputs. It
  still serializes the already-supplied value to measure it; this is not a bound
  on caller-side parsing/allocation or callback latency.
- In-memory stores remain process-local and explicitly reset/deleted by hosts.
  No cache, hidden retention policy, async worker, retry or networking was added.
  File roots and concurrent writers remain host responsibilities. Existing
  cooperative timeout and fail-open observation contracts are preserved.
- Public export names/signatures, CLI behavior, versioned schemas, persistence
  formats, config, environment variables and package interfaces are unchanged.
  The public result API changes additively: failed memory-query results gain a
  provider `error` when present. Consumers
  see intentional stricter handling of failed reads and earlier size rejection.
- No cross-repository changes, dependency release or consumer migration is
  required. No external advisory/latest-version claim is made.

Remaining classifications: **P0/P1/P2: none established and left unresolved in
this pass. Needs more evidence:** production-wide latency/RSS effects, live
provider behavior and host-specific concurrent persistence. **Not worth changing:**
blanket removal of JSON round trips (they also define serialization behavior),
broad runner rewrites, dependency substitution and stylistic example churn.
These are scope/measurement limitations, not newly discovered open defects.
SignalBox: no captures warranted.

## Commands and evidence

All implementation and verification ran in the managed worktree. Read-only
inspection used `git fetch/status/rev-parse/log`, `rg --files`, scoped `rg -n`,
`cat`, `sed`, and `git diff`. Exact primary verification commands:

```bash
.tmp/runtime/kujo --version
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-repeat/persistence_tests.kujo -v
.tmp/runtime/kujo test-run tests/context_state_tests.kujo -v
.tmp/runtime/kujo test-run tests/memory_store_contract_tests.kujo -v
.tmp/runtime/kujo run scripts/benchmark_memory_page.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-repeat/isolated-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-repeat/isolated-after.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-repeat/evidence-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-repeat/evidence-after.kujo --interpreter
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 1b408314f767d5f3e6db8384aad82464118100f7 HEAD
```

The initial four-case regression command intentionally failed; targeted fixed
suites passed. The embedded-source probes were generated from `git show
1b40831:src/agents/{memory/store,context/state}.kujo` and the corresponding final
files, with identical workload bodies and distinct probe variable names to avoid
Kujo module/global binding collisions. All raw samples, before/after regression
logs and main gate receipts remain in `.tmp/audit-repeat/`. Offline per-test logs
and context VM/interpreter evidence remain in the gate's receipt directories.

Final evidence: baseline logs `.tmp/offline-checks.ceGVJV/`, final logs
`.tmp/offline-checks.Sxx2QZ/`, gate receipts in `.tmp/audit-repeat/`, context
evidence in `.tmp/context-evaluation/`. Exports and examples passed explicitly;
shell syntax, diff hygiene and the committed artifact guard passed. The shipped
benchmark command also produced the same result hash. SHA-256 verification of
all 11 maintenance-agent files matched the pre-merge manifest; their original
untracked status and detached checkout were preserved. Implementation commits:
`5853226` (context persistence/admission), `26830ac` (memory queries).
