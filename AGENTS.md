# Agent Guidance

Start with `README.md`, then `docs/DEVELOPER_GUIDE.md` and `docs/EXAMPLES.md`.

Prioritize copyable examples over tests: examples should model the most token-efficient idioms we want agents to imitate.

## Canonical Surfaces

- Canonical runnable examples live in `examples/*_agent.kujo`.
- `examples/examples_smoke_runner.kujo` is the canonical offline example aggregator.
- `examples/support.kujo` is shared example support, not a standalone demo.
- `tests/*.kujo` files are contract tests and may be more explicit than examples on purpose.
- `tests/*.out` files are expected-output fixtures; do not shorten or refresh them unless the matching behavior intentionally changed.
- `docs/AGENTS_SDK_BUILD_CHECKLIST.md` is a historical build checklist and work log; scan it for context, but do not treat old implementation notes as canonical examples.

## Search Hygiene

Exclude generated/bulk paths from the main sweep unless the task explicitly targets them; document the search exclusions you used.

Default readability sweeps should start with:

```bash
rg "pattern" README.md docs examples src tests scripts \
  --glob '!tests/*.out' \
  --glob '!docs/AGENTS_SDK_BUILD_CHECKLIST.md'
```

When searching runnable examples, prefer:

```bash
rg "pattern" examples --glob '!examples/support.kujo'
```

Use full fixture searches only for behavior-contract work.

## Edit Rules

- Preserve public result shapes and deterministic offline behavior.
- Keep intro examples direct; use tiny local helpers only for repeated support plumbing.
- Do not hide the feature being demonstrated behind helpers.
- Do not blindly update expected-output fixtures or snapshots.
- Run targeted example/contract validation after each logical change.
