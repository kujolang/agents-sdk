# Tracing Primitive

Module: src/agents/tracing/sink.kujo

## Purpose

Tracing records lifecycle events for observability and diagnostics.

## Core Contracts

- TraceEvent
- TraceSink

## Default Behavior

- In-memory sink for deterministic test assertions.
- Optional JSONL sink for local persistence/export.
- Append creates the file when needed without a separate existence check.
- Malformed JSON or non-object records return `trace_sink_read_failed` with
  a one-based line number. Corrupt lines are not silently discarded.
- Both sinks preserve insertion order and count all matching records. In-memory
  pagination rebuilds only the requested page; `limit: 0` remains unlimited.
  Large offsets/limits do not require adding them together.
- JSONL reading still buffers the source file; hosts must rotate/bound logs.

## Policy Notes

- Apply redaction metadata when payloads are sanitized.
- Preserve deterministic event ordering and sequence fields.

For a repeatable local pagination workload, run
`"$KUJO_BIN" run scripts/benchmark_trace_page.kujo`. Its fixed input
timestamps keep the result hash deterministic. Timing is diagnostic, not a CI
threshold.
