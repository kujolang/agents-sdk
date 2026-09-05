# Artifacts Primitive

Module: src/agents/artifacts/store.kujo

## Purpose

Artifacts store typed durable outputs produced during runs.

## Core Contracts

- Artifact
- ArtifactKind
- ArtifactStore

## Default Behavior

- In-memory artifact store for local tests.
- Optional file-backed store with validated leaf IDs and suffixes. The caller
  owns and trusts the root directory; this is not a filesystem sandbox.
- File replacements use the runtime's atomic write operation. No automatic
  backup files are accumulated. Content whitespace and caller metadata survive
  persistence; storage-owned reference fields take precedence.
- The index remains process-local. Use distinct store IDs for distinct roots;
  listing/recovery across restarts requires a durable backend adapter.

## Policy Notes

- Enforce artifact size and kind limits.
- Configured byte limits check actual UTF-8 content bytes as well as declared
  estimates. A caller-supplied lower estimate cannot bypass a store limit.
- A missing/unreadable backing file returns `artifact_store_read_failed` rather
  than stale cached content.
- Keep metadata-only references in result payloads when possible.
