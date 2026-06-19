# Agents SDK Review Backlog

Review date: 2026-06-19

## Review Scope

This pass reviewed canonical user and agent surfaces first: `README.md`, `docs/DEVELOPER_GUIDE.md`, `docs/EXAMPLES.md`, `src/`, `examples/`, `tests/`, `scripts/`, and root package metadata.

Search exclusions used for the main sweep:

```bash
--glob '!tests/*.out'
--glob '!docs/AGENTS_SDK_BUILD_CHECKLIST.md'
```

The excluded paths are expected-output fixtures and a historical work log; neither should drive copyable examples or broad readability conclusions unless a task explicitly targets behavior contracts or archaeology.

## This Pass

- Public module descriptor now reports `status: active`, `maturity: experimental`, and `readiness: production_oriented` instead of the stale `stub` label.
- Package metadata now describes the package as Kujo runtime primitives built on the Kujo AI SDK.
- `kennel.toml` script strings are now copyable TOML literal strings.
- README now states the production-readiness boundary directly and clarifies why root files remain minimal while implementation lives under `src/`.

## Root File Review

The remaining root files are appropriate:

- `README.md`: primary user-facing entrypoint.
- `AGENTS.md`: repo-specific agent guidance.
- `CHANGELOG.md`, `LICENSE`: release/legal metadata.
- `agents-sdk.toml`, `kennel.toml`: package and registry metadata.
- `.gitignore`: repository hygiene.

No implementation files need to be moved from root into `src/` in this pass.

## Recommended Next Work

1. Add manifest parsing validation.

   Create a lightweight test or script that validates `agents-sdk.toml` and `kennel.toml` before release. This prevents broken script quoting or stale metadata from slipping into package publication.

2. Add a package export coverage test.

   `kennel.toml` currently exports only the top-level index and a few core modules. Decide whether all public primitive modules should be exposed in package metadata, then assert the export map matches the documented public surface.

3. Add a production adapter cookbook.

   Keep examples offline-first, but add a docs-only guide showing how a real provider adapter, persistent session store, artifact store, and trace sink should be wired behind existing boundaries.

4. Add performance micro-benchmarks for hot constructors.

   Focus on schema validation, budget accounting, redaction, memory query, and runner lifecycle event creation. Keep benchmarks deterministic and separate from contract tests.

5. Add security fixture coverage for trace/artifact redaction combinations.

   Current redaction coverage is good, but a combined runner flow that emits traces, tool IO, and artifacts through one redaction policy would make the production story stronger.

6. Add resume/handoff loop stress tests.

   Expand deterministic tests for nested handoff depth, visited-target prevention, and session restore behavior across repeated runs.

7. Add docs for deployment profiles.

   Define recommended `development`, `ci`, `staging`, and `production` profiles for timeouts, budgets, approval policies, redaction, and no-network enforcement.

8. Review `run_agent_safe_impl` stream fallback.

   The current fallback intentionally maps known stream guardrail key-access failures to `guardrail_blocked`. A future pass should make that path less string-matching dependent once the runtime map-access behavior is fixed upstream.

9. Add long-output and large-artifact budget tests.

   Strengthen coverage for output-size guardrails, artifact byte ceilings, and budget accounting under larger deterministic payloads.

10. Decide and document release maturity language.

   The codebase is production-oriented but package status remains experimental. Before a wider launch, define the exact gate for moving from `experimental` to `stable` and make README, release notes, and package metadata agree.
