# Repository Hardening Engineering Receipt

Recorded 2026-09-05; observations began 2026-09-04.

## Scope and Baseline

- Repository: Kujo Agents SDK, branch `main`. This is an interpreter-first agent
  runtime library with deterministic examples, not a frontend or hosted service.
- Starting commit: `c48cde3303003e0952aca8a720f5754c59ea9bf7`.
- Reviewed implementation end: `a539905a994aca995e8a85cd11d57695e281acdc`.
  The subsequent report-only commit is discoverable with
  `git log -1 -- docs/audits/repository-hardening.md`; a commit cannot embed its
  own final hash.
- Implementation commit: `9cd6d78`; complete offline CI gate: `a539905`.
- Read README, developer guide, examples, architecture, public contracts,
  integration boundaries, security/persistence documentation, source modules,
  tests, manifests, scripts, and CI. Main searches excluded `tests/*.out`, the
  historical `docs/AGENTS_SDK_BUILD_CHECKLIST.md`, generated/dependency paths,
  and preexisting untracked `src/maintenance`. Fixtures were inspected only for
  behavior-contract verification. No sibling repository was modified.
- The starting tracked suite contained 180 test-block cases, all passing on
  released Kujo 1.2.2. The old CI command executed only two test-block files
  (9 cases), then fixture execution. `kujo test` alone does not run test blocks.
- The machine's default Kujo 1.0.0 cannot resolve some current package imports.
  Verification used released macOS x64 Kujo 1.2.2, checked against its release
  SHA-256 sidecar, matching the repository CI version pin.
- Ability remains pinned to `4aa354da8d02b027c459f692f69b523f96e97056`
  in manifest and lockfile. No dependency upgrades or new runtime dependencies
  were justified. Existing CI/runtime tooling pins remain unchanged.

## Findings and Changes

| Priority | Evidence / finding | Resolution |
| --- | --- | --- |
| P1 | Explicit invalid approval modes allowed execution; provider `ok:false` with approved status could authorize a handler. | Invalid explicit modes deny; both successful resolution and approved status are required. Omitted mode keeps its compatible default. |
| P1 | Invalid or throwing guardrail callbacks could pass or escape policy handling. | Unsupported/malformed results block; callback exceptions return structured blocking results. |
| P1 | External adapter risk was lost at registry normalization. | Project risk into the registry's canonical field while preserving legacy metadata; regression checks approval and full metadata. |
| P1 | A multi-call model response could exceed the tool-call limit before the next budget check. | Check prospective usage before each tool side effect. Regression observes one call with a one-call limit. |
| P1 | Recursive dictionary reconstruction loses nested sibling state in the interpreter. | Replace 13 recursive clone helpers with native value semantics; preserve nested metadata and mutation isolation. Rename a colliding session constructor local. Upstream runtime follow-up remains open. |
| P2 | Artifact limits trusted caller estimates and undercounted multibyte content. | Enforce actual UTF-8 content bytes when a cap is active, without trusting a smaller supplied estimate. |
| P2 | File artifacts trimmed content, lost caller metadata on replacement, allowed unsafe extensions, and used a non-atomic backup/write sequence. | Preserve exact content and caller metadata, validate suffixes, use atomic writes, and report missing-file reads. |
| P2 | JSONL path checks compared boolean containment to an integer; corrupt records were silently ignored. | Use substring indices, return line-numbered corruption errors, append directly, and retain only requested page records. |
| P2 | Gateway projection accessed identity fields before validating definitions. | Validate first and return the existing structured validation result. |
| P2 | Runner fallback mislabeled a missing-key implementation error as a guardrail decision. | Preserve actual error classification and stream telemetry; remove the heuristic fallback. |
| P2 | Most contract tests were absent from the CI execution path; trace tests tolerated failed writes. | Execute every contract, assert successful trace persistence, retain separate fixture checks, and upload detailed logs with seven-day retention. |

The first six targeted regressions failed before their fixes. The prospective
tool-budget regression also failed before its fix. The final hardening file has
16 passing cases, including nested constructor metadata, callback exceptions,
UTF-8 limits, file replacement, corrupt JSONL, and stream error classification.
Existing snapshots were not blindly refreshed or committed.

## Performance and Efficiency

The reproducible microbenchmark is `scripts/benchmark_tool_metadata.kujo`.
It creates 200 tools with 32 metadata fields, verifies exact metadata JSON, and
prints an output checksum. Serial runs on the same host and released 1.2.2
interpreter gave:

| Revision | Elapsed milliseconds, three samples | Median |
| --- | --- | --- |
| Starting revision | 586, 611, 588 | 588 ms |
| Reviewed implementation | 446, 484, 529 | 484 ms |

All six runs returned `ok:true` and checksum
`51fb473ee21f13a6c046f2089c118b439438129953fbe35a5f55da41074decc0`.
The observed median reduction is approximately 18% for this small constructor
benchmark, not an application-wide performance guarantee. Earlier samples under
concurrent test load varied substantially. No RSS, provider-token, billing, or
end-to-end throughput improvement is claimed.

Native value semantics remove repeated recursive reconstruction while preserving
contract values. Trace pagination avoids accumulating every matching parsed
record, but still reads the whole raw file: host rotation remains necessary.
CI now runs 196 contract cases instead of 9, with a compact receipt and detailed
per-check files rather than streaming every successful assertion. Failure output
still points directly to complete evidence. No speculative caching, batching,
provider routing, or dependency replacement was added.

