# Agents SDK hardening: latest-main pass

- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `6b9457b45fa02fe58b2fb9fec0d8e44ddeacf967`, verified against freshly fetched `origin/main`.
- Ending implementation SHA: `2f8ad99` (identifier fix `80695d7`). The subsequent report-only
  SHA is available with `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-12-third.md`.
- Write scope: the existing managed Agents SDK worktree. The original detached
  checkout and its maintenance-agent files remain untouched.

This follows the [first](repository-hardening-2026-10-12.md) and
[second](repository-hardening-2026-10-12-repeat.md) passes with a new full baseline.
New experiments focus on storage identity, accidental replacement and artifact
pagination, including paths used by runner output persistence.

## Ground truth and verification

The repository is a local-first library for agent orchestration, tool approval,
context, persistence and adapter integration. Read the attachment, current
README/AGENTS/developer/examples guidance, architecture, primitive references,
prior reports, package/lock files and CI. Rechecked storage implementations,
runner persistence call sites, clock services, trace redaction/path handling,
RAG transport and context ratchet boundaries. Reviewed source I/O/failure/retry
searches and contract coverage. Unchanged approval, handoff, cancellation,
controlled Ability, context provenance and observability contracts remain covered
by the complete offline suite. No new network executor or subprocess interface
was introduced.

Main searches excluded generated/dependency directories, `tests/*.out` and the
historical `docs/AGENTS_SDK_BUILD_CHECKLIST.md`, which remains absent. Maintenance
work was excluded. Fixture files were executed, never refreshed. The source tree
and runtime are the same as the verified second-pass delivery before new edits;
no intervening remote-main changes were present at baseline.

| Gate | Before | After |
| --- | --- | --- |
| Offline checks | 42, zero failures | 42, zero failures |
| Contract files / cases | 41 / 255 passed | 41 / 261 passed |
| Fixture executions | 42/42 passed | 42/42 passed |
| Context corpus | 20 paired repetitions; 14 VM/interpreter source executions passed | Same complete gate passed |
| Token/hash ratchet | Passed without warnings/regressions | Passed without warnings/regressions |
| Exports / canonical examples | Covered by baseline contracts | Explicit checks passed |

Released Kujo **1.6.0**, the CI pin, is the authoritative runtime. The only declared
package dependency remains Ability 1.0.1 at
`4aa354da8d02b027c459f692f69b523f96e97056`, matching the manifest/lock.
AI SDK/provider calls are host callbacks; Dispatch, Watchdog, Scout, MCP and RAG
remain adapters. Inspected the **v1.6.0** runtime source for atomic-write semantics,
not just a newer sibling checkout: `overwrite=false` publishes through a
non-replacing hard link. A direct runtime probe also rejected replacement and
preserved existing bytes. No sibling repository was modified.

No tracked baseline failure was found. There is no separate configured native
build, formatter, linter, typecheck or live E2E gate for this source package;
its build command is empty. No live-provider readiness, current-advisory status
or newest-dependency-version claim is made.

## Meaningful changes

| Priority / problem | Root cause and implementation | Files and proof | Compatibility |
| --- | --- | --- | --- |
| P1: automatic memory/artifact creation overwrote explicit records | The next numeric ID ignored keys already in the shared namespace. Skip occupied IDs before inserting and advance the existing counter. Memory tombstones also reserve their IDs. | `src/agents/memory/store.kujo`, `src/agents/artifacts/store.kujo`; both initial public-API regressions failed, then passed. Additional cases cover consecutive reservations, deleted memory IDs, subsequent sequence values and explicit replacement order. | Same generated format and collision-free sequence. Previously destructive collisions now choose the next unused ID. Explicit replacement remains supported. |
| P1: automatic file artifacts could overwrite earlier files | Millisecond timestamps were treated as unique, and publication always enabled overwrite. Keep the timestamp prefix, choose a numeric suffix when the path/index is occupied, then publish atomically with overwrite disabled for automatic creates. | Artifact store; frozen-clock probes reproduce prior content loss, including an existing disk file absent from the local index. Both preserve content after the fix. Public file-store tests check distinct creates, reads and deliberate replacement; the runtime no-overwrite probe passes. | Existing non-colliding names and explicit-ID atomic replacements remain unchanged. A racing automatic publisher can return the existing structured `artifact_store_write_failed` instead of destroying another file. No hidden retry. |
| P2: artifact pagination rebuilt off-page records and repeatedly scanned dictionary keys | Count matching records while constructing only the requested page. Use native dictionary membership instead of interpreted key enumeration. | Artifact store, `scripts/benchmark_artifact_page.kujo`; exact before/after result hashes and a paginated contract covering kind/run filters, totals, insertion order, nested value isolation, `limit: 0` and extreme offsets. | Shapes, total counts and ordering stay the same. Artifact `limit: 0` still means unlimited; it is intentionally different from the established memory-query contract. |

Six new cases extend the two existing contract files; the normal CI glob picks
them up. The clock probes are explicit fault-injection experiments: they embed
the exact before/after artifact module and replace only its `current_timestamp()`
call with the same fixed integer. They do not claim that the host's real clock
was frozen. The unmodified public-API file test also passes. No private helper
was exported, no clock configuration API was added and no snapshot was changed.

