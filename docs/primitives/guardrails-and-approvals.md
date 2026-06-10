# Guardrails and Approvals Primitive

Module: src/agents/security/approval.kujo

## Purpose

Guardrails and approval policies control risky operations and sensitive outputs.

## Core Contracts

- ApprovalPolicy
- ApprovalRequest
- ApprovalDecision
- ApprovalProvider
- GuardrailResult (pass/warn/block)

## Default Behavior

- Auto and deny-all providers are available.
- Stage-aware guardrail checks are supported.

## Policy Notes

- Use write_tool or permission_based approval modes for mutating tools.
- Apply redaction before persisting event/trace payloads.
