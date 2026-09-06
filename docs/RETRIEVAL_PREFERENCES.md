# Programming-language retrieval preferences

Agents SDK carries an optional programming-language hint to retrieval providers,
tool handlers, and handoff child runs. A supporting adapter can select relevant
examples before they enter model context. Unsupported handlers keep their existing
behavior. No HTTP headers, model instructions, network calls, or language detection
are added by this feature.

```kujo
from src.agents.core_types import create_agent_run_request

request := create_agent_run_request("Show the Rust client", {
    "metadata": {"retrieval_preferences": {"programming_language": "rust"}}
})
```

The runner resolves the value once with `resolve_retrieval_preferences(agent,
request)` in `src.agents.core_types`. Precedence is explicit request metadata over
agent metadata defaults over unset. A harness may place a reviewed project
preference in the agent default; task selection belongs in the request. File
extensions, repository language counts, runtime, prompts, and `kujo.toml` are not
automatically interpreted. An explicit empty, null, malformed, or unsupported
preference namespace suppresses the default. An empty/invalid language is omitted.

Identifiers are trimmed, lowercased, limited to 64 ASCII characters, and follow
`[a-z][a-z0-9_-]*`. `c++` maps to `cpp` and `c#` to `csharp`. Other valid identifiers
remain extensible; there is no registry of supported languages. Unknown preference
fields are not propagated. Natural-language locale is outside this contract.

The same resolved dictionary reaches:

- `RetrievalQuery.metadata.retrieval_preferences` before provider retrieval;
- `ToolExecutionContext.metadata.retrieval_preferences` before tool execution;
- handoff request metadata, taking precedence over the target agent's default.

Existing unrelated retrieval-query metadata is preserved. A retrieval policy's
nested preference cannot override the task. With no preference, tool/query metadata
has no added signal (an existing query preference namespace is cleared). The input
request remains unchanged through Kujo value semantics. The feature does not add a
field to `AgentContext` or change provider options.

Adapters must use only a recipient's supported mechanism: a documented query/body
field, a tool argument declared by its schema, or mutually agreed MCP metadata.
A local RAG adapter should preserve general guidance alongside matching examples;
file extension alone does not identify the example languages inside Markdown.
Do not turn a preference into an authorization filter.

For an MCP server explicitly configured to understand this **Kujo-specific** key:

```kujo
from src.agents.integrations.adapters import create_mcp_2026_call_tool_request

// Inside a tool handler; only on the explicitly supported server route:
request_options := {"meta": {
    "ai.kujolang/retrieval_preferences": context["metadata"]["retrieval_preferences"]
}}
wire := create_mcp_2026_call_tool_request("docs", input, request_options)
```

`meta` support already exists; no new automatic MCP negotiation is implemented.
Do not send this key when the internal preference is absent. For unsupported
servers, use the existing request unchanged. Keep MCP's JSON/SSE transport media
types; Markdown belongs inside resource/tool content. Do not use
`Accept-Language` for code languages, and do not introduce a global
`X-Code-Language` header. HTTP documentation adapters must encode parameters,
respect variant cache keys, and recheck support after redirects.

AI Chat and the Dispatch CLI are independent runtimes, not an automatic chain
through Agents SDK. Dispatch integration callbacks preserve their supplied
payloads, so host glue can pass this request contract directly. A new AI Chat
setting or a Dispatch CLI-wide adapter requires a concrete supporting consumer;
neither is implied by this change.

Verification: `kujo test-run tests/retrieval_preferences_tests.kujo -v` covers task
override, normalization, unknown identifiers, suppression, retrieval metadata,
Dispatch hook payloads, supported MCP mapping, unsupported handlers, provider
isolation, handoff, and absence. These are offline contract tests, not a claim
that a third-party MCP server implements this extension.

## Empty results and provider failures

The runner calls the retrieval provider once per pre-model retrieval attempt.
Empty matches remain empty, and provider failures retain their error payload.
Legacy top-level documents, citations, and summaries are normalized from that
same response; explicitly present context fields take precedence. Summary-only
results are valid. Constructor option names stay distinct across nested calls
to prevent the interpreter from replacing the outer result options.

`tests/retrieval_single_call_tests.kujo` checks actual callback receipts and
content preservation, including wrapped legacy envelopes and multiple documents.

## Supported Kujo RAG adapter

`src.agents.retrieval.rag_adapter` exports `create_kujo_rag_provider` and `create_kujo_rag_http_transport`. This is an explicit Kujo RAG `/query` adapter, separate from the core propagation contract.

```kujo
from src.agents.retrieval.rag_adapter import create_kujo_rag_provider, create_kujo_rag_http_transport

provider := create_kujo_rag_provider({
    "namespace": "default",
    "supports_preferences": true,
    "transport": create_kujo_rag_http_transport("http://127.0.0.1:8787", {})
})
```

Only set `supports_preferences` for a recipient implementing the RAG request field. Its default is false; older recipients receive an ordinary query. The transport callback receives a POST `/query` descriptor and returns `{status_code, body}` with the decoded RAG envelope. A custom callback owns endpoint selection, authentication, timeout, redirect, and byte limits.

The provided HTTP transport takes a host-configured base URL and optional `bearer_token`, `timeout_seconds` (default 10), and `max_response_bytes` (default 1 MiB). It pins DNS under runtime network policy, follows no redirects, and makes one call without probing or retrying. It sends no code-language headers. Keep the endpoint and credentials outside model arguments.

Successful citations become retrieved documents with their original text, paths, and source line ranges. Empty citations remain empty; non-success HTTP responses, invalid envelopes, and transport exceptions remain failures. Provider errors do not expose response bodies or authentication values.

`examples/rag_documentation_agent.kujo` is an **opt-in live retrieval** example. Start the RAG documentation pilot, then run it with `RAG_URL` and optional `RAG_EXAMPLE_LANGUAGE=python`. The model callback is local and prints the actual messages presented to it; no model inference is billed. This live example is intentionally excluded from the offline smoke aggregator. RAG's `scripts/verify_retrieval_preferences.py` checks this real transport and records exact tokenizer counts for captured model-input content.
