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

## Optional live observation

Pass `producer_instance` (a unique host invocation namespace) and `on_lifecycle`
to `run_agent`. `src.agents.tracing.lifecycle.create_lifecycle_spool(path, bytes)`
is the provided metadata-only local sink. Give every execution a private spool;
262144 bytes is the Observer example limit. Overflow writes a `.gap` sidecar.
The callback is exception-isolated, carries no inputs/results/exception text,
and has no network delivery or animation acknowledgement. It observes the run,
pre-model retrieval, tool execution envelopes, and actual child handoffs.
Operation start and terminal records are distinct. Internal provider retries
are not claimed as separate attempts; the host can supply `observation_attempt`
for an explicitly retried invocation. Missing identity disables observation.

Use local storage. Append byte size is bounded; this is not a hard real-time
filesystem-latency guarantee, and arbitrary custom callbacks must obey the same
bounded, no-network contract. Callback return/failure never changes source work.
Child handoff runs retain their own run and agent IDs and inherit the sink.

`examples/agent_city_observer.kujo` runs actual local RAG with an explicitly
labeled offline model callback. `CITY_HANDOFF=1` adds an actual SDK child handoff.
Dispatch's separately owned example supplies run correlation. City is an
external consumer; it does not become an SDK or Dispatch execution dependency.

### Agent City Observer metadata

`observation_profile` and `observation_collection` are explicit source metadata;
absent values remain `unknown`. Live handoff envelopes include the actual
source-qualified child execution in `metadata.relatedInstance`. These fields
carry no prompts, messages or tool results.

`examples/agent_city_mcp.kujo` registers a real read-only local Kujo MCP tool
handler. The handler's operation envelope preserves server identity read from
`/health`, tool name, invocation, attempt and bounded result classification.
It uses the same bounded local lifecycle spool. HTTP occurs in the business
tool handler, never in the observation callback. Its optional metadata artifact
has a separate outcome; an artifact failure cannot change a completed MCP call.
