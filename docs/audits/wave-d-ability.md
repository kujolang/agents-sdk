# Wave D Ability Tool audit and implementation plan

2026-09-27. Starting SDK bb2202d8b54f44717b1b1f0157a6774f2027cea1,
Ability ca9acea544e9a8a806f1f09d42b4ca7b5299bd18,
Dispatch 5fc27fe7c4a7a0bd20e896ce49d5a96b3c067d54,
Kujo 6f06e41bfcabc67c0e1669a493f941863a2bf865. Fetched main matched.
SDK work occurs in an isolated worktree; existing untracked maintenance-agent work
in the original checkout is unrelated and preserved.

## Existing source-backed lifecycle

| Surface | Source and behavior | Owner/trust |
|---|---|---|
| Definition/projection | abilities/contract.kujo validates canonical definition, schemas, digest and local handler binding | Ability semantic identity; application exposure/permissions |
| Model call | runner.kujo reads tool name/input from model calls; registry resolves installed handler | Provider/model assertion, not authority |
| SDK execution | core_types/runner create SDK run/step identities; registry creates ToolExecutionContext | SDK lifecycle; distinct from Dispatch attempt |
| Input | registry validation plus Ability validate_ability_value | SDK structure; Ability/application semantics |
| Gateway invocation | ability_gateway_handler builds invocation, optional host metadata key/approval, SDK correlation | Host ID/key or existing fallback; principal NOT authenticated by SDK |
| Authentication | Ability application gateway authorize checks session token hash and canonical principal in operator SQLite | Application authority, external to model JSON |
| Receipt | SDK validates canonical receipt, invocation/Ability/version/definition; success validates output schema | Application-reported evidence, no replay permission |
| Tool result/error | registry retains handler metadata on success; wraps failure in tool_execution_failed | SDK envelope; existing gateway failure may include full receipt |
| Retry | runner calls execute_tool once per emitted call and fails terminally on error; max_tool_retries is reported configuration but no execution loop | No hidden automatic tool replay; duplicate model calls still need host admission |
| Approval | registry approval policy/provider gates before handler | Local deny gate, not Dispatch intervention authority |
| Telemetry | tracing/watchdog maps existing lifecycle; prompts/input/output/error detail excluded; delivery fail-open | Observation only |
| Artifacts | artifacts/store and tool metadata retain references | Evidence transport, not authority |
| Replay | Dispatch assurance_admission/configuration/runner locked persisted negotiation, live Ability verifier, v1 replay predicate | Dispatch exclusively |

See tests/ability_contract_tests.kujo for existing receipt identity/output behavior;
docs/WATCHDOG_TELEMETRY.md and tracing/watchdog.kujo for privacy. Ability gateway
business and receipt commits are separate; receipt commit failure is not business
failure. Existing Wave C semantics need no change.

## Planned minimal change

Add an experimental controlled gateway wrapper next to the current Ability
projection. Reuse projection/receipt/schema validation. Require host admission and
host evidence persistence callbacks; neither callback comes from model input.
Preserve standalone exports unchanged. Propagate SDK-generated invocation and
model-call attribution separately in ToolExecutionContext. Controlled errors are
content-light and remain uncertain after gateway/receipt/transport failures.

A bounded versioned handoff carries SDK and Dispatch correlation plus content-addressed
receipt/result/assurance references; no payload or verifier configuration. The SDK
only checks structure/correlation. Dispatch's opt-in embedding resolves artifacts
under an operator root, checks exact expected identities, then uses existing beta
admission. No new control lifecycle, package cycle, provider policy or beta verifier
inside SDK.

Prove real publication through a fresh SDK process called by a Dispatch action,
forced receipt-store failure after business commit, review/checkpoint, fresh
controller and SDK replay, one business row. Exercise model injection, reference
and identity substitution, process restarts and standalone receipt replay. Existing
Watchdog tool/run records remain observations. Optional RunLedger integration is
deferred; the durable Dispatch journal/result references remain correlation source.

Validation: SDK canonical offline suite plus context gates/examples; real Ability
owner verification; Dispatch full release gate/new integration; Kujo docs checks.

## Implementation and local validation

The opt-in controlled wrapper reuses the gateway's input/receipt/output validation.
Host admission runs per call; failed receipts remain uncertain and private. The
handoff is a closed 4096-byte reference contract. The runner adds correlation only
to controlled tools; applying it globally initially broke the unset-preference
metadata regression and was corrected before final validation.

The real participant runs under the SDK's documented interpreter path. Named
callbacks did not capture host lexical variables; explicit closures fixed the
fixture. The SDK uses no Dispatch implementation imports. The standalone gateway
continues to replay the application's retained receipt without synthetic Dispatch
identity. No Kujo runtime or Ability stable contract change was required.

Local checks: all 41 offline checks pass; controlled tool tests pass; module-export
and examples smoke pass; context contracts, 20 paired repetitions and 14 dual
runtime source executions pass; token ratchet passes. The Dispatch cross-repository
fixture proves business commit/receipt failure, fresh controller review/replay,
14 rejected substitutions, one logical effect and standalone replay. The complete
cross-repository evidence record is owned by Dispatch's Wave D rehearsal document.
