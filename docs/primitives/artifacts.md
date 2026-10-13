# Artifacts Primitive

Module: src/agents/artifacts/store.kujo

## Purpose

Artifacts store typed durable outputs produced during runs.

## Core Contracts

- Artifact
- ArtifactKind
- ArtifactStore

## Default Behavior

- In-memory artifact store for local tests. Automatic IDs skip IDs already in the
  store; explicit IDs retain replacement semantics.
- Optional file-backed store with validated leaf IDs and suffixes. The caller
  owns and trusts the root directory; this is not a filesystem sandbox.
- File replacements use the runtime's atomic write operation. No automatic
  backup files are accumulated. Content whitespace and caller metadata survive
  persistence; storage-owned reference fields take precedence.
- Automatic file IDs retain the timestamp prefix and gain a numeric suffix when
  a filename or indexed ID already exists. Automatic writes use atomic
  non-overwriting publication; a racing writer can cause a visible
  `artifact_store_write_failed`, never an implicit replacement. Explicit IDs
  retain atomic replacement behavior. No automatic retry is performed.
- The index remains process-local. Use distinct store IDs for distinct roots;
  listing/recovery across restarts requires a durable backend adapter.

## Policy Notes

- Enforce artifact size and kind limits.
- Configured byte limits check actual UTF-8 content bytes as well as declared
  estimates. A caller-supplied lower estimate cannot bypass a store limit.
- A missing/unreadable backing file returns `artifact_store_read_failed` rather
  than stale cached content.
- Keep metadata-only references in result payloads when possible.

## Listing and measurement

Artifact lists retain insertion order and report all matching records in `count`
and `total_count`. `offset` and `limit` select the returned page; `limit: 0` keeps
the existing unlimited-page behavior. Only records in that page are rebuilt for
return. File-backed lists use the same process-local index and pagination rules.

Run `"$KUJO_BIN" run scripts/benchmark_artifact_page.kujo --interpreter` for a
repeatable local list workload. The receipt includes query time and a result hash;
timing is diagnostic, not a CI threshold.
