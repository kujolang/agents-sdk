# Agents SDK hardening audit — 2026-10-12

## Revision and scope

- Repository: `kujolang/agents-sdk`, library-first Kujo agent orchestration.
- Starting checkout: detached HEAD at `5a9d5525e511a293b743b1c44d9ef270fd491f9f` (1.1.2).
- Audit branch: `codex/agents-sdk-hardening`.
- Ending implementation SHA: `c4fad82f899d8009774ccd4ece582899d84b2285`.
- Final report commit: resolve with `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-12.md`; this file cannot contain its own commit hash.
- Implementation commits: `5a8f6a2` runtime boundaries, `c554f71` measured efficiency, `c4fad82` session retention and operational guidance.
- Write scope: this repository only. Work used an attached isolated worktree because the original checkout contained unrelated, pre-existing maintenance-agent files. Those files remain untouched. The audit branch is independently verifiable without them.

Read README, developer/examples guides, architecture, public API stability,
security guidance, integration/context contracts, prior audit, manifests, CI,
source modules, runnable examples and contract coverage. The instructed historical
`docs/AGENTS_SDK_BUILD_CHECKLIST.md` no longer exists at this revision. Main
searches excluded `tests/*.out`, that historical path, dependencies/generated
artifacts and the unrelated maintenance work. The actual tracked fixture was
preserved. Dependency source was inspected separately when verifying the pin.

This is a source-backed engineering audit with deterministic offline experiments,
not a claim of exhaustive vulnerability elimination or live-provider readiness.

## Baseline and dependencies

The shell default is Kujo 1.5.0, below the repository's 1.6.0 minimum. Its original
working-directory run returned 42 checks / 2 failures: maintenance-agent contracts
and fixtures. These are pre-existing working-directory failures, not the tracked
release baseline. Logs remain in the original checkout under
`.tmp/offline-checks.kIYZ0V/`.

The tracked starting tree passed with both the read-only sibling build reporting
1.8.1 and the released 1.6.0 runtime used by CI. Release 1.6.0 macOS x64 was
retrieved with `gh`, and its archive matched the published SHA-256 sidecar.
Authoritative before/after verification below uses the identical released binary.

| Gate | Before | After |
| --- | --- | --- |
| Contract files / cases | 40 / 234, all passed | 41 / 247, all passed |
| Fixture execution | 41/41 passed | 42/42 passed |
| Offline script receipt | 41 checks, 0 failures | 42 checks, 0 failures |
| Context corpus | 20 paired repetitions and 14 VM/interpreter source executions passed | Passed unchanged |
| Context budget/hash ratchet | No warnings/regressions | No warnings/regressions |
| Module exports and canonical examples | Existing contracts passed | Explicit smoke executions passed |

Ability is the only declared runtime package dependency. Both manifest and lock
pin `4aa354da8d02b027c459f692f69b523f96e97056` (Ability 1.0.1). The installed
package was byte-for-byte compared with an archive of that exact commit from the
read-only sibling repository; no differences. Final verification used the local
archive copy. No dependency versions, packages or install scripts were added.
AI SDK/provider integration uses injected callbacks; Dispatch, Watchdog, Scout,
MCP and RAG remain adapter boundaries. CI action/runtime/dependency pins were
reviewed; no unsupported advisory-clean or latest-version claim is made.

No separate project native build, formatter, lint/type-check or live E2E command
is configured. The package build command is empty. Native executable size and
provider billing are therefore not useful before/after dimensions for this pass.

## Findings and implemented changes

