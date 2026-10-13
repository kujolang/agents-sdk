# Sessions Primitive

Module: src/agents/sessions/store.kujo

## Purpose

Sessions persist conversation/run continuity across turns and resumptions.

## Core Contracts

- Session
- SessionMessage
- SessionState
- SessionStore

## Default Behavior

- In-memory implementation is deterministic and ordered.
- Session state can include resumable run snapshots.
- Deletion clears saved run state even when the runner saved a snapshot without
  creating a separate Session record. Other session IDs remain intact; creating
  the same session later does not restore the deleted snapshot.

## Policy Notes

- Session data should be scoped and validated before persistence in hosted environments.
- Sensitive fields should be redacted before external export.
