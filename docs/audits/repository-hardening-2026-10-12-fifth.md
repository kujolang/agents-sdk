# Agents SDK hardening: retrieval response integrity

- Audit began October 12; final verification continued October 13, 2026 (America/Detroit).
- Repository: `kujolang/agents-sdk`; branch: `main`.
- Starting SHA: `5f44e2e58a96628c841f9ff675c4b743e11c9e19`, matching freshly fetched `origin/main`.
- Ending implementation SHA: `de589345af5021ef0e50135bf7bca4d4de2360a8`; citation validation: `d20123e`.
- Report-only delivery SHA: `git log -1 --format=%H -- docs/audits/repository-hardening-2026-10-12-fifth.md`.
- Write scope: existing managed Agents SDK worktree. Original detached checkout
  and all maintenance-agent files remain excluded.

This fresh audit follows the [fourth pass](repository-hardening-2026-10-12-fourth.md).
There were no intervening remote-main changes. The new attachment repeats the
same evidence-driven audit requirements. Current guidance, manifests and CI match
the prior inspected versions; this pass focuses new experiments on retrieval
response validation and source-text fidelity.

## Scope and ground truth

The package is a local-first agent orchestration library with host-injected model
callbacks. Ability is its sole pinned package dependency; Dispatch, Watchdog,
MCP and RAG integrate through explicit adapters. Reviewed current retrieval
constructors, RAG transport/normalization, runner retrieval injection, model
failure mapping and retries, tool-input validation, observability hook deduping,
context manifests and source/provenance handling. Broad sweeps cover I/O,
exceptions, serialization, TODO markers, examples and command output. Unchanged
approval/handoff, persistence, cancellation, trace and budget contracts remain
covered by the full suite and earlier source-backed reports.

Main search exclusions: generated/dependency directories, `tests/*.out`, audit
history for broad sweeps, maintenance paths, the absent historical build checklist
and shared example support where searching runnable examples. Expected-output
fixtures were executed without changes. No sibling repository was modified.

Runtime: released Kujo **1.6.0**, matching CI. Ability remains **1.0.1**, pinned to
`4aa354da8d02b027c459f692f69b523f96e97056`; dependency inputs and installed package
remain unchanged from the prior verified pass. No additional dependency or new
cache was justified. The manifest has no configured native build, linter,
formatter, typecheck or live E2E gate. No newest-dependency/advisory or live-provider
readiness claim is made.

## Baseline and verification

| Gate | Before | After |
| --- | --- | --- |
| Offline checks | 42, zero failures | 42, zero failures |
| Contract files / cases | 41 / 263 passed | 41 / 267 passed |
| Fixtures | 42/42 passed | 42/42 passed |
| Context corpus | 20 paired repetitions; 14 VM/interpreter source executions passed | Same complete gate passed |
| Token/hash ratchet | No warnings or regressions | No warnings or regressions |
| Exports / canonical examples | Covered by baseline contracts | Explicit checks passed |

Baseline evidence: `.tmp/offline-checks.Vzfb9J/` and
`.tmp/audit-fifth/baseline-{offline,context,ratchet}.log`. No tracked baseline
failure was found. New reproducers establish two bugs; a malformed-wrapper control
already passed and was not treated as a finding.

## Changes

| Priority / problem | Root cause / implementation | Evidence and affected files | Compatibility |
| --- | --- | --- | --- |
| P2: malformed RAG citation identity escaped as a runtime error | An ID was checked only against the empty string before concatenation with `rag-`. Require a nonempty string before constructing references. | `retrieval/rag_adapter.kujo`; numeric ID reproduced `Invalid binary operation: string + int`. Regression covers integer, float, boolean, null, array, object and empty IDs, including a preceding valid citation. All return structured `invalid_response` without partial documents or raw content. | Successful response shapes and valid string IDs remain unchanged. Invalid upstream IDs now return the documented failure envelope. No coercion, retry or fallback document. |
| P2: retrieved source text lost significant whitespace before reaching the model | General string normalization trimmed document content in the constructor, context formatter and final message constructor. Preserve string content at the document boundary and through the retrieval-specific message path. | `retrieval/provider.kujo`, `runner.kujo`; the four-space-indented `return value` line lost indentation and its newline before the fix. Constructor, RAG and full runner tests now preserve exact spaces, tabs, CRLF, blank strings and Unicode. | IDs/titles and ordinary AgentMessage normalization remain unchanged. Missing/non-string content remains empty. Retrieval consumers now receive original text; callers intentionally relying on trimming should trim explicitly. |