| Priority / problem | Root cause and implementation | Files / regression proof | Compatibility and impact |
| --- | --- | --- | --- |
| P1: manual/custom approvals became automatic approvals | Runner reconstructed every non-deny provider using the auto constructor. Preserve host callbacks, dispatch known built-in kinds, and resolve unknown explicit kinds as manual/pending. Consolidate three duplicated resolution branches. | `src/agents/runner.kujo`; `tests/audit_regression_tests.kujo` checks manual, unknown and failed custom approval. New regression failed before correction. | Same public signatures/status shapes. Omitted kind retains auto default; explicit manual/custom policy is now honored. |
| P1: ordinary handoffs lost parent safety controls | Propagation existed only in the typed-handoff branch. Every child now receives cancellation/sanitizer callbacks and ancestor approval gates. Evaluate the child's own policy AND each ancestor gate; isolate provider fallback so a child cannot approve an ancestor request. | Runner, `src/agents/tools/registry.kujo`; denial, cancellation, provider isolation and stricter-child regressions. Ordinary denial/cancellation tests failed before correction. | No payload-format change. Child execution that previously bypassed a parent restriction now fails/pends correctly. Typed handoffs also retain stricter child policy. |
| P2: multi-tool responses exceeded `max_iterations` | Ceiling was checked only after the model. Check before each tool, handoff and final step. Centralize terminal event/session persistence in the existing stop-result helper; retain executed tool/model/handoff evidence. | Runner; batch, exact completion, before/after handoff, terminal event and session-state regressions. Batch regression failed before correction. | Existing `max_iterations` terminal status and errors retained; runs no longer report completion above their declared ceiling. |
| P2: lifecycle spool exceeded its byte quota with Unicode | Character count was added to filesystem byte size. Count encoded UTF-8 bytes including newline. | `src/agents/tracing/lifecycle.kujo`; over-quota and exact-fit/second-record regressions. Unicode regression failed before correction. | JSONL unchanged; over-quota Unicode records correctly return false and leave the existing gap marker. |
| P2: shared skill dependencies caused repeated validation and reads | Output deduplication occurred after recursively loading every dependency path. Track completed skill IDs within one load invocation, separately from active-path cycle detection. | `src/agents/context/skills.kujo`, `tests/context_skills_tests.kujo`, `scripts/benchmark_skill_dependencies.kujo`; exact output hash, read-count, repeat-call, cycle and missing-dependency checks. | Public result and disclosure order unchanged. No cross-call cache or stale reuse. |
| P2: artifact byte limits allocated unnecessary encodings | Byte counting encoded and decoded the entire string as base64. Use native `byte_length`, already supported by the minimum runtime. | `src/agents/artifacts/store.kujo`, `scripts/benchmark_artifact_bytes.kujo`; existing UTF-8 and underdeclared-byte regressions remain green. | Same byte-limit behavior; fewer full-content temporary representations. No RSS claim. |
| P2: deleted sessions retained full payloads | Delete marked an ID inactive and cleared run state but retained session messages/context in the internal map. Clear the stored payload, preserving the ordering tombstone. | `src/agents/sessions/store.kujo`, `tests/session_store_contract_tests.kujo`; deletion/recreation preserves visibility, empty state and deterministic ordering. | CRUD result shape and recreation order unchanged. Payload release is source-supported; process RSS was not measured. |

The initial four boundary regressions were **0/4 passing** before fixes and
**4/4 passing** afterward. A later provider regression separately demonstrated
manual approval returning `completed` before correction. Final added coverage
is 13 cases: 10 runtime-boundary, two skill-dependency and one session-lifecycle.
The existing offline CI glob automatically executes them; no new flaky timing
threshold or baseline refresh was introduced.

## Measured efficiency

All numbers below are local microbenchmarks under released Kujo 1.6.0,
interpreter mode. They are not application-wide throughput or model-quality claims.

| Experiment | Before | After | Equivalence |
| --- | --- | --- | --- |
| 100 artifact constructions with 73,728-byte UTF-8 content and a byte cap; three serial samples | 226, 224, 229 ms; median 226 ms | 107, 139, 129 ms; median 129 ms | Checksum 7,372,800 in every run; all accepted |
| Eight skills with duplicate dependency edges; one measured sample | 255 artifact reads, 1,169 ms | 8 artifact reads, 61 ms | Eight loaded items; exact same canonical output hash |

