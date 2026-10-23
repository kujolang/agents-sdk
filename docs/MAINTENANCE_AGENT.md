# Maintenance agent example

`examples/maintenance_agent.kujo` combines fixture inspection, write approval,
redaction, project-scoped memory, sessions, and typed artifacts in an offline run.
It is an application example, not a project-cleanup command. The model response
and five file records are synthetic; no project files are read, moved or deleted.

## Run

```bash
kujo run examples/examples_smoke_runner.kujo
kujo test-run tests/maintenance_agent_tests.kujo -v
```

Call the example from a Kujo program to inspect its full result:

```kujo
from examples.maintenance_agent import run_maintenance_agent

approved := run_maintenance_agent({"run_id": "maintenance-approved"})
print(to_json(approved["stored_artifacts"]))

denied := run_maintenance_agent({"approval_provider_kind": "deny_all"})
print(denied["result"]["status"])
```

The default `auto` provider simulates approval for the fixture. It is not human
consent for real filesystem writes. The `write_tool` policy permits inspection
and gates the plan tool; `deny_all` blocks the write and leaves the store empty.
A production application must supply its own approval and persistence boundaries.

## Evidence and storage

The approved run completes five steps and two tool calls. Its in-memory artifact
store contains the JSON cleanup proposal and the runner's Markdown summary.
`result.artifacts` contains the runner's final output; inspect `stored_artifacts`
for both records, including producer IDs and the actual plan content. Test cases
verify JSON targets, types, provenance, denial, and isolation between demo runs.

Support modules live under `examples/maintenance/`. Each invocation resets its
example stores. Memory contains the final summary under the project scope;
sessions record lifecycle state. None of these stores survive process exit.
The sanitizer masks synthetic token, secret, and authorization fields before
tool output reaches the runner.

## Budget behavior

Setting `budget_policy` to `{"mode":"enforce","budget":{"limits":{"max_artifact_bytes":1}}}`
produces `budget_exceeded` at the `after_artifact` lifecycle check. This check
occurs after artifact persistence and does not roll back the plan or summary.
Its artifact counter measures the runner output, not every tool-emitted byte.
Use the artifact store's own limits when a hard per-artifact write cap is needed.

Budget error results retain usage counters and lifecycle steps, but do not expose
the completed-run `metadata.tool_calls` list. The test checks the two executed
calls through budget usage rather than assuming success-only result metadata.

For real maintenance, a separate operator-controlled application must validate
and approve a plan before executing changes. This example grants no such power.
