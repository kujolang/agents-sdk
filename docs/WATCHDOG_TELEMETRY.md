# Watchdog telemetry adapter

`src.agents.tracing.watchdog` maps Agents SDK lifecycle events to
`watchdog.telemetry.v2` without network I/O. The adapter emits metadata only:
prompts, responses, tool inputs, tool outputs, and arbitrary payload fields are
not copied. Watchdog remains authoritative for validation, privacy policy,
persistence, retention, and export.

Use `watchdog_telemetry_batch(events, batch_id, sdk_version)` and deliver the
returned `batch` to `POST /telemetry/v2/batches` through the host's bounded,
failure-isolated transport. Hosts must keep credentials outside spooled batch
files and must not make agent execution depend on optional telemetry delivery.

The stable correlation inputs are `trace_id` (falling back to `run_id`), plus
`session_id`, `run_id`, `agent_id`, and `step_id` references. Source IDs remain
provenance; the adapter derives W3C-width trace IDs without changing SDK IDs.
