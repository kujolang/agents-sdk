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

## Policy Notes

- Apply redaction metadata when payloads are sanitized.
- Preserve deterministic event ordering and sequence fields.
