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
- Optional file-backed store with safe root-path constraints.

## Policy Notes

- Enforce artifact size and kind limits.
- Keep metadata-only references in result payloads when possible.
