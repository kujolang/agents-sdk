# Agents SDK hardening: tool artifact fidelity

- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `a20b89a992bde4f3e480dff42ea5423956dfd348`, matching freshly fetched `origin/main`.
- Ending implementation: `7cd9a33d11439a5c2f29f41e6ad2e215a979d782`.
- Report-only delivery SHA: `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-13-sixth.md`.
- Scope: existing managed SDK worktree; original detached checkout and maintenance-agent files excluded.

This fresh audit follows the [fifth pass](repository-hardening-2026-10-12-fifth.md).
No intervening remote-main changes were present. Current README, AGENTS,
developer/example guidance, manifest/lock and CI remain unchanged from the prior
inspection. The attachment again requests measured improvements without churn.

## Review and baseline

The SDK is a local-first agent orchestration library with provider execution
through host callbacks. Reviewed artifact emission from tool handlers through
normalization, policy checks, persistence and execution-result diagnostics;
registry approval/input/timeout sequencing; direct artifact byte estimates and
UTF-8 limits; runner output/memory persistence boundaries; canonical/controlled
Ability validation and host admission; and architecture/integration ownership.
Broad I/O/error/serialization/TODO searches cover source, scripts, docs and
examples. Existing full-suite checks cover unchanged approval, handoff, tracing,
retrieval, cancellation, session, context and budget behavior.

Main sweeps exclude generated/dependency paths, `tests/*.out`, audit history,
maintenance paths, the absent historical checklist and shared example support
when searching runnable examples. Fixtures were executed without rewriting them.
No sibling repository changed.

Released Kujo **1.6.0** remains the CI pin. Ability **1.0.1** remains the sole
package dependency at `4aa354da8d02b027c459f692f69b523f96e97056`, with manifest,
lock and installed package unchanged from the prior verified pass. AI SDK,
Dispatch, Watchdog, MCP and RAG remain callback/adapter boundaries. No upgrade,
new dependency, cache, release or cross-repository change is required. There is
no configured separate native build, lint, formatter, typecheck or live E2E gate.
No live-provider readiness or current-advisory claim is made.

| Gate | Before | After |
| --- | --- | --- |
| Offline checks | 42, zero failures | 42, zero failures |
| Contract files / cases | 41 / 267 passed | 41 / 270 passed |
| Fixtures | 42/42 | 42/42 |
| Context corpus | 20 paired repetitions; 14 VM/interpreter source executions passed | Same complete gate passed |
| Token/hash ratchet | No warnings or regressions | No warnings or regressions |
| Exports / canonical examples | Covered by baseline contracts | Explicit checks passed |

Baseline receipts: `.tmp/offline-checks.XwpykA/` and
`.tmp/audit-sixth/baseline-{offline,context,ratchet}.log`. No tracked baseline
failure was found.

## Meaningful change

| Priority / problem | Root cause / implementation | Evidence / affected files | Compatibility |
| --- | --- | --- | --- |
| P2: tool-emitted artifacts lost source whitespace before storage and validation | The registry treated artifact content like an identifier and trimmed it before passing it to ArtifactStore. Resolve `content` or the legacy `text` fallback, retain strings exactly, and preserve the established empty fallback for non-strings. | `src/agents/tools/registry.kujo`; new contracts in `tests/tool_registry_tests.kujo` cover indentation/newlines, Unicode, empty/non-string precedence, file bytes and mixed rejected/successful writes. Primitive docs explain fidelity and write diagnostics. | Public shapes/signatures unchanged. IDs/titles keep normalization; explicit `content` still wins over `text`. The store sees original bytes, so near-limit payloads previously shortened by trimming may now be rejected. Consumers wanting trimming must do it before emission. |

Three new cases extend the existing tool contract file, picked up by the normal
CI glob. The file-backed case reads the actual persisted bytes and removes its
file. Mixed-write coverage confirms a failed artifact does not prevent the next
valid artifact from persisting. Existing best-effort semantics remain: the tool
handler can succeed while `metadata.artifact_writes` records a failed write;
rejected artifacts are omitted from returned artifacts.

## Measured behavior and efficiency

- An indented code artifact `    return value\n` contains **17 UTF-8 bytes**.
  Before, the tool path stored **12 bytes**; afterward all **17 bytes** survive.
- The payload ` \n🌍\n ` contains **8 UTF-8 bytes**. With a four-byte store limit
  and caller estimate zero, the old path stored the shortened four-byte emoji.
  The fixed path returns `budget_exceeded` with `artifact_bytes: 8` and stores
  nothing for that item. A following four-byte emoji succeeds.
- A tab-indented CRLF artifact survives actual file persistence unchanged.

The byte-limit comparison embeds the exact before/after registry module and uses
the same public API workload and unchanged ArtifactStore. Initial probes omitted
required tool identity or placed the in-memory limit outside `metadata`; those
setups were corrected and are not accepted evidence. The permanent tests configure
the policy correctly. The legacy `Artifact.bytes` estimate remains compatible;
it is not redefined as authoritative UTF-8 length. Existing store validation
independently measures actual UTF-8 bytes when enforcing a configured limit.

No CPU, latency, RSS, binary-size or model-token savings are claimed. Preserving
required source bytes can increase stored payload length; deleting them is not a
valid efficiency improvement. Existing pagination/byte-accounting optimizations
remain under regression coverage. No further broad optimization had sufficient
measured benefit to justify scope expansion. Prompts, tool schemas, context
baselines, dependencies and normal command-output volume remain unchanged.
Verbose evidence stays in local files; no new logging or retry was introduced.

## Boundaries and remaining work

This change sits before the existing ArtifactStore size/kind and filesystem
validation. It adds no filesystem authority, network request or subprocess.
Approval and input validation still precede handler execution. Tool/model data
cannot install host capabilities, admission callbacks or roots. File roots remain
host-owned; atomic publication and explicit replacement semantics are unchanged.
In-memory retention, process-local file indexes, cooperative callback timeouts
and multiwriter coordination remain documented host responsibilities.

Public exports, CLI behavior, JSON/file formats, schemas, configuration and
environment variables are unchanged. External consumers only observe preserved
artifact whitespace and byte-limit decisions on the original payload. No new
migration beyond explicitly trimming where a caller wants that behavior.

Remaining **P0/P1/P2: none established and left unresolved by this pass**.
**P3 / not worth changing:** cosmetic cleanup and broad normalizer rewrites.
**Needs more evidence:** production aggregate performance and host-specific
concurrent backends. No new unresolved cross-repository requirement.
SignalBox: no captures warranted.

## Commands and receipts

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-sixth/artifact-regressions.kujo -v
.tmp/runtime/kujo run .tmp/audit-sixth/budget-before.kujo --interpreter
.tmp/runtime/kujo run .tmp/audit-sixth/budget-after.kujo --interpreter
.tmp/runtime/kujo test-run tests/tool_registry_tests.kujo -v
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh a20b89a992bde4f3e480dff42ea5423956dfd348 HEAD
```

The text reproducer and corrected before-module byte-limit probe intentionally
fail on the starting implementation; both pass after the fix. Targeted tool
contracts: 21/21 passed. Final per-test receipts: `.tmp/offline-checks.kE3Vzw/`.
Full context/ratchet and explicit export/example receipts are under
`.tmp/audit-sixth/`. Shell syntax, diff hygiene and the artifact commit-range
guard passed. No fixture or context baseline changed. All 11 maintenance-agent
files retain their original SHA256 hashes and untracked state in the untouched
detached checkout. No unresolved delivery blocker.
