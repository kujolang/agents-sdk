# Controlled Ability tools (experimental, unreleased)

`register_controlled_ability_gateway_tool` and
`controlled_ability_gateway_to_tool_contract` add host callbacks to the existing
Ability gateway projection. Standalone `register_ability_gateway_tool` is unchanged.
There is no Dispatch package dependency and no verifier in the SDK.

The host installs `invoke(call, context)`, `admit(context)` and
`record(admission, context, result)` at registration. `admit` must check the current
controller-owned execution context on every invocation, including duplicates; it
returns `ok`, a stable `ability_invocation_id` and an application `idempotency_key`.
These are never read from model arguments. The embedding application authenticates
the principal at its gateway; SDK metadata is attribution only.

The runner adds the model's `tool_call_id` and its own `sdk_invocation_id` (tool
step ID) to tool context metadata. These identify different things. A model call
ID is not authority. SDK run IDs, Ability invocation IDs, Dispatch attempts and
business transactions MUST NOT be substituted for each other. Hosts must bind
model attribution to a controller-issued invocation, and prevent duplicate ticket
use. Replays require a newly admitted Dispatch attempt. Ability retains its stable
application invocation/key so a duplicate can return the original receipt.

`record` receives the private existing gateway result after receipt validation.
It persists evidence through authorized host storage and returns `ok` plus a
`sha256:` content reference. The public controlled result contains business output
on success and only that handoff reference as metadata. Uncertain failures expose
`ability_completion_uncertain` with a handoff reference; private receipt bodies and
exception messages are withheld. Input/admission failures happen before invocation.
Recording failure exposes `ability_evidence_unavailable`, never permission to retry.
The host must preserve transport failure, missing receipt and receipt failure in
private evidence; an error does not establish that the business mutation failed.

## Handoff

`agents-sdk.ability-handoff/v1alpha1` is a closed, at most 4096 UTF-8-byte reference
object, described by `schemas/ability-handoff-v1alpha1.schema.json`. IDs use bounded
ASCII grammar (no newline); digests are lowercase SHA-256. References are exactly
`sha256:` plus 64 hex characters. Receipt ID/reference are both null or both set;
receipt outcomes require a receipt. Assurance may initially be null. Adding a
sidecar produces a new immutable handoff and leaves the original untouched.

Digests commit exact retained artifact bytes, not reconstructed objects. The local
example writes sorted `to_json` bytes without whitespace and resolves digest-only
filenames below an operator-owned root with bounded no-symlink reads. No paths,
URLs, configuration, authenticated identities, payloads or verification flags are
handoff fields. Consumers must validate integrity and exact correlation with the
current authoritative execution result. A matching handoff is not replay authority.

Dispatch's optional `load_agents_ability_handoff` checks correlation before its
existing persisted beta admission/live Ability verifier. It must run under the
existing run lock. Dispatch alone owns review, replay and descendants. SDK approval
hooks may add a denial or present a UI; they cannot approve a Dispatch continuation.
The SDK executes each emitted tool call once; its retry counters do not create a
tool retry loop. A second model call is another invocation requiring host admission.

## Offline proof

`examples/controlled-ability/participant.kujo` is an operator embedding used by
Dispatch's `tests/sdk_ability_integration.mjs`. It uses a deterministic model,
real SDK runner, authenticated SQLite Ability gateway and real persisted Dispatch
beta review/checkpoint path. A business commit plus receipt-store failure pauses;
new processes attach assurance, verify and replay with one logical business effect.
The example requires the current sibling Ability/Dispatch source runtime, not SaaS.
Its ticket files are host anti-duplication records, not a second policy engine.

Watchdog receives existing tool-call lifecycle records with bounded attribution.
It does not receive receipts or control authority. RunLedger is not required by
this slice. SDK/app/controller processes share trusted local infrastructure; this
is not remote authentication, hostile-host isolation, exactly-once or machine-loss
recovery. If evidence publication fails, continuation stays unavailable for review.

The host `invoke` callback MUST also bind the actual validated application input to
its admitted intent; admission by context alone does not authenticate arbitrary
model arguments. The example compares the call against the operator-owned
invocation before reaching Ability. Correlation metadata is added only to tools
registered through the controlled projection, preserving ordinary tool contexts.
