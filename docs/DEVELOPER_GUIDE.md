# Developer Guide

## Quick Setup

1. Export a pinned Agents SDK runtime binary.
2. Run the module smoke check.
3. Run offline tests.

Commands:

- export KUJO_BIN=/path/to/kujo/target/debug/kujo
- "$KUJO_BIN" run examples/module_exports_smoke.kujo --interpreter
- "$KUJO_BIN" test

## Define an Agent

Minimal agent creation:

```agents-sdk
from src.agents.core_types import create_agent

agent := create_agent({
	"id": "writer-agent",
	"name": "Writer Agent",
	"instructions": "Write concise responses."
})
```

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

- "$KUJO_BIN" test-run tests/run_basic_runner_tests.kujo -v
- "$KUJO_BIN" test-run tests/example_smoke_tests.kujo -v
- "$KUJO_BIN" run examples/examples_smoke_runner.kujo --interpreter
