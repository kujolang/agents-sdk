# Agents SDK hardening: model-attempt token accounting

- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `4a1bf1f5c8b3f47bc2292889c53274aea86fd8c6`, matching freshly fetched `origin/main`.
- Ending implementation SHA: `b316a6c6c54d1042d1d49016d693b9f706d248bb`.
- Report-only delivery SHA: `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-13-eighth.md`.
- Worktree: existing managed SDK checkout; original detached checkout and all maintenance-agent files excluded.

This repeats the attached audit against current main after the
[bounded-retry pass](repository-hardening-2026-10-13-seventh.md).
No intervening remote-main changes were present.

## Review and baseline

The SDK remains a local-first agent orchestration library whose provider,
persistence and external service behavior belongs to host callbacks. Rechecked
unchanged guidance, package/CI inputs, source exception paths, adapter usage
normalization, retry receipts, budget accumulation and after-model enforcement,
structured-output validation, stream failures and public result contracts.
Prior reports retain the broader component findings. Searches exclude generated
and dependency trees, `tests/*.out`, historical audit output, maintenance paths,
the absent historical build checklist and shared runnable-example support.
Expected-output fixtures were executed without rewriting them.

Released Kujo **1.6.0** remains the CI runtime. Ability **1.0.1** remains the only
package dependency at `4aa354da8d02b027c459f692f69b523f96e97056`, unchanged
from the preceding verified pass. AI SDK, Dispatch, Watchdog, MCP and RAG remain
adapter boundaries. A read-only AI SDK source check confirms cent-denominated
cost telemetry; no sibling source changed. No dependency upgrade or new package.
No separate native build, lint, formatter, typecheck or live E2E gate is configured.
No live-provider or current advisory assurance is claimed.

Before tracked edits, all **273 contract cases in 41 files**, **42 fixtures**,
context verification (**20 paired repetitions, 14 VM/interpreter source
executions**) and the token/hash ratchet passed. No existing-suite baseline
failure. Logs: `.tmp/offline-checks.8rSCaY/` and
`.tmp/audit-eighth/baseline-{offline,context,ratchet}.log`.

## Changes and evidence

| Problem | Root cause / implementation | Files / coverage | Compatibility and measured effect |
| --- | --- | --- | --- |
| P2: reported token consumption disappeared on failed attempts and retries | Runner budget accounting read only the final normalized response. Error normalization retains provider usage in `raw`. Recover that usage through the existing adapter normalizer when normalized usage is absent, and accumulate each non-stream attempt's budget delta once. | `src/agents/runner.kujo`; four public runner contracts in `tests/run_basic_runner_tests.kujo`. | Final model-result shape and per-response usage remain unchanged. Run-level counters now include reported consumption from failed attempts; enforce mode can stop a run previously undercounted. |
| Misleading deployment guidance for cost enforcement | Adapter telemetry exposes `cost_cents`; the generic budget counter expects `cost_microunits`. No currency, scale or rounding conversion is defined. Document that automatic cent conversion is unavailable and cost limits belong in the host/provider layer until that contract is defined. | `docs/SECURITY_PRODUCTION_GUIDE.md`; local public-API probe, source comparison. | No speculative conversion or new unit convention is introduced. The unresolved contract gap is recorded below. |

All four new regression cases failed on the starting implementation and pass
afterward. Existing CI picks up the additional cases through its normal glob.

| Workload | Before | After |
| --- | --- | --- |
| Initial 3 tokens, failed attempt reports 7, successful retry reports 5; limit 10 | Run counted 8 and completed | Counts **15**; enforce mode returns `budget_exceeded` after the model; observe mode completes and retains the final response's **5-token** usage |
| Three exhausted attempts, each reports 7 tokens | 0 tokens | **21 tokens**, original `timeout` failure retained |
| Successful provider response reports 14 tokens but fails structured-output validation | 0 tokens | **14 tokens**; enforce mode applies the 10-token limit, observe mode retains `structured_output_invalid` |
| Failed streaming response reports 7 tokens through prompt/completion aliases | 0 tokens | **7 tokens**, one model call, original `invalid_request` retained |