Four new cases extend existing contract files. They run in the normal offline
CI glob. The full runner case verifies exactly one transport callback, no malformed
content in model messages, preserved `invalid_response` diagnostics and the
existing best-effort retrieval failure behavior (the model can still complete).
Primitive and RAG docs describe the corrected contracts. No snapshot was refreshed.

## Measurements and efficiency

The exact source excerpt `    return value\n` contains **17 UTF-8 bytes**. Before,
the normalized document contained **12 bytes** (`return value`); afterward all
**17 bytes** survive, including in the asserted model request. This five-byte
increase restores required source content; it is not inefficiency to optimize away.
The malformed numeric-ID probe changes from an uncaught runtime error to a failed
retrieval result. Valid and malformed runner cases each make exactly **one**
transport call, established by a local callback receipt that the test removes.

No latency, CPU, RSS, binary-size or model-token savings are claimed. Existing
pagination/byte-accounting optimizations remain under the full suite; no further
runtime optimization had sufficient measured benefit to justify additional code.
Source text fidelity can increase context bytes when whitespace was previously
lost. Canonical context baseline files, prompts, schemas, dependency surface and
normal command-output volume remain unchanged. Logs stay in local evidence files;
no extra model-visible diagnostic payload or giant stdout report was introduced.

## Boundaries, interfaces and remaining work

The RAG transport remains host-configured: one request, bounded response bytes,
timeout, DNS pinning and no redirects in the provided HTTP callback. This pass
makes no live network call and does not change endpoint/authentication policy.
Malformed response content is rejected before reference construction and is not
copied into errors. Valid retrieved text remains data; approval/capability and
registered-handler authority are unchanged. The established trusted-provider
requirement for system-role retrieval context remains in force.

Public exports/signatures, CLI behavior, file formats, schemas, config and
environment variables did not change. The intentional observable differences are
structured rejection of malformed citation IDs and retention of retrieved source
whitespace. These are source-integrity fixes; no cross-repository change or
coordinated release is required. Host retention/concurrency, cooperative callback
timeouts and private filesystem roots remain documented operational boundaries.

Remaining **P0/P1/P2: none established and left unresolved by this pass**.
**P3 / not worth changing:** cosmetic rewrites, consolidation of small normalizers,
or another membership optimization without a representative measured benefit.
**Needs more evidence:** production-scale memory/latency and application-specific
transport behavior. No new unresolved external finding. SignalBox: no captures warranted.

## Commands and receipts

```bash
git fetch origin
git merge --ff-only origin/main
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/ci_no_network_enforcement.sh
KUJO_BIN="$PWD/.tmp/runtime/kujo" bash scripts/verify_context.sh
.tmp/runtime/kujo run scripts/context_token_ratchet.kujo --interpreter -- --check
.tmp/runtime/kujo test-run .tmp/audit-fifth/rag-regressions.kujo -v
.tmp/runtime/kujo run .tmp/audit-fifth/runner-text-regression.kujo --interpreter
.tmp/runtime/kujo test-run tests/rag_adapter_tests.kujo -v
.tmp/runtime/kujo test-run tests/retrieval_provider_contract_tests.kujo -v
.tmp/runtime/kujo test-run tests/retrieval_single_call_tests.kujo -v
.tmp/runtime/kujo run examples/module_exports_smoke.kujo --interpreter
.tmp/runtime/kujo run examples/examples_smoke_runner.kujo --interpreter
bash -n scripts/ci_no_network_enforcement.sh scripts/verify_context.sh
git diff --check
bash .github/scripts/check-kujo-tool-artifacts.sh 5f44e2e58a96628c841f9ff675c4b743e11c9e19 HEAD
```

The temporary regression suite had two intentional before-fix failures and one
passing control; all three pass after changes. The model-input reproducer failed
before and passes after. Targeted provider (4), RAG (5) and single-call runner (4)
cases passed. Final per-test receipts are in `.tmp/offline-checks.EJ39Uc/`;
`.tmp/audit-fifth/final-{offline,context,ratchet}.log`, `exports.log` and
`examples.log` record passing checks. No fixture or context baseline changed.
Shell syntax, diff hygiene and commit-range artifact guard passed. SHA256 checks
confirm all 11 maintenance-agent files match their original hashes and remain
untracked in the untouched detached checkout. No unresolved delivery blocker.
