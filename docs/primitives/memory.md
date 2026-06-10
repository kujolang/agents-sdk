# Memory Primitive

Module: src/agents/memory/store.kujo

## Purpose

Memory stores scoped long-term or run-adjacent entries with provenance metadata.

## Core Contracts

- MemoryEntry
- MemoryQuery
- MemoryQueryResult
- MemoryStore

## Default Behavior

- Noop memory store for no-write contexts.
- In-memory scope-aware implementation for deterministic tests.

## Policy Notes

- Enforce memory write policy controls for restricted scopes.
- Include provenance tags for auditing and citations.