The retry case also checks cumulative input/output counts (**9 / 6**, including
initial usage), model-call counts and retry counters. No guessing of unreported
usage, no double-counting of the successful response, and no fixture changes.
Raw provider/model outputs are not copied into additional public telemetry.

## Resource and trust boundaries

The accumulator retains one fixed-size counter record, not previous response
history. Per-attempt accounting adds necessary work to preserve consumption;
no speedup, RSS reduction or model-token savings is claimed. Reported run token
counts increase because missing consumption is restored, not because this patch
requests more model work. Prompt/tool schemas, context baselines, dependencies,
command output volume and provider-call count are unchanged.

Retry ceilings, early stopping, streaming dispatch, callback authority and
approval boundaries remain unchanged. Budgets are still checked at lifecycle
boundaries, not between individual retries; transport callbacks enforce
per-attempt deadlines/cancellation. No new filesystem, subprocess, network or
replay authority. Persistence and multiwriter coordination remain host-owned.
Error usage is normalized and counters reject negative/non-integer values using
the existing budget rules. No additional sensitive payload logging.

Public API signatures and result shapes, CLI behavior, file formats, schemas,
configuration and environment variables are unchanged. External consumers may
observe higher, accurate run-level token counters and earlier after-model budget
failure. Final per-response usage is preserved. No token-accounting change is
required in another repository.

## Remaining work

- **P0/P1:** none established by this pass.
- **P2 / needs contract decision:** runner `max_cost_microunits` cannot enforce
  reported `cost_cents` without a defined unit mapping. A public-API probe with
  `estimated_cost_cents: 1.75` and `max_cost_microunits: 1` completes while the
  cost counter remains **0**. Source: adapter normalization/extraction and
  `build_model_budget_delta`; receipt: `.tmp/audit-eighth/cost-unit.log`.
  Define currency/scale/rounding and overflow behavior, then implement compatible
  conversion and failure/retry coverage. Coordinate with AI SDK consumers;
  no sibling patch is necessary for the token fix. Current safe integration:
  use host/provider cost governance. SignalBox captures this unresolved item.
- **Needs more evidence:** aggregate production performance and host-specific
  concurrent backend behavior.
- **P3 / not worth changing:** cosmetic churn, broad rewrites and unmeasured
  optimizations. No release or dependency change.

## Verification and commands

Final: **277/277 contract cases in 41 files**, **42/42 fixtures**, **32/32 targeted
runner cases**, all four new regression cases, context parity/evaluation,
context ratchet (no warnings/regressions), explicit exports/examples, shell
syntax, diff hygiene and commit-range artifact guard passed. Final full-suite
receipts: `.tmp/offline-checks.r9UbsD/`; aggregate and targeted receipts:
`.tmp/audit-eighth/`. Maintenance hashes remain unchanged; delivery worktree
committed and clean.

SignalBox project `agents-sdk`: Capture
`cap_33795451-d68d-46ec-80a9-64cb353cd2c0` and Signal
`sig_fa52406e-2134-47eb-bcf3-83d19f25d300` preserve the unresolved cost-unit gap.
Exact-ID and concept retrieval passed for both. No duplicates found; completed
token fixes and routine verification were rejected as Capture candidates.

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-eighth/usage-regressions.kujo -v
.tmp/runtime/kujo test-run tests/run_basic_runner_tests.kujo -v
.tmp/runtime/kujo run .tmp/audit-eighth/cost-unit-probe.kujo --interpreter
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 4a1bf1f5c8b3f47bc2292889c53274aea86fd8c6 HEAD
```

The four-case regression command intentionally fails before the fix. All other
listed verification commands pass. No fixture or context baseline was rewritten.
Maintenance verification uses the original eleven-file SHA256 manifest and the
original checkout's untracked status. No delivery blocker.