Skill output SHA-256:
`ce7f681adc014b1071fc9c9074c18352698c6f8001e0c18a5d10590c6b423ec4`.
The deterministic regression ratchet uses **read count and output hash**, not
wall time. Each subsequent call performs fresh reads. The artifact benchmark
exercises the public create boundary with a callback store and verifies acceptance
and accumulated byte counts. The removed base64 temporaries are evident in source;
no allocation profiler or process-memory savings percentage is claimed.

Model input/output, tool schema bytes and estimated-token baselines remain
unchanged. Skill output was already deduplicated: this fix saves host work,
not additional model tokens. The existing context ratchet passes without
approval changes. Detailed contract output remains in local logs; the normal
offline command still emits one concise success receipt. No new runtime logging,
prompt prose, external dependency or eager context injection was added.

## Boundary and contract review

- **Model/tool trust:** provider responses and model tool names/arguments are
  untrusted; registered host callbacks and run options supply execution authority.
  Unknown tools, approval failures and canonical Ability input/output/receipt
  identity validation remain covered. This pass repairs the runner approval
  boundary rather than changing portable Ability definitions or gateway auth.
- **Context:** manifests and references verify integrity/freshness, not an
  attacker-owned catalog's authenticity. Selected skills/capabilities remain
  trusted configuration. Resume and typed handoff use verified artifact references.
  Existing security-rule, forgery, stale-source and dispatch tests pass.
- **Filesystem/state:** safe leaf artifact IDs/extensions, atomic artifact writes,
  JSONL corruption errors and read-after-write context verification remain tested.
  Roots/symlinks, multi-process writers and retention are host responsibilities.
  Spools are single-execution sinks, not concurrent quota managers. Session payload
  deletion now releases retained values; identifier tombstones still need lifecycle
  resets in long-lived hosts.
- **Network/process:** the SDK has no standalone CLI or generic shell executor.
  RAG's optional HTTP transport uses a host-configured endpoint, timeout/response
  bounds, disabled redirects and DNS pinning. MCP request helpers construct data;
  gateway transport/authentication and AI calls remain host callbacks. Offline
  contracts deny network, AI, shell and subprocess capabilities.
- **Failures/resources:** callbacks are cooperative, not preemptible. Retry count,
  timeout, usage and artifact bounds were reviewed. Existing per-run stores and
  streams retain data until host release; no speculative global caching was added.
  Guardrail/redaction primitives, sanitizer fallback compatibility, failed model
  mapping and observability fail-open behavior remain intact.
- **Architecture/maintenance:** the large runner has substantial explicit terminal
  result construction; a broad rewrite would increase regression risk. Only the
  repeated approval-provider resolution and iteration-stop behavior were factored.
  Public normalizers/aliases were retained because exported compatibility outweighs
  speculative line-count reductions. Examples remain direct and copyable.

Public export names/signatures, top-level result contracts, CLI, file formats,
versioned schemas, package configuration and environment variables are unchanged.
The runner carries additive trusted `inherited_approval_gates` options internally
across handoffs; these are not model payload fields. Metadata on newly enforced
iteration stops includes completed execution evidence. Consumers relying on
approval bypasses or over-limit execution intentionally see stricter behavior.
Consumers using documented approvals, payloads and defaults need no migration.

Known integration consumers include Dispatch workflows, Agent City observation,
RAG retrieval and Watchdog telemetry. No sibling modification or synchronized
release is required for these fixes; their local SDK adapter contracts pass.

## Verification commands and evidence

Commands ran from the audit worktree unless a path is explicit. Read-only
inventory used `git status -sb`, `git log -5 --oneline`, `git rev-parse HEAD`,
`git branch -a`, `rg --files`, scoped `rg -n`, `cat`, `sed` and `wc -l`.

