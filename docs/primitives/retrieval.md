# Retrieval Primitive

Module: src/agents/retrieval/provider.kujo

## Purpose

Retrieval enriches model context using external document/query sources.

## Core Contracts

- RetrievalQuery
- RetrievedContext
- RetrievalCitation
- RetrievalResult

## Default Behavior

- Deterministic mock provider available for no-network runs.
- Runner can inject retrieved context before model execution.

## Policy Notes

- Persist citation identifiers for output traceability.
- Keep retrieval interfaces provider-agnostic through adapter boundaries.

## Source text fidelity

Retrieved document string content retains leading/trailing spaces, tabs and
newlines through normalization and runner injection into model messages. This
preserves whitespace-sensitive code and source excerpts. IDs and titles keep
their existing normalization; missing or non-string content remains empty.
Consumers that intentionally trim excerpts should do so explicitly.
