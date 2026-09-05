# Developer Guide

## Quick Setup

1. Export a pinned Agents SDK runtime binary.
2. Run the offline example smoke check.
3. Run the complete offline verification command.

Commands:

```bash
export KUJO_BIN=kujo
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
bash scripts/ci_no_network_enforcement.sh
```

Expected example-smoke output:

```json
{"approval_agent":{"ok":true,"requires_network":false,"status":"failed"},"artifact_agent":{"ok":true,"requires_network":false,"status":"completed"},"handoff_agent":{"ok":true,"requires_network":false,"status":"completed"},"hello_agent":{"ok":true,"requires_network":false,"status":"completed"},"retrieval_agent":{"ok":true,"requires_network":false,"status":"completed"},"tool_agent":{"ok":true,"requires_network":false,"status":"completed"},"traced_agent":{"ok":true,"requires_network":false,"status":"completed"}}
```

## Define an Agent

Minimal agent creation:

```agents-sdk
from src.agents.core_types import create_agent

agent := create_agent({
	"id": "writer-agent",
	"name": "Writer Agent",
	"instructions": "Write concise responses.",
	"handler_id": "writer-handler",
	"execution_contract": {"id": "report-writer", "version": "1"},
	"capabilities": {"write_report": true},
	"model_candidates": [{"provider": "openai", "model": "approved-model"}]
})
```

`handler_id` identifies the runtime implementation. `execution_contract` identifies agents that may safely substitute for each other even when their handlers differ. Routing engines should require the same handler or an exact execution-contract ID/version match before agent substitution. `model_candidates` are declarative references only; provider metadata and selection policy remain owned by the AI SDK and the external orchestrator.

## Register Tools

```agents-sdk
from src.agents.tools.registry import create_tool_registry, register_tool

registry := create_tool_registry({})
register_result := register_tool(registry, {
	"id": "tool.echo",
	"name": "echo_tool",
	"input_schema": {
		"type": "object",
		"required": ["content"],
		"properties": {
			"content": {"type": "string"}
		}
	},
	"handler": func(input_payload, context) {
		return {
			"ok": true,
			"output": {
				"content": input_payload["content"]
			}
		}
	}
})
```

## Project a Portable Ability into a Tool

Keep the portable definition separate from the local binding and exposure
policy. The adapter validates both the definition and every invocation:

```agents-sdk
from src.agents.abilities.contract import register_ability_tool
from src.agents.tools.registry import create_tool_registry

registration := register_ability_tool(create_tool_registry({}), {
	"schema": "kujo.ability/v1",
	"id": "kujo.docs.content.find",
	"version": "1.0.0",
	"description": "Find a bounded set of documentation records.",
	"input_schema": {
		"type": "object",
		"required": ["query"],
		"properties": {"query": {"type": "string", "minLength": 1}},
		"additionalProperties": false
	},
	"output_schema": {
		"type": "object",
		"required": ["count"],
		"properties": {"count": {"type": "integer", "minimum": 0}},
		"additionalProperties": false
	},
	"effects": [{"kind": "read", "resource": "kujo.docs.content"}],
	"idempotency": {"mode": "intrinsic"}
}, {
	"handler": func(input_payload, context) {
		return {"ok": true, "output": {"count": 1}}
	}
}, {
	"name": "find_documentation",
	"permissions": ["docs.read"]
})

ability_registry := registration["registry"]
ability_tool := registration["tool"]
```

Do not put credentials, transport details, tenant policy, approval state, or a
handler reference into the Ability definition. Those belong to the binding or
exposure inputs. The canonical definition validator and schema come from the
exact `ability` package revision pinned by Kennel; the projected Tool metadata
contains a digest that can be compared with a discovery document or receipt.

When execution belongs to a remote service, register the same definition with
`register_ability_gateway_tool`. Its `invoke` callback is the transport seam:
it receives a `kujo.ability.gateway-call/v1` payload and must return
`{"receipt": <canonical receipt>}`. Put `ability_invocation_id`,
`ability_approval_id`, and `ability_idempotency_key` in the Tool execution
context metadata when supplied by the caller. The SDK validates the receipt,
matches it to the exact definition and invocation, validates successful output,
and preserves it in `result.metadata.handler.ability_receipt`. The callback—not
the portable Ability definition—owns authentication, endpoint selection, and
response-envelope normalization.

## Run Non-Stream Mode

```agents-sdk
from src.agents.ai.adapter import create_ai_sdk_adapter
from src.agents.runner import create_agent_runner, run_agent
from src.agents.core_types import create_agent_run_request

adapter := create_ai_sdk_adapter({
	"chat_completion_fn": func(client, messages, request_options) {
		return {
			"ok": true,
			"provider": "mock-provider",
			"model": "mock-model",
			"output_text": "done",
			"status_code": 200
		}
	}
})
runner := create_agent_runner({"ai_adapter": adapter})
request := create_agent_run_request("Write summary", {
	"run_id": "run-dev-guide",
	"session_id": "session-dev-guide"
})
result := run_agent(runner, agent, request, {"tool_registry": register_result["registry"]})
```

## Run Stream Mode

```agents-sdk
stream_result := run_agent(runner, agent, request, {
	"stream": true,
	"tool_registry": register_result["registry"]
})
```

## Use Deterministic No-Network Fixtures

```agents-sdk
from src.agents.testing.no_network import create_no_network_harness

harness := create_no_network_harness({})
runner := create_agent_runner({"ai_adapter": harness["model_adapter"]})
```

## Validate Locally

Use Kujo 1.2.2 (the CI pin) and install the exact Ability dependency from
`kennel.lock` before validating. An older runtime may fail to resolve the
`ability` package even when its installed directory exists.

`bash scripts/ci_no_network_enforcement.sh` executes every `tests/*_tests.kujo`
file with `test-run`, then checks fixture snapshots with `kujo test`. Snapshot
execution alone does not execute test blocks. The script continues collecting
failures, exits nonzero if any check fails, and prints a short receipt with the
private local log directory under `.tmp/`. CI uploads those logs for seven days.

Contract execution uses `--untrusted` with only filesystem read/write/delete
and clock capabilities enabled. Network, AI, shell, and subprocess capabilities
remain denied. Fixture execution uses Kujo's separate snapshot runner.

```bash
"$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v
"$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
bash scripts/ci_no_network_enforcement.sh
```

## Agent Search Hygiene

Use `AGENTS.md` as the source of truth for canonical examples and fixture boundaries. Default readability sweeps should exclude `tests/*.out` expected-output fixtures and the historical `docs/AGENTS_SDK_BUILD_CHECKLIST.md` work log unless the task explicitly targets them.
