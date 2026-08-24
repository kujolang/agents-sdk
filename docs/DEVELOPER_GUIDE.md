# Developer Guide

## Quick Setup

1. Export a pinned Agents SDK runtime binary.
2. Run the offline example smoke check.
3. Run offline tests.

Commands:

```bash
export KUJO_BIN=kujo
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
"$KUJO_BIN" test
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

```bash
"$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v
"$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
"$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
```

## Agent Search Hygiene

Use `AGENTS.md` as the source of truth for canonical examples and fixture boundaries. Default readability sweeps should exclude `tests/*.out` expected-output fixtures and the historical `docs/AGENTS_SDK_BUILD_CHECKLIST.md` work log unless the task explicitly targets them.
