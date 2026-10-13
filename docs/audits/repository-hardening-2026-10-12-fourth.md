# Agents SDK hardening: session cleanup and trace pagination

- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `95f66d02b09494bad35db9b1302bcf817d9a85e7`, matching freshly fetched `origin/main`.
- Ending implementation: `68776a6`; session fix: `92afbd6`.
- The report-only delivery commit is discoverable with
  `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-12-fourth.md`.
- Write scope: existing managed Agents SDK worktree. Original detached checkout
  and maintenance-agent files are excluded and preserved.

This is a fresh pass after the [third audit](repository-hardening-2026-10-12-third.md).
No intervening remote-main changes were present. The SDK remains a local-first
agent orchestration library: AI SDK execution is injected through callbacks,
Ability is the single pinned package, and Dispatch/Watchdog/MCP/RAG remain adapter
boundaries rather than implicit execution authorities.

## Ground truth

Reread the attachment, README, AGENTS, developer and example guidance, package
manifest/lock, CI, architecture, public stability and security/integration docs.
Reviewed persistence lifecycles and their runner callers, in-memory/JSONL tracing,
trace filtering, redaction and metadata-only telemetry, model callback failure
mapping, cancellation, budgets, context views/dispatch, progressive skill loading
and context ratchets. Broad source searches cover error/I/O/retry boundaries,
loops, repeated serialization, overflow-prone pagination and TODO markers.

Main searches exclude generated/dependency paths, `tests/*.out`, maintenance
work and the absent historical build checklist. Expected-output fixtures were
executed without editing. Prior reports establish historical changes; new claims
below are backed by fresh baseline, reproducer and final receipts.

Kujo **1.6.0** is the CI-pinned released runtime used throughout. Ability remains
1.0.1 at `4aa354da8d02b027c459f692f69b523f96e97056`; manifest/lock and installed
package are unchanged from the prior verified pass. Running `git rev-parse` inside
the package resolves the parent SDK checkout, so it is not dependency evidence.
No dependency update, sibling modification or coordinated release is required.
There is no separate configured build, lint, formatter, static typecheck or live
E2E gate; the manifest build command is empty. No latest-advisory or live-provider
readiness claim is made.

## Baseline and final verification

| Gate | Before | After |
| --- | --- | --- |
| Offline checks | 42, zero failures | 42, zero failures |
| Contract files / cases | 41 / 261 | 41 / 263 |
| Fixtures | 42/42 | 42/42 |
| Context evaluation | 20 paired repetitions, 14 VM/interpreter source executions passed | Same complete gate passed |
| Token/hash ratchet | No warnings or regressions | No warnings or regressions |
| Exports / canonical examples | Covered by baseline contracts | Explicit checks passed |

Baseline log directory: `.tmp/offline-checks.sj2BrB/`. Full receipts and temporary
experiments live under `.tmp/audit-fourth/`. No tracked baseline failures were
found; two new behavioral regressions failed before implementation.

## Changes and compatibility

| Priority / problem | Root cause and fix | Evidence / affected files | Compatibility |
| --- | --- | --- | --- |
| P1: deleting a session left runner-only snapshots retrievable | The runner saves run state without separately creating a Session record, but deletion gated cleanup only on session identifiers. Admit stored run-state identifiers to the same cleanup path. | `sessions/store.kujo`; regression observed `get_run_state.ok:true` after deletion before the fix, false afterward. Session contracts now cover isolation, recreation, fresh saves and absent IDs. Runner integration executes two turns, deletes state, then verifies the third turn does not restore it. | Public signatures and result shapes unchanged. Deleting an ID with only saved run state now succeeds and clears it. Previously created sessions keep their existing deletion/recreation and ordering behavior. |
| P2: large valid trace pagination arguments raised integer overflow, and small pages rebuilt all matches | `offset + limit` overflowed; the list built an entire intermediate array before slicing. Count all matches and materialize only selected records without summing offset and limit. | `tracing/sink.kujo`; before-fix probe throws on offset 1 and maximum integer limit; after returns the remaining two records. Expanded trace coverage checks filters, totals, insertion order, value isolation, maximum offsets, zero/invalid limits and no matches. | Counts remain total matches, ordering unchanged, zero/omitted/invalid limit remains unlimited. JSONL behavior is unchanged. Large supported integers now produce a valid page rather than an exception. |