## Compatibility and Security Boundaries

- Public exports and principal result shapes are preserved; external risk and
  failed-model stream metadata are additive. Deterministic examples remain valid.
- Intentional tightening: invalid explicit policy modes, malformed guardrails,
  failed approvals, unsafe extensions, and corrupt trace lines no longer succeed
  permissively. Omitted approval policy mode is not changed to deny by default.
- Artifact content now preserves whitespace exactly. Replacement uses atomic
  overwrite rather than producing automatic backup files. Storage metadata is
  authoritative when keys conflict with caller metadata. The public byte estimate
  remains compatible; cap enforcement independently checks actual UTF-8 bytes.
- No manifest, lockfile, persistent schema, environment-variable contract, or
  public SDK CLI migration was introduced. Verification stdout is intentionally
  compact; `KUJO_BIN` remains the existing runtime override.
- Contract tests run untrusted with filesystem read/write/delete and clock only;
  AI, network, shell, and subprocess capabilities are not granted. Fixture checks
  use the separate snapshot runner. No live provider credentials were required.
- Callbacks execute cooperatively in the host process. Timeouts cannot preempt a
  blocking callback; provider retries need host-side bounded attempt/time budgets.
  Store roots, file ownership, symlinks, retention, and concurrency are host trust
  boundaries, not an OS sandbox. In-memory stores require host lifecycle limits.
- Retrieval inserted into system context must come from a trusted provider.
  Existing sanitizer fallback is compatibility behavior, not a confidentiality
  enforcement boundary. These limitations are stated in the production guide;
  changing these public contracts needs a separately designed migration.

## Verification Receipt

The final staged source/CI changes were applied to an isolated archive of the
starting tracked tree, with the existing pinned dependency installation linked
in. This excludes unrelated untracked maintenance-agent work without deleting it.

```bash
KUJO_BIN="$PWD/../hardening-runtime/kujo" bash scripts/ci_no_network_enforcement.sh
```

Executed from `.tmp/hardening-verify`: **27 checks, zero failed**. Detailed local
evidence is in `.tmp/hardening-verify/.tmp/offline-checks.wpN0YP/`:

- 26 contract files: **196 total, 196 passed, 0 failed**.
- Fixture runner: **26/26 passed**, no skipped or expected failures.
- Final targeted hardening contracts: **16/16 passed**.
- Targeted registry, integration adapters, module exports, and canonical offline
  example aggregator also passed during implementation.
- `bash -n scripts/ci_no_network_enforcement.sh` and `git diff --check` passed.
- The repository's Kujo-tool-artifact commit-range guard passed.
- No separate lint/typecheck/frontend build is configured for this SDK; no live
  provider integration or production deployment was attempted.

To reproduce the constructor benchmark, run the script three times with the same
runtime in each revision. The starting archive used the identical benchmark
script and same pinned dependency directory. Local `.tmp` evidence is ignored,
not a portable committed test artifact; CI retains new run logs for seven days.

## Remaining Work and Cross-Repository Follow-up

### Kujo Interpreter Local State (P1, SDK Cases Mitigated)

This minimal program errors with `Missing map key "z"` (exit 4) on the released
1.2.2 interpreter and the read-only sibling build reporting 1.2.3. The VM returns
the correct value. The sibling build is a local build, not a verified release.

```kujo
func clone_value(value) {
    if type(value) == "dict" {
        source := value
        cloned := {}
        for key in keys(source) { cloned[key] := clone_value(source[key]) }
        return cloned
    }
    return value
}
print(to_json(clone_value({"a": {"value": "original"}, "z": "sibling"})))
```

Expected: `{"a":{"value":"original"},"z":"sibling"}`. Runtime call-frame/local
state isolation and interpreter/VM parity tests need review in `kujolang/kujo`.
This repository avoids that reconstruction pattern; it cannot repair the language
runtime. No sibling files were changed.

SignalBox admitted this one unresolved finding after exact/concept deduplication:

- Capture: `cap_459ef66e-3402-4151-90ef-932c6f01a048`.
- Signal: `sig_8d9a5ed9-ba57-4955-839d-44aa43f28472`.
- Exact-ID and concept retrieval passed for both. No duplicates were skipped.
  Resolved implementation work and routine verification were rejected as capture
  candidates; they belong in this receipt and Strata, not new Signals.

### Preexisting User Work (Not Committed)

`docs/MAINTENANCE_AGENT.md`, `maintenance_agent.kujo`, `src/maintenance/`, and
`tests/maintenance_agent_tests.kujo` were untracked at the start and remain
untouched. Their initial test-block baseline was 1/5 passing. A final targeted
run is 3/5 passing, with the artifact-budget event-count and sanitizer assertions
still failing. Running the expanded gate against the entire working directory
therefore is not green; stale ignored maintenance fixtures may also differ.
The tracked release snapshot is green. These unrelated files were not swept into
hardening commits merely to obtain a clean status. The owner must resolve or
separately commit that work before the whole working tree can be called clean.

### Needs Further Evidence

Callback preemption, per-attempt provider accounting, multiprocess persistence,
untrusted retrieval roles, and sanitizer failure policy require explicit host or
API contracts before broader changes. No unsupported claim of comprehensive
vulnerability elimination or production capacity is made by this bounded audit.