```bash
# Runtime provenance — passed
kujo --version                         # default: 1.5.0, unsupported baseline runtime
/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo --version # 1.8.1
mkdir -p .tmp/runtime
gh release download v1.6.0 --repo kujolang/kujo -p 'kujo-v1.6.0-macos-x64.tar.gz*' -D .tmp/runtime
(cd .tmp/runtime && shasum -a 256 -c kujo-v1.6.0-macos-x64.tar.gz.sha256 && tar -xzf kujo-v1.6.0-macos-x64.tar.gz)
.tmp/runtime/kujo --version             # 1.6.0

# Dependency provenance — archive matches the original installation exactly
git -C /Users/robertdevore/2026/Kujolang/kujo-repos/ability archive 4aa354da8d02b027c459f692f69b523f96e97056 | tar -x -C kennel_packages/ability
diff -qr kennel_packages/ability /Users/robertdevore/2026/Kujolang/kujo-repos/agents-sdk/kennel_packages/ability

# Full before/after gates — passed
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter

# Targeted checks — passed after correction
.tmp/runtime/kujo test-run tests/audit_regression_tests.kujo -v
.tmp/runtime/kujo test-run tests/hardening_contract_tests.kujo -v
.tmp/runtime/kujo test-run tests/run_basic_runner_tests.kujo -v
.tmp/runtime/kujo test-run tests/handoff_contract_tests.kujo -v
.tmp/runtime/kujo test-run tests/context_skills_tests.kujo -v
.tmp/runtime/kujo test-run tests/session_store_contract_tests.kujo -v

# Reproducible informational benchmarks — passed
.tmp/runtime/kujo run scripts/benchmark_artifact_bytes.kujo --interpreter
.tmp/runtime/kujo run scripts/benchmark_skill_dependencies.kujo --interpreter

# Hygiene — passed
bash -n scripts/*.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 5a9d5525e511a293b743b1c44d9ef270fd491f9f HEAD
```

Before fixes, boundary tests ran from `.tmp/audit_regression_tests.kujo`, and the
same benchmark sources ran from `.tmp/artifact-byte-benchmark.kujo` and
`.tmp/skill-dag-benchmark.kujo`. Those local sources became the committed scripts
and tests after measurement. An initial session regression incorrectly addressed
`Session.messages` instead of `Session.state.messages`; correcting that test
access restored its intended public-contract assertion, without changing fixtures.

Local evidence: `.tmp/offline-checks.r8bcPd/` (baseline),
`.tmp/offline-checks.ZDtrAV/` (final), `.tmp/context-evaluation/`,
`.tmp/audit-regressions-before.log`, `.tmp/provider-before.log`,
`.tmp/audit-regressions-expanded.log`, `.tmp/skill-dag-{before,after}.json`,
`.tmp/dependency-comparison.txt`, `.tmp/final-{offline,context,ratchet}.txt`.
These logs are ignored; the committed regressions and scripts reproduce the proof.
CI already preserves newly generated verification logs for seven days.

## Remaining work

- **P0/P1/P2 regressions introduced by this pass:** none observed.
- **Cross-repository changes required:** none. The prior audit's recursive-clone
  interpreter reproducer returns the correct nested/sibling JSON on released
  1.6.0 (`.tmp/clone-repro.log`). This is a narrow retest, not a claim about all
  historical interpreter defects; no new duplicate upstream finding is filed.
- **Needs more evidence/design:** host callback preemption, aggregate budgets
  across child runs/provider attempts, shared-writer persistence and untrusted
  retrieval roles require explicit host/API contracts. Existing documentation
  describes their limits; no production capacity or isolation claim is added.
- **P3 / not worth changing here:** wholesale runner decomposition, shared
  normalizer migration, replacing pinned Ability or changing historical snapshot
  content solely for style.
- **Separate pre-existing work:** maintenance-agent files in the original checkout
  remain uncommitted and outside this audit branch. The isolated audit worktree
  is the clean delivery surface; the original checkout is not claimed clean.

SignalBox: no captures warranted. Fixed findings and benchmark/test receipts
belong in this report and Strata; the historical upstream item is not duplicated.
