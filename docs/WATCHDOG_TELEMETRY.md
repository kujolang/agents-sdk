# Watchdog telemetry adapter

`src.agents.tracing.watchdog` maps Agents SDK lifecycle events to
`watchdog.telemetry.v2` without owning network I/O. Run, model, tool, and
handoff start/terminal event pairs map to stable canonical spans; approvals,
guardrails, memory, artifacts, and budget milestones map to events. The
adapter emits metadata only:
prompts, responses, tool inputs, tool outputs, and arbitrary payload fields are
not copied. Watchdog remains authoritative for validation, privacy policy,
persistence, retention, and export.

Use `watchdog_telemetry_batches_from_run_result(result, batch_id, sdk_version)`
to convert a completed or failed `AgentRunResult`; it chunks runs larger than
100 events into bounded batches. `watchdog_telemetry_batch` remains available
when lifecycle events are already collected. Deliver each batch to
`POST /telemetry/v2/batches` through the host's bounded, failure-isolated
transport. `watchdog_deliver_batches` composes host callbacks and always fails
open: unsuccessful network delivery may use `queue_batch_fn`, but never changes
the agent result. Hosts must keep credentials outside spooled batch files.

The stable correlation inputs are `trace_id` (falling back to `run_id`), plus
`session_id`, `run_id`, `agent_id`, `step_id`, tool-call, handoff-request,
artifact, workflow, and evaluation references. Source IDs remain provenance.
Already-valid W3C trace IDs are preserved; other SDK IDs are deterministically
projected to W3C-width IDs. `watchdog_trace_context` returns a `traceparent`
that callers can propagate to model, MCP, Dispatch, or child-agent boundaries.

Usage preserves input/output/total, cache-read/cache-write, reasoning, and the
bounded provider payload. Provider-reported cost remains explicitly identified
as provider-reported; the adapter never converts an estimate into billed cost.
Prompts, responses, tool arguments/results, retrieval bodies, output text, and
detailed errors are never copied by this adapter.
