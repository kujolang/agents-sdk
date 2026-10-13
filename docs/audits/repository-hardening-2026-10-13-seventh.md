# Agents SDK hardening: bounded model retries

- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `489c3a0f07ee75e7bac32a04c3c41cd6ed4a555a`, matching freshly fetched `origin/main`.
- Ending implementation SHA: `7b3f4cec3b9acc9a178a13f8f30a54378651a3bb`.
- Report-only delivery SHA: `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-13-seventh.md`.
- Scope: existing managed SDK worktree; original detached checkout and maintenance-agent files excluded.

This fresh pass follows the [tool-artifact audit](repository-hardening-2026-10-13-sixth.md).
There were no intervening remote-main changes. The SDK remains a local-first
agent orchestration library; model/provider calls belong to host callbacks.

## Inspection and baseline

Rechecked README, agent guidance, developer/examples documentation, architecture,
integration boundaries, manifests, CI, verification scripts and source failure
boundaries. Focused implementation review covered non-stream model retry
sequencing, adapter error normalization and observation hooks, runner counters,
budget/timeout/cancellation boundaries, tool dispatch, artifact persistence,
controlled Ability admission and metadata-only trace spooling. The prior audit
reports retain the wider component analysis; the full unchanged contract suite
was rerun before tracked edits.

Search exclusions: generated/dependency paths, `tests/*.out`, audit history,
maintenance files, the absent historical build checklist, and shared support
when searching runnable examples. Fixtures were executed without rewriting them.
No sibling repository was modified.

Released Kujo **1.6.0** is still the CI pin. Ability **1.0.1** remains the sole
package dependency, pinned to `4aa354da8d02b027c459f692f69b523f96e97056`.
The dependency files and installed package are unchanged from the preceding
verified pass. AI SDK, Dispatch, Watchdog, MCP and RAG remain adapter boundaries.
There is no separate configured native build, lint, formatter, typecheck or live
E2E gate. No live-provider or current dependency-advisory assurance is claimed.

Baseline receipts: `.tmp/offline-checks.Sxm2EH/` and
`.tmp/audit-seventh/baseline-{offline,context,ratchet}.log`.
All **270 cases in 41 contract files**, **42 fixtures**, context verification
(**20 paired repetitions and 14 VM/interpreter source executions**) and the
context token/hash ratchet passed. No existing-suite baseline failure was found.

## Change and proof

| Problem | Root cause and implementation | Files and coverage | Compatibility / impact |
| --- | --- | --- | --- |
| P2: retryable model failures could exhaust the language call stack before the configured retry ceiling | Each attempt recursively called the retry helper. Use one iterative helper frame, retaining the same stop predicates, per-attempt options and final receipt. | `src/agents/runner.kujo`; three new public runner contracts in `tests/run_basic_runner_tests.kujo`; deployment guidance in `docs/SECURITY_PRODUCTION_GUIDE.md`. | Existing signatures, result shapes, retry policy, counters and errors are preserved. Larger configured retry sequences can now complete or exhaust normally. |

The corrected before-change regression file has two failures and one passing
control. With `max_model_retries: 40`, recovery on attempt **40** and exhaustion
on attempt **41** both failed before the fix. The runner instead produced an
internal error; a separate public-API probe exposed `Maximum call stack depth
of 32 exceeded`. The early non-retryable failure control stopped at attempt **4**.
Afterward all three cases pass: recovery reports **40 attempts / 39 retries**,
exhaustion reports **41 / 40** with the original `timeout` error, and the control
reports **4 / 3** with `invalid_request`. Per-attempt top-level and nested metadata
are checked on each callback. The existing tests retain default/no-retry,
small-budget, streaming, cancellation and lifecycle coverage. A separate offline
public-API probe also completes on attempt **300**, reporting **299 retries**
under a configured ceiling of 300 retries; its starting implementation hit the
same stack-depth error.

Initial temporary harness drafts omitted the required agent name and attempted
to count calls by mutating a captured dictionary; those were corrected before
accepting the regression evidence. A later whole-result JSON print encountered
an existing function-valued runtime field; the probe receipt was narrowed to
status and retry counters. None of these harness failures is treated as an SDK
finding or a performance measurement.

## Efficiency and boundaries

The retry helper no longer retains one recursive frame per attempt. This is a
source-backed resource-lifetime improvement, demonstrated by executing a retry
sequence beyond the old stack limit; no RSS, latency or percentage speedup is
claimed. The same supported short retry sequences make the same provider calls.
A previously prematurely aborted sequence can now use its full configured
ceiling, so deployments should still use small limits. This does not introduce
backoff, transport preemption or retries of tools/streaming calls.

Success, non-retryable errors and ceiling exhaustion remain terminal. Provider
callbacks still enforce per-attempt deadlines and cancellation; the runner's
budget/timeout checks remain cooperative lifecycle checks. Approval, host-owned
capabilities, persistence, filesystem roots, trace retention and replay admission
are unaffected. No new network or subprocess capability is granted.

Tool schemas, prompts, context baselines, normal command output, dependencies and
file formats are unchanged. Existing context ratchets protect token accounting;
no model-token savings are claimed. Detailed verification output stays in local
receipts. No new cache, retained retry history or broad fallback was added.

Public APIs, CLI behavior, JSON/file formats, schemas, configuration and
environment variables are unchanged. External consumers observe normal results
and complete counters for retry sequences that previously hit the stack limit.
No migration or change in another Kujo repository is required.

## Final verification

All **273 contract cases in 41 files** and **42/42 fixtures** passed: three more
contract cases than the baseline. The targeted runner file passed **28/28**.
Context verification, the token/hash ratchet (no warnings or regressions),
explicit module-export and canonical-example smoke checks, shell syntax, diff
hygiene and the commit-range artifact guard passed. Final per-test receipts:
`.tmp/offline-checks.YUSokH/`; aggregate receipts:
`.tmp/audit-seventh/final-{offline,context,ratchet,exports,examples}.log`.

All **11 maintenance-agent files** retain their original SHA256 hashes and
untracked state in the untouched original checkout. The delivery worktree is
committed and clean. No unresolved delivery blocker.

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-seventh/retry-regressions.kujo -v
.tmp/runtime/kujo run .tmp/audit-seventh/retry-probe.kujo --interpreter
.tmp/runtime/kujo test-run tests/run_basic_runner_tests.kujo -v
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 489c3a0f07ee75e7bac32a04c3c41cd6ed4a555a HEAD
```

The temporary regression run intentionally fails before the fix. Permanent
regression cases live in the existing runner contract file, automatically picked
up by CI. No fixture or context baseline changed.

Remaining **P0/P1/P2: none established and left unresolved by this pass**.
**P3 / not worth changing:** cosmetic cleanup, broad normalizer rewrites and
speculative optimizations. **Needs more evidence:** production aggregate
performance and host-specific concurrent storage behavior. No cross-repository
requirement or release was introduced. SignalBox: no captures warranted.