Two cases were added to existing contract files and an existing runner integration
case was extended; CI automatically includes them. Primitive docs describe the
cleanup boundary and trace pagination. `scripts/benchmark_trace_page.kujo` provides
a deterministic workload; no flaky timing threshold or fixture rewrite was added.

Public exports, CLI behavior, JSON/file formats, schemas, config and environment
variables are unchanged. External consumers only observe corrected deletion and
large-page behavior. No migration is required.

## Measurements

The workload seeds 120 trace records with fixed IDs/timestamps and 128 repeats of
`evidence 🌍 ` in each payload, then performs eight filtered queries at offset 60,
limit two. Before/after scripts embed the exact source modules with identical
workloads and alternate three times on the same released interpreter. Query wall
time excludes seeding; child user+system CPU includes startup and seeding.

| Variant | Query wall time (ms) | Process CPU (s) | Median CPU |
| --- | --- | --- | --- |
| Before | 1791 / 2893 / 1943 | 3.236 / 3.335 / 3.220 | 3.236 s |
| After | 871 / 836 / 866 | 2.340 / 2.371 / 2.413 | 2.371 s |

All six result hashes match:
`c3394b8a8e2ce02d4b7886968d49ae49b4e08a9ef2fbf6c197d6d158face56c0`.
Separate source instrumentation counts trace-record construction after seeding:
**120 before → two after per query**, with the same hash. The roughly 27% local
median CPU reduction is diagnostic, not a production throughput promise.
An exploratory workload omitted fixed timestamps and produced varying hashes;
those samples were discarded and are not included above.

No RSS/allocation-byte, binary-size, production latency or model-token savings are
claimed. Context payloads/prompts/tool schemas and their baselines are unchanged.
Dependencies and ordinary command-output volume are unchanged. Verification keeps
verbose evidence in files and emits concise receipts. No cache or invalidation
policy was introduced; stored trace retention still requires a bounded host sink.

## Boundaries and remaining work

Host callbacks, registered tools, approval policies and capability limits retain
authority. Model/retrieval content does not authorize actions. Existing approval,
handoff, controlled Ability, context provenance, trace privacy and failure-path
contracts remain covered by the full suite. This pass adds no new network,
subprocess, deserialization or credential surface.

Session stores remain process-local. Deletion now removes the saved payload even
without a Session record; identifier tombstones and existing repeated-deletion
behavior remain compatible. Trace pagination scans all records for accurate
totals. JSONL still buffers the source file and hosts must bound/rotate it.
Callbacks and timeouts are cooperative, file roots are host-owned, and
multiwriter coordination is outside these in-memory contracts.

Remaining **P0/P1/P2: none established and left unresolved by this pass**.
**P3 / not worth changing:** stylistic rewrites, generic abstraction consolidation
and blanket serializer removal without demonstrated benefit. **Needs more
evidence:** aggregate production memory/latency and application-specific concurrent
backends. These scope limits are not newly discovered unresolved defects.
No cross-repository change or release requirement. SignalBox: no captures warranted.

## Reproduction commands

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-fourth/regressions.kujo -v
.tmp/runtime/kujo test-run tests/session_store_contract_tests.kujo -v
.tmp/runtime/kujo test-run tests/runner_session_memory_integration_tests.kujo -v
.tmp/runtime/kujo test-run tests/trace_sink_contract_tests.kujo -v
.tmp/runtime/kujo run .tmp/audit-fourth/trace-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-fourth/trace-after.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-fourth/counted-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-fourth/counted-after.kujo --interpreter
.tmp/runtime/kujo run scripts/benchmark_trace_page.kujo --interpreter
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 95f66d02b09494bad35db9b1302bcf817d9a85e7 HEAD
```

The temporary two-case regression suite intentionally failed before fixes and
passed afterward. Targeted session (7), runner integration (1) and trace (10)
cases passed. Final receipts: `.tmp/offline-checks.x6XvvW/` and
`.tmp/audit-fourth/final-{offline,context,ratchet}.log`; explicit exports/examples
also passed. The shipped benchmark matched the paired hash (1800 ms diagnostic
query time, not pooled with paired samples). Shell syntax, diff hygiene and
commit-range artifact guard passed. All 11 maintenance-agent files retain their
original SHA256 hashes and untracked state in the untouched detached checkout.
