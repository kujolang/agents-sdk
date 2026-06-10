# Handoffs Primitive

Module: src/agents/handoffs/handoff.kujo

## Purpose

Handoffs transfer execution to configured target agents with explicit policy control.

## Core Contracts

- HandoffRequest
- HandoffResult
- HandoffPolicy

## Default Behavior

- Runner supports explicit handoff requests and deterministic merge behavior.
- Depth and loop protections prevent recursive handoff cycles.

## Policy Notes

- Track visited targets and max depth in run metadata.
- Emit started/completed/failed handoff events for auditability.
