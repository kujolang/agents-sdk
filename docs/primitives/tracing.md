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
- Pagination keeps only the requested matching records while counting all
  matches. Reading still buffers the source file; hosts must rotate/bound logs.

## Policy Notes

- Apply redaction metadata when payloads are sanitized.
- Preserve deterministic event ordering and sequence fields.
