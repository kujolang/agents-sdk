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
