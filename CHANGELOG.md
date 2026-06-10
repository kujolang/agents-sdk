# Changelog

## 2026-05-22

### FEATURE

- Added production-oriented agent runtime modules for tools, approvals, guardrails, memory, sessions, retrieval, handoffs, tracing, artifacts, budgets, streaming, and integration boundaries.
- Added deterministic no-network fixture harness and offline-first example set.

### FIX

- Hardened example smoke runner output serialization to avoid function-to-JSON conversion failures.

### TWEAK

- Expanded package scripts for full test, contract test, example smoke, and offline verification flows.
- Added module responsibility and integration boundary documentation for adapter-first architecture.

### SECURITY

- Added security and production guidance for approval policies, redaction, and dangerous tool controls.

### PERFORMANCE

- Kept deterministic local fixtures as default runtime path to avoid network latency and flaky CI behavior.

### REFACTOR

- Standardized architecture docs and primitive references around explicit module boundaries.