## Measurements

The artifact workload seeds 160 text artifacts, each with 1,024 repeats of
`evidence 🌍 `, then runs twelve list queries with run filter, offset 80 and
page size two. Seeding is outside the script's query timer. The comparison embeds
the exact starting/final artifact module with the identical workload, alternates
before/after three times and uses Python `resource.getrusage` for child user+system
CPU; CPU includes process startup and seeding. Host load makes wall time noisy.

| Variant | Query wall time, milliseconds | Whole-process CPU, seconds | Median CPU |
| --- | --- | --- | --- |
| Before | 54,834 / 48,721 / 38,653 | 14.928 / 14.941 / 14.959 | 14.941 s |
| After | 6,889 / 4,568 / 5,496 | 3.214 / 3.364 / 3.282 | 3.282 s |

The local median CPU reduction is approximately 78%. This is a microbenchmark,
not a production throughput promise. Separate instrumentation of the exact
before/after module counted `to_artifact_record` calls after seeding for one query:
**160 before, two after**, with the same result hash. This supports the bounded
materialization claim without treating timing noise as an allocation measurement.

Every successful comparison returned result SHA-256
`fc6a6dcac958a2e12fcfd109b153202b519114b0d7a613541c49b32f7af491e9`.
The timestamp-collision probes changed `distinct_ids`, `first_content_preserved`
and `preexisting_file_preserved` from false to true. These are measured data
integrity outcomes, not probabilistic timing assertions.

No model prompts, tool schemas, provider payloads or token baselines changed.
No new token savings are claimed. Dependency count, package configuration,
normal command-output volume and logging policy are unchanged. Detailed evidence
stays in local files and normal verification emits concise receipts. No RSS,
allocation-byte, production-throughput or binary-size claims are made.

## Boundaries, contracts and remaining work

- Model/retrieval content remains untrusted. Host registrations, callbacks,
  capability ceilings and approval policies retain execution authority. This
  pass repairs persistence identity rather than adding authorization policy.
- Automatic file publication now refuses an existing destination atomically,
  including a race after name selection. This does not provide a filesystem
  sandbox, a durable index or a transaction across filesystem and process-local
  metadata. Host-owned roots and concurrency coordination remain required.
- Stored payloads are still retained until reset/deletion or host lifecycle ends.
  Paging removes unnecessary intermediate records; it does not change retention.
  No cache or invalidation policy was introduced. Trace/privacy/redaction,
  provider retry/deadline, context freshness and prior persistence-error fixes
  remain unchanged and covered by existing tests.
- Public exports/signatures and result shapes did **not** change. CLI behavior,
  JSON/file formats, versioned schemas, config, environment variables and package
  interfaces did **not** change. Automatic IDs differ only on occupied names;
  callers relying on automatic overwrite now receive new IDs or a structured
  publication failure. Explicit-ID update callers require no migration.
- Canonical examples remain direct; shared normalizers and public compatibility
  aliases were preserved. Broad refactors, blanket serializer removal and
  dependency replacement lacked enough benefit to justify compatibility risk.

No cross-repository change or coordinated release is required. Remaining work:
**P0/P1/P2: none established and left unresolved by this pass. Needs more evidence:**
production aggregate latency/memory effects and application-specific concurrent
backends. **Not worth changing:** stylistic rewrites and unmeasured broad cleanup.
These are operational scope limits, not newly discovered unresolved defects.
SignalBox: no captures warranted.

## Commands and local evidence

All verification uses the managed worktree and its released runtime. Primary
commands executed (intentional before-fix failures are called out below):

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-third/collision_tests.kujo -v
.tmp/runtime/kujo test-run tests/memory_store_contract_tests.kujo -v
.tmp/runtime/kujo test-run tests/artifact_store_contract_tests.kujo -v
.tmp/runtime/kujo run .tmp/audit-third/frozen-file-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/frozen-file-after.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/frozen-existing-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/frozen-existing-after.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/native-no-overwrite.kujo --interpreter
.tmp/runtime/kujo run scripts/benchmark_artifact_page.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/isolated-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/isolated-after.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/counted-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-third/counted-after.kujo --interpreter
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 6b9457b45fa02fe58b2fb9fec0d8e44ddeacf967 HEAD
```

The initial collision test and before-fix frozen-clock probes intentionally
failed. A first attempt to shadow the builtin clock in an importing caller did
not affect the module clock and was discarded; the later explicitly embedded
fault-injection probes are the accepted evidence. Targeted fixed suites and the
native no-overwrite probe passed. Generated sources, logs and measurements are
under `.tmp/audit-third/`; baseline per-test evidence is
`.tmp/offline-checks.8wrEil/`. Final per-test receipts are in `.tmp/offline-checks.HYgC72/`: 41 contract
files, 261/261 cases, zero failures; 42/42 fixtures. `final-offline.log`,
`final-context.log`, `final-ratchet.log`, `exports.log` and `examples.log` all
record passing checks. The shipped benchmark returned the same hash at 7,535 ms
under concurrent verification load; it is not pooled with the paired comparison.
Shell syntax, diff hygiene and the artifact commit-range guard passed. SHA256
comparison confirms all 11 original maintenance-agent files unchanged; their
untracked state is preserved. No unresolved delivery blocker remains.
