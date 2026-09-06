# Programming Language Negotiation Audit

Date: 2026-09-06. Scope: `/Users/robertdevore/2026/Kujolang/kujo-repos`.
Canonical committed copy: `agents-sdk/docs/audits/PROGRAMMING_LANGUAGE_NEGOTIATION_AUDIT.md`.
The identical workspace-root copy is the requested entrypoint. This directory is
not an ecosystem Git repository: Git walks up to `/Users/robertdevore/2026`, whose
remote identifies a different project. The audit does not add ecosystem files to
that unrelated parent repository.

Current implementation status: the authorized P0–P2 follow-up is merged into main across **four repositories: agents-sdk, rag, ai-chat, and dispatch**. AI Chat and the local docs.kujolang.ai RAG dogfood service are configured and verified. The existing overdue RAG security-review gate remains open for production release readiness. See [the rollout checklist and measured evidence](RETRIEVAL_PREFERENCES_ROLLOUT.md). Historical audit observations below are retained as baseline evidence where labeled.

## 1. Executive Summary

Yes, Kujo can carry a task's code-language preference early enough for a supporting
retrieval provider or tool adapter to select examples before building model
context. The value belongs to the task/harness, not the model provider or HTTP
runtime. There is no verified universal code-language negotiation header in the
standards and provider documents reviewed. `Accept-Language: en-US, python` is not
a portable expression of a Python code preference.

The initial audit implemented Agents SDK metadata propagation and AI Chat Markdown reading. The authorized follow-up now adds a real RAG documentation recipient, equivalent-example selection, preference-aware caching, Agents SDK HTTP retrieval, AI Chat's persisted language control and documentation tool, Dispatch task/step mapping with retry/resume persistence, and MIME-aware HTTP ingestion. The duplicate empty-retrieval callback is fixed.

The local HTTP pilot verifies each host against the recipient. Actual Agents SDK model-input content falls from 509 tokens to 365 for Python or 356 for JavaScript using cl100k_base, retaining shared warnings and citations. These are fixture-context measurements, not paid-model quality or latency claims. No universal header, inferred language, or model-provider change is introduced.

## 2. Architectural Finding

The actual paths differ from the proposed linear diagram:

```text
User / coding harness
  |
  +--> AI Chat lib/server-runtime.js
  |      +--> bridge_chat.kujo --> external AI SDK --> provider API
  |      +--> direct provider/Watchdog/Codex paths
  |      +--> lib/tool-runtime.js --> page fetch / search / browser / actions
  |
  +--> Agents SDK AgentRunRequest.metadata.retrieval_preferences
  |      + agent.metadata default
  |      --> runner resolves once
  |          +--> RetrievalQuery.metadata --> configured retrieve_fn
  |          +--> ToolExecutionContext.metadata --> configured handler
  |          +--> handoff child request metadata
  |          +--> AI adapter --> AI SDK/provider (no preference forwarding)
  |
  +--> Dispatch CLI --input-json --> persisted run input --> step payload
         +--> src/agents/agent.kujo --> sdk_adapter / bridge_chat --> AI SDK
         +--> src/tools/tool.kujo --> handler(payload, context.input)

Optional Agents SDK Dispatch hooks preserve host-supplied payload/options.
A recipient-aware tool adapter translates the one task value to its supported
query/body field, declared tool argument, or agreed MCP metadata key.
```

Primary trace evidence, reviewed in the requested order:

1. **AI Chat:** `bridge_chat.kujo` forwards provider/model/messages/tools and
   approved request headers to AI SDK. `lib/server-runtime.js` executes model
   tool calls through `toolRuntime.execute` with cancellation, scope, credentials,
   model, and request state. `lib/tool-runtime.js` forwards this context to the
   registered page/browser/action executors. Search is an independent SearXNG or
   Ollama adapter. No current structured task code-language setting was found.
2. **AI SDK:** `src/ai_sdk.kujo` builds a provider driver's request descriptor,
   applies protected-header/endpoint policy, and invokes an injected or native
   transport. Native drivers encode/decode; core owns transport. Model catalog
   preferences select provider models, not documentation example languages.
   Adding code hints to these headers would target the wrong recipient.
3. **Agents SDK:** `src/agents/core_types.kujo` already stores request and agent
   metadata. Before this change, `runner.kujo` built retrieval metadata only from
   retrieval policy and constructed tool context without request preferences.
   `tools/registry.kujo` and `retrieval/provider.kujo` already preserve metadata.
   `integrations/adapters.kujo` preserves explicit MCP `meta` and Dispatch hook
   payload/options. The missing link was runner propagation, not a new transport.
4. **Dispatch:** `src/core/runner.kujo::execute_tool_step` supplies persisted
   `run_state.input` as `context.input`; `build_step_input` and payload adapters
   select each step's input. The built-in source lookup searches local fixtures.
   It does not route every tool through Agents SDK. Host integration can map
   structured task input into AgentRunRequest metadata using existing callbacks.

**Source of truth and precedence.** Implemented: explicit request preference
namespace > agent default namespace > unset. A present empty/invalid namespace
suppresses defaults. Only `programming_language` is propagated. Harnesses may
choose a reviewed project preference as the agent default and put an explicit
user/task selection in request metadata. No universal file > project > dominant
language hierarchy is justified by these independent runtimes.

`scout/lib/scout_runtime.kujo` detects per-file language from an extension map and
counts languages. These are repository facts, not task intent; `.h`, JSX/TSX and
mixed repositories need care. `packwrite/src/repo_context.kujo::detect_stack`
reports manifest-derived languages/runtimes, including `node`, which cannot
resolve JavaScript versus TypeScript. `kujo.toml` marks a Kujo project in that
scanner, not a documentation preference. Spec task text, agent instructions, and
current artifacts can inform a host's explicit selection, but are not parsed or
inferred by this feature. Runtime implementation language (Rust/Kujo/Node) is never
used as the agent's requested example language.

## 3. Standards Analysis

| Option | Status | Decision |
| --- | --- | --- |
| A: `Accept-Language: en-US, python` | HTTP field for natural-language ranges; not code-language negotiation | Reject. Syntactic acceptance of a token does not give it programming-language semantics. |
| B: `X-Code-Language` / `X-Programming-Language` | No interoperable definition verified | Do not introduce globally. A provider-documented private field can be mapped by that provider's adapter. |
| C: query/body parameter | Ordinary API mechanism; field meaning is API-specific | Prefer when documented. Encode and sign through the existing adapter. |
| D: MCP argument / metadata / capability | Standard extensibility mechanisms; code-language semantics remain private | Use schema-declared arguments first, or agreed namespaced metadata. Preserve protocol requirements. |
| E: emerging convention | Markdown negotiation is deployed; universal code-language header not verified | Track adoption; do not claim an absence across the entire Internet. |
| F: multiple mechanisms | Adapter strategy, not a new standard | Select one supported mechanism per destination; otherwise omit. No probing or speculative retries. |

HTTP distinguishes representation media types from natural-language ranges.
`Vary` identifies selecting request fields for caches. A code identifier can look
like a language range while still being semantically inappropriate; locale
middleware may ignore it, select unexpected translations, or produce 406.
[HTTP Semantics, RFC 9110 §§12.5.1, 12.5.4–12.5.5](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.4).

`text/markdown` is a registered media type, not a code-language selector.
[RFC 7763](https://www.rfc-editor.org/rfc/rfc7763.html).
The `X-` prefix is not a standards shortcut and is discouraged for newly defined
parameters. [RFC 6648](https://www.rfc-editor.org/rfc/rfc6648.html).
The reviewed IANA field registry has no match for `Programming` or `Code-Language`;
that is bounded evidence, not proof that no informal header exists.
[IANA HTTP fields](https://www.iana.org/assignments/http-fields).

Cloudflare documents serving Markdown in response to an `Accept: text/markdown`
request. That supports format negotiation as a practical integration, but says
nothing about selecting Rust versus Python examples.
[Cloudflare Markdown for Agents](https://blog.cloudflare.com/markdown-for-agents/).
Context7's documented library/query/type parameters and response `codeList`
illustrate task-aware documentation retrieval and multi-language response data;
they do not establish a universal code-language header.
[Context7 API guide](https://context7.com/docs/api-guide),
[Context7 OpenAPI](https://github.com/upstash/context7/blob/master/docs/openapi.json).

MCP 2026-07-28 preserves per-request metadata and defines Streamable HTTP's
JSON/SSE `Accept` requirements. It also specifies schema-declared `x-mcp-header`
mirroring to `Mcp-Param-*`: this is a transport mechanism, not a standardized
programming-language parameter. Never replace MCP's `Accept` with Markdown.
Kujo's helpers are deliberately partial request builders, not a complete MCP
transport implementation. The proposed `ai.kujolang/retrieval_preferences` key is
**Kujo-specific**, supported only by explicit agreement; no standard capability
name or automatic capability discovery is claimed.
[MCP overview](https://modelcontextprotocol.io/specification/2026-07-28/basic),
[MCP Streamable HTTP](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http).

## 4. Repository Matrix

P0 = source/propagation; P1 = immediate consumer; P2 = meaningful integration;
P3 = future opportunity; P4 = no action. Priority is relevance, not a demand to
modify the repository. The following inventory includes every immediate child
with its own `.git` entry, including duplicate worktrees and empty checkouts.
Primary and candidate paths received manual call-path review; other rows received
README/source-surface triage. Source scans excluded generated dependencies,
output/runtime data, fixtures, and bulk lockfiles where applicable. Symbol aliases,
subprocess curl, vendored runtime copies, and generated SDKs were followed manually
in relevant paths; a zero string-match count is not proof of no network activity.

| Repo | Priority | Relevant code | Opportunity | Recommended action |
| ---- | -------: | ------------- | ----------- | ------------------ |
| `ability` | P2 | `README.md; schema/` | Portable schemas can declare relevant parameters | No change; preferences are not authority or portable effect policy |
| `ability-gateway` | P2 | `src/http.ts; src/mcp.ts` | Server-owned MCP/HTTP translation | No change until supported ability declares the parameter |
| `agents-sdk` | P0 | `src/agents/core_types.kujo; src/agents/runner.kujo; src/agents/integrations/adapters.kujo` | Request metadata to retrieval/tools/handoffs | Implemented normalization, propagation, single-call normalization and explicit RAG HTTP adapter |
| `agents.kujolang.ai` | P2 | `build.kujo; content/agents/` | Agent definitions and static discovery | Future task defaults when explicitly configured |
| `ai-chat` | P0 | `lib/server-runtime.js; lib/tool-runtime.js; lib/page-fetch.js` | Host owns task intent; static evidence consumer | Implemented Markdown reader, persisted language selector and configured RAG documentation tool |
| `ai-chat-tool-repair` | P4 | `lib/tool-runtime.js; lib/browser-runtime.js` | Alternate AI Chat checkout | No duplicate implementation; integrate from canonical repository |
| `ai-sdk` | P0 | `src/ai_sdk.kujo; src/provider_driver.kujo` | Provider boundary; not retrieval preference owner | No change required; keep provider headers unchanged |
| `anthropic` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `assetworks` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `azure-ai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `baseten` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `bedrock` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `benchmarks-capsule` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `benchmarks-capsule-v3` | P4 | `No tracked source at inspected HEAD` | Empty/incomplete checkout | No change required; no independent boundary to implement |
| `benchmarks-system` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `bluepencil` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `casefile` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cerebras` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `changebucket` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cinch` | P3 | `README.md` | Editor/harness can know selected artifact | Future explicit host mapping; no inferred setting now |
| `cloudflare-ai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `cms` | P2 | `backend/routes/abilities.kujo` | Content delivery and executable abilities | Future docs-specific projection if corpus supports it |
| `cms-contact-form` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cms-example` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cms-experience` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cms-field-notes-theme` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `cohere` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `commerce` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `commerce.robertdevore.com` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `concord` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `contentgraph` | P3 | `README.md` | Source content relationships | Future example-language metadata; no locale redefinition |
| `crud-api` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `deepinfra` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `deepseek` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `diff-viewer-demo` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `diff-viewer-demo-fresh` | P4 | `No tracked source at inspected HEAD` | Empty/incomplete checkout | No change required; no independent boundary to implement |
| `diff-viewer-inline-review-fresh` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `diff-viewer-verified` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `dispatch` | P0 | `src/core/runner.kujo; src/tools/tool.kujo; sdk_adapter.kujo` | Persisted task input and host callback orchestration | Implemented workflow/run/step mapping, persistence across retries/resume and opt-in RAG plugin |
| `docs.kujolang.ai` | P1 | `assets/js/docs.js; kujo-ssg.yml` | Documentation content and search producer | Future corpus-aware selection; no assumption server honors new header |
| `dossier` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `email` | P4 | `mcp/server.kujo; sdk/kujo/email.kujo` | Email application API | No code negotiation required |
| `eval` | P3 | `README.md; tests/` | Deterministic acceptance and quality comparisons | Future relevance/bandwidth benchmark; no runtime change |
| `fal` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `fence` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `fireworks` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `galleypack` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `gemini` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `groq` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `hermes-kujo-chain-of-command` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `hermes-kujo-discord-agents` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `hermes-motoko-red-team` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `howl` | P3 | `README.md` | Example manifests and rendered showcase cards | Future code-block tagging; no outbound negotiation needed |
| `huggingface` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `intake` | P4 | `src/adapters/email.js; README.md` | Inbound business evidence | No code negotiation required |
| `kennel` | P4 | `README.md` | Git/package distribution and runtime installation | No change; artifacts and package metadata must remain exact |
| `kujo` | P4 | `src/interpreter/native_functions/http.rs` | General HTTP and MCP language-runtime facilities | No change; runtime must not guess coding language or mutate Accept |
| `kujo-agents` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `kujo-benchmark-ap-audit-20260811-021429` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-benchmark-ap-audit-20260811-025659` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-benchmark-ap-audit-20260811-025724` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-benchmark-ap-audit-20260811-025727` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-docs` | P3 | `assets/js/docs.js; README.md` | Older documentation checkout | No change; identify active publishing source first |
| `kujo-hyperframes` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-pi` | P2 | `src/extension.ts; src/operations.mjs` | Harness-to-CLI and service requests | No change; add explicit task input only with matching consumer contract |
| `kujo-pinned-web` | P4 | `src/interpreter/native_functions/http.rs` | Alternate runtime checkout | No change; follow canonical runtime decision |
| `kujo-release-v1.3.0` | P4 | `src/interpreter/native_functions/http.rs` | Alternate runtime checkout | No change; follow canonical runtime decision |
| `kujo-release-v1.3.1` | P4 | `src/interpreter/native_functions/http.rs` | Alternate runtime checkout | No change; follow canonical runtime decision |
| `kujo-skills` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `kujo-ssg-webmcp` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `kujo-upgrade-linux-race` | P4 | `src/interpreter/native_functions/http.rs` | Alternate runtime checkout | No change; follow canonical runtime decision |
| `kujo-videoops` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `kujo-workflows` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `kujolang-mcp` | P2 | `src/registry.kujo; src/catalog.kujo` | Bounded catalog search and Markdown resources | No change; catalog is not a multilingual example server |
| `kujolang.ai-source` | P4 | `No tracked source at inspected HEAD` | Empty/incomplete checkout | No change required; no independent boundary to implement |
| `kujolang.ai-work` | P2 | `build.kujo; assets/js/site.js` | Public ecosystem documentation producer | Future indexed content selection; no global header rewrite |
| `kujolang.ai.incomplete` | P4 | `No tracked source at inspected HEAD` | Empty/incomplete checkout | No change required; no independent boundary to implement |
| `kujolang.ai.sparse` | P4 | `No tracked source at inspected HEAD` | Empty/incomplete checkout | No change required; no independent boundary to implement |
| `leash` | P3 | `README.md; daemon/native/fcm.kujo` | Supervised agent control and notifications | Future task input; no preference on push/auth requests |
| `lens` | P2 | `bridge/browser-bridge.js; bridge/flow-bridge.js` | Browser navigation and visual QA | No change; HTML/rendered layout is the intended evidence |
| `mcp` | P1 | `src/server/runtime.kujo; src/resources/registry.kujo; integrations/kujo-ability/bin/kujo-ability-mcp.mjs` | MCP resource/tool delivery and gateway bridge | No change: preserve JSON-RPC and declared schemas |
| `mistral` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `muzzle` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `nvidia-nim` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `ollama` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `openai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `openrouter` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `packwrite` | P2 | `src/repo_context.kujo` | Manifest-derived languages/runtime and suggested checks | No change; node is not a code-language selection |
| `paperclip` | P3 | `src/features/context/generate.ts; schemas/context-pack.schema.json` | Context pack construction | Future task-owned preference; retain current pack schema |
| `patchbrief` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `perplexity` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `presswire` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `rag` | P1 | `src/connectors.kujo; src/retrieval.kujo; src/vector_backend.kujo` | HTTP docs and pre-ranking filters | Implemented MIME-aware ingestion, opt-in equivalent-example groups, selection and cache variants |
| `readersignal` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `redact` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `relay` | P3 | `src/watchdog.kujo; README.md` | Bounded missions and provider routing | Future explicit mission input; provider transport unchanged |
| `replicate` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `runledger` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `scent` | P3 | `README.md; repository-owned context and agent artifacts` | Can preserve explicit task context | No change; optional future mapping, no automatic language inference |
| `scout` | P2 | `lib/scout_runtime.kujo; lib/path_filters.kujo` | File languages and repository counts | No change; optional host input, never automatic task preference |
| `searchbridge` | P2 | `src/adapters.kujo; src/registry.kujo; src/transport.kujo; src/core.kujo` | Provider-specific query projection, budgets and fingerprints | No change: existing language is locale/SEO; code docs need a concrete adapter |
| `shipcheck` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `site-kit` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `sitekit-docs-template` | P1 | `build.kujo; scripts/docs_search_index.kujo` | Documentation producer and local search index | Future example-language tags and variant URLs |
| `siteprobe` | P4 | `src/siteprobe.py` | HTML crawler for website intelligence | No change; HTML metadata and links are required evidence |
| `source` | P3 | `src/submit.js; src/git-http.js` | Work/evidence platform and Git transport | Future task metadata only; never change Git responses |
| `spec` | P3 | `README.md; schema/` | Task contracts can express desired output | No schema expansion without an executing consumer |
| `ssg` | P1 | `build.kujo` | Static site index, generated WebMCP and Markdown content | Follow up on served representations; keep visual/link checks on HTML |
| `stego-cipher-kujo` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `storydesk` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `together` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `totalrecall` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `tribunal` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `truthlens` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `versionseal` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `vertex-ai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `ward` | P4 | `README.md; tracked source surface` | Local tooling, domain API, showcase or alternate checkout | No change required for code-example negotiation |
| `watchdog` | P4 | `dashboard_server.kujo; clients/javascript/watchdog-telemetry.mjs` | Provider proxy and telemetry | No change; do not leak task preferences into provider calls |
| `watchdog-date-filters` | P4 | `dashboard_server.kujo` | Alternate Watchdog checkout | No change; follow canonical proxy decision |
| `workcell` | P2 | `src/domain/caller_context.kujo; src/execution/coordinator.kujo` | Execution definitions and strict caller correlation metadata | No change; do not add unknown fields to caller_context/v1 |
| `workcell-studio` | P3 | `webmcp/register-tools.js; README.md` | Browser workspace tool schemas | Future explicit artifact/task selector; no transport change |
| `xai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |
| `zai` | P4 | `README.md; provider package source` | Model/native inference API; own parameter and signing policy | No change required; no universal documentation preference |

Inventory: 123 Git-backed immediate children. Non-Git directories were scope-screened, not treated as separate publishable repositories: `artifacts`, `data`, `depcount`, `eael-test`, `eael-test-validation`, `ecosystem-pattern-audit-2026-06-11`, `frontier-skills`, `jackson-mi-market-research`, `kujo-benchmarks`, `kujo-command`, `kujo_repair`, `repomap`, `results`, `seo-audit`, `site_checks`, `tmp`. These are evidence, scratch, generated/partial projects or unversioned surfaces; no blanket modifications were made.
## 5. P0 Changes

Implemented in Agents SDK:

- Keep the optional value in `metadata.retrieval_preferences`; no parallel context
  object, giant enum, per-repository header constants, or new dependency.
- Normalize at the runner entry once, then forward the same bounded dictionary
  to existing retrieval/query and tool metadata seams. Carry it to child handoffs.
- Preserve default behavior when absent; leave unrelated metadata and provider
  options alone. Invalid explicit values suppress defaults instead of triggering
  a guessed replacement.
- Document host responsibility and test actual runner execution, not just a
  serialization helper. Tests exercise Dispatch hook and MCP request-builder
  seams with explicit fixture support; they do not claim a deployed end-to-end
  AI Chat → Dispatch → remote MCP integration.

Implemented in AI Chat: negotiate and accept Markdown on the existing static
page-reader path. Existing HTML/plain servers continue to work in a single fetch.
This has a real supported recipient convention without needing a code-language
header. The common HTTP client preserves `accept` through redirects and continues
to enforce DNS/URL/output policy.

**Markdown baseline review.** Before this change, the traced AI Chat reader sent
HTML/plain `Accept` and rejected a Markdown response. No automatic Markdown
request default was found in the other reviewed outbound retrieval paths.
`mcp` and `kujolang-mcp` advertise or return Markdown resources; that is response
content, not an HTTP request header. AI Chat's browser allowlist preserves its
browser-supplied `accept`/natural `accept-language`; search expects JSON. RAG's
HTTP docs connector preserves explicitly configured headers through its curl
command but has no centralized format preference and derives file parsing from
saved paths. SSG browser search uses JSON indexes. There is therefore no existing
ecosystem-wide Markdown negotiation layer to extend. Centralize format policy in
recipient-aware readers; transport clients should preserve permitted headers,
not select document formats globally.

## 6. P1 Changes

The following original P1 recommendations have now been implemented for the explicitly configured Kujo RAG recipient; see the linked rollout record for verification. Their original rationale is retained:

1. Build one corpus-backed documentation adapter with example-language metadata
   and generic prose retention. Accept a structured parameter, select matching
   examples before serialization, and report what was actually selected. A
   preference is a ranking/selection hint, not grounds to discard all fallback
   guidance or conceal that no matching example exists.
2. Connect that adapter to the existing Agents SDK metadata seam. Only then add an
   explicit AI Chat task control or Dispatch step mapping where users need it.
   Do not implement a setting whose value has no effective recipient.
3. For RAG, annotate code blocks/chunks with their example languages. Existing
   `query_filters` supports extension/tags/path and filters local candidates
   before ranking; `.md` contains many possible code languages, so translating
   `python` blindly to `.py` is wrong. Existing remote vector storage and ingestion
   should retain partition/authorization filters when adding language selection.
4. RAG's `run_http_docs_connector` already permits configured headers but saves
   using URL-derived filenames and follows redirects through curl. Markdown
   negotiation should be coupled to MIME-aware ingestion, destination checks,
   and index provenance, not added as a standalone default header.
5. Preserve selected fields in response/cache receipts: requested versus applied
   language, returned format, cache variant, result size and request count. Avoid
   recording full URLs/queries/code where telemetry privacy settings exclude them.

Historical issue, resolved by Agents SDK commit `a66ae54`: Agents SDK's existing
`maybe_inject_retrieval_context` invokes the raw provider callback again whenever
normalized documents are empty, including legitimate empty results. Language
selection can increase empty results, making this implicit second request
particularly relevant. A counting provider returning `ok: true` and `context.documents: []` reproduced
two calls on unchanged baseline `9c8763d`: `runner.pre_model` followed by
`runner.pre_model.raw_fallback`, ending in `completed`. Evidence is retained at
`/tmp/kujo-negotiation-empty-repro.log`; the minimal reproduction is shown below.
Redesign fallback around demonstrable normalization loss before changing its
compatibility behavior.
The initial audit preserved this behavior for review; the follow-up normalizes the original response without another callback and preserves explicit failures. Three regression cases fail the pristine baseline and pass the fix.
SignalBox Capture `cap_ed841074-5013-42ff-b362-59b3a62a999a` and Signal
`sig_443a36cd-350e-425b-90cb-72a4001481cb` preserve it; exact-ID and conceptual
retrieval succeeded. No duplicates matched the two pre-write queries. Completed
implementation summaries, speculative integrations, maintenance work owned by
another task, and normal verification outputs were not captured.

Minimal offline reproduction from the Agents SDK repository root:

```kujo
from src.agents.core_types import create_agent, create_agent_run_request
from src.agents.runner import create_agent_runner, run_agent
from src.agents.ai.adapter import create_ai_sdk_adapter
from src.agents.retrieval.provider import create_retrieval_provider_interface
provider := create_retrieval_provider_interface({"retrieve_fn": func(provider, query, options) {
    print(options["source"])
    return {"ok": true, "context": {"documents": []}}
}})
runner := create_agent_runner({"ai_adapter": create_ai_sdk_adapter({
    "chat_completion_fn": func(client, messages, options) {
        return {"ok": true, "status_code": 200, "output_text": "done"}
    }
})})
run_agent(runner, create_agent({"policy": {"retrieval": {"enabled": true}}}),
    create_agent_run_request("no matches", {}), {"retrieval_provider": provider})
```

## 7. Future Opportunities

| Dimension | Useful upstream action | Constraint |
| --- | --- | --- |
| Framework | Select relevant guide/API section | Task must identify framework; do not infer it from runtime alone |
| Library/API/runtime version | Return compatible signatures and migration notes | Version-aware corpus and cache key; keep security/deprecation guidance |
| Package manager | Select install command | Explicit project lockfile/user choice; do not scan repeatedly |
| OS/architecture | Select installation/build snippet | Target deployment may differ from harness host |
| Format | Markdown or structured fields instead of page chrome | Preserve protocol media types and evidence needed for visual QA |
| Detail budget | Request top-k, fields, page size, excerpt limits | Apply before network transfer when service supports it; distinguish bytes/tokens |

SearchBridge already has page/row/output/call budgets, provider capabilities,
query fingerprints, and deterministic provider projection. Extend those mechanisms
for a real documentation provider instead of creating another global preferences
framework. SSG's generated site index and MCP catalog tools already enable bounded
structured discovery; narrowing a query often matters more than a new header.
Context7-style library/version/query selection is an example of this principle,
not a requirement to integrate that service in this task.

**Harness interoperability:** Codex, Claude Code, Cursor, Gemini CLI, Pi, or a
generic MCP client can supply an explicit schema-supported argument or host
configuration. No uniform built-in preference across those clients was verified
or relied on. Kujo should preserve that explicit value, allow the task to override
the host's default, and omit it on unsupported routes. Stdio MCP carries metadata
in JSON-RPC without HTTP headers. Modern/legacy MCP capability exchange differs;
keep it inside the versioned connector. A recipient may advertise a documented
extension during normal discovery, but no extra network discovery is needed for a
statically configured route. Unsupported services should receive their old request
rather than being required to tolerate arbitrary fields. If a provider ignores a
supported optional hint, accept its normal result and do not claim filtering.

## 8. Token Efficiency Impact

The completed local pilot is measured in the rollout record: 28.3%/30.1% less actual Agents SDK model-input content for Python/JavaScript. Ecosystem-wide savings remain unmeasured. The following original estimate is illustrative only.
With shared prose `P`, `N` examples of roughly `E` tokens each, and overhead `H`,
upstream example selection saves approximately `(N - 1) * E - H` tokens. A
hypothetical page with 800 prose tokens and six 300-token examples falls from
2,600 to 1,100 tokens when one example is selected: about 58% for that constructed
case. This is arithmetic, not a benchmark or guaranteed tokenizer ratio.

| Boundary traced | Usefulness and why the recipient can act | Mechanism / disposition |
| --- | --- | --- |
| AI Chat static docs (`page-fetch.execute → safeRequest`) | High format value: an enabled docs server can render Markdown | Implemented weighted `Accept`; HTML/plain fallback, no extra request |
| Agents SDK retrieval (`runner → retrieval_provider_retrieve → retrieve_fn`) | High with indexed examples: provider can filter/rank before returning context | Implemented internal metadata plus configured Kujo RAG HTTP adapter |
| RAG ingestion (`connectors → native HTTP → MIME parser → chunks`) | High when source actually has selectable examples | Implemented weighted Markdown Accept, MIME-based staging and bounded native HTTP |
| RAG query (`rag_engine → retrieval → filters/ranking`) | High if chunks carry code-language tags | Implemented explicit equivalent-example groups; preserve existing corpus/namespace filters |
| MCP resources/tools (`adapters → JSON-RPC`, `mcp/resources`, `kujolang-mcp/catalog`) | Conditional: declared tool or resource template can choose an example variant | Declared arguments/agreed metadata; JSON/SSE transport unchanged |
| AI Chat web search (`tool-runtime → SearXNG/Ollama`) | Maybe: query terms/library names can improve ranking; locale does not select code | Keep current bounded query/domain/freshness projection; no code header |
| SearchBridge (`adapters/provider_runtime → transport`) | Most current recipients serve SEO/analytics data, not code examples | No change; preserve existing locale, metric, page and budget controls |
| Browser/Lens (`page.goto`, intercepted browser requests) | Low: content, layout and JavaScript fidelity are required | Preserve browser defaults and natural locale; no global Markdown |
| AI/provider APIs (AI SDK, AI Chat direct, Dispatch bridge, provider packages) | No universal retrieval benefit: returns model output/native API data | No change; express code-generation intent in existing task instructions |
| Ability gateway/CMS/API clients | API-dependent: only docs-specific operations could select examples | Declared structured input and server-owned validation |
| Git/package/registry/downloads (Kennel, runtime install, Source) | No: content bytes or package metadata are the artifact | No change; preserve hashes, request signing and exact responses |
| Telemetry, OAuth, webhooks, commerce, email, mobile notifications | No: recipients do not select coding examples | No code signal; preserve existing protocols |
| Static site search/index/build link checks | Conditional structured lookup; visual/link checks need HTML | Use index filters; do not silently change build validation representations |

AI Chat's HTML extractor already drops scripts/styles/hidden content but retains
visible navigation and multi-language code tabs; it also collapses horizontal
whitespace. Direct Markdown preserves code formatting without HTML parsing.
Upstream Markdown can reduce transferred page chrome, while actual model-token
savings versus the existing extracted text can be smaller or even negative.
The new fixture proves compressed Markdown/code fences reach the tool unchanged,
HTML/plain fallback remains accepted, and one call returns one response. It does
not prove any live server supports programming-language selection.

Other existing bounds remain useful: AI Chat result-byte/context budgets; RAG
`top_k`; SearchBridge rows/pages/calls/output limits; MCP catalog limits. None
requires injecting extra preference prose into every model prompt.

## 9. Compatibility Risks

- **Caching/CDNs:** negotiated variants need selecting fields in `Vary` and
  application cache keys. Query variants must survive CDN normalization. Do not
  cache Rust as the unqualified document; response validators should track the
  representation. Bound identifiers and supported variants to avoid unbounded
  fragmentation. AI Chat Page Reader currently has no shared content cache.
- **Privacy:** code language is low sensitivity but may reveal project/toolchain
  facts when sprayed to unrelated hosts. Send only the normalized value to opted-in
  recipients, never source paths, repository names, or configuration contents.
- **Redirects:** destination support and authorization must be checked per hop.
  AI Chat forwards safe standard `Accept`; this change forwards no private code
  hint. A future custom adapter must not forward hints across origins blindly.
- **Strict APIs/signatures:** unknown body fields can fail schema validation;
  header/query mutations can invalidate signatures. Project before signing through
  the provider adapter. Never overload protected authentication/content headers.
- **Browser/CORS:** custom browser headers can trigger preflights; Markdown can
  destroy navigation/QA semantics. Keep this feature on retrieval routes.
- **MCP:** `_meta` is an extensibility container, not evidence of semantic support.
  Honor version/capability/schema rules, retain JSON/SSE transport types, and do
  not conflate generic `language` parameters with programming language.
- **Task continuity:** target agent defaults must not replace explicit task intent.
  Handoff propagation is tested. External session restore/harness persistence
  must re-supply the task contract; no new chat persistence setting is claimed.
- **Safety of content:** Markdown/code remains untrusted. Selection must not strip
  relevant warnings, security limitations, or citations merely to meet a budget.
- **Fallback:** unsupported programming-language destinations retain the old request.
  Page Reader offers Markdown/HTML/plain in one request; 406 remains a bounded
  upstream error, with no retry/probe or hidden additional network cost.

## 10. Changes Made

| Repository | Files changed | Before | After | Tests added |
| --- | --- | --- | --- | --- |
| agents-sdk | `src/agents/core_types.kujo`, `src/agents/runner.kujo` | Request metadata did not reach runner-created retrieval/tool contexts | One optional normalized code-language value reaches retrieval, tools and handoffs; provider options unchanged | `tests/retrieval_preferences_tests.kujo`: five offline cases covering precedence/validation, full runner plus Dispatch/MCP seams, unsupported tools, handoffs and absence |
| agents-sdk | `README.md`, `docs/RETRIEVAL_PREFERENCES.md`, this audit | No documented shared retrieval preference | Contract, nonstandard transport status, examples, limits and ecosystem map | Documentation reviewed against source and contract tests |
| ai-chat | `lib/page-fetch.js`, `lib/tool-runtime.js` | Page reader requested/accepted HTML/plain only | Requests weighted Markdown/HTML/plain; preserves Markdown source as bounded untrusted text | Two additional tests in `tests/page-fetch.test.js`; existing nine page-reader tests retained |
| ai-chat | `README.md`, `docs/PAGE_READER_NEGOTIATION.md` | No Markdown negotiation guide | Explicit behavior, single-request fallback, transport exclusions and limits | Documentation reviewed against local HTTP fixture tests |

The initial audit modified two repositories; the authorized follow-up modifies four total: agents-sdk, rag, ai-chat, and dispatch. The rollout record lists all follow-up commits. Pre-existing AI Chat browser-containment
edits and Agents SDK maintenance-agent files were present at entry and are not
part of this change. The workspace-root audit copy is delivered outside the
unrelated parent repository, with its canonical version committed in Agents SDK.

Verification receipts are recorded at the end of this report.

## 11. No-Change Decisions

AI SDK owns inference, so making it the common code-header source would be an
architectural error. Dispatch now uses its persisted task input and dictionary hooks for the explicit RAG plugin. Other built-in local source tools remain unchanged. SearchBridge `language` is an existing natural-language
SEO/locale control. Workcell's caller context rejects unknown fields and is for
correlation, not retrieval. Scout/PackWrite language facts do not establish task
intent. MCP resources already returning Markdown do not need a Markdown HTTP
`Accept` header. Lens/SiteProbe require page fidelity. Provider packages, package
registries, authenticated APIs, telemetry and arbitrary GitHub traffic gain
nothing from a speculative code-language header. Alternate worktrees and generated
site/runtime copies should inherit future reviewed changes from their canonical
repositories, not receive duplicated implementations here.

## 12. Recommended Kujo Contract

Implemented internal representation:

```json
{
  "metadata": {
    "retrieval_preferences": {
      "programming_language": "rust"
    }
  }
}
```

`AgentRunRequest.metadata` overrides `agent.metadata`; defaults are only used if
the request has no `retrieval_preferences` namespace. Empty/invalid explicit input
suppresses the default. Normalization lowercases/trims and accepts extensible
`[a-z][a-z0-9_-]*` identifiers up to 64 characters; `c++ → cpp`, `c# → csharp`.
Unknown fields are omitted. No natural locale, runtime version, file detection,
HTTP header policy, or model preference is smuggled into this small contract.

```text
Task/harness explicit selection (or reviewed agent default)
  --> runner resolves once
    --> RetrievalQuery.metadata.retrieval_preferences
    --> ToolExecutionContext.metadata.retrieval_preferences
    --> child AgentRunRequest.metadata.retrieval_preferences
  --> adapter checks configured/schema-advertised destination support
    --> documented parameter OR agreed MCP metadata
    --> recipient selects matching examples + useful general guidance
  --> bounded result with honest provenance
```

The latter recipient-selection step is an adapter obligation, demonstrated by
fixtures and not asserted for arbitrary remote services. The proposed private MCP
mapping is `params._meta["ai.kujolang/retrieval_preferences"]`; an argument declared
by the server schema is preferable when available. No Kujo-specific HTTP header
is introduced. `Accept-Language` remains natural language. `Accept: text/markdown`
is used by AI Chat's static Page Reader and RAG's HTTP documentation connector, with HTML/plain alternatives.

The completed RAG integration demonstrates reduced response bytes and model-input content, retained guidance/citations, and isolated cache variants. Framework/version dimensions and external adapters remain deferred until their own corpus semantics and recipient support are established.

### Initial audit verification and provenance receipts

For the completed P0–P2 follow-up, see [the rollout verification](RETRIEVAL_PREFERENCES_ROLLOUT.md). The receipts below describe the earlier audit milestone.

Initial inventory revisions: `agents-sdk 9c8763d`, `ai-chat 33c3745`, `ai-sdk 71bad14`, `dispatch 6fc6fed`, `kujo de69289`, `mcp 20f1c83`, `rag 2005da7`, `searchbridge 88aad1c`.

- Agents SDK feature commit: `1e1d6ab`. All 27 tracked contract suites passed
  in an isolated worktree after copying the existing pinned Ability installation.
  The five new preference cases passed, including handoff and no-signal cases.
  After restoring the original local fixture outputs to the isolated setup,
  `kujo test` passed 27/27 fixtures; no expected-output source was changed.
- AI Chat feature commit: `e16b597`. Isolated Node 22.17.0 suite: 344 tests,
  343 passed, zero failures, one Linux-only platform skip on macOS. The earlier
  shared-workspace run passed 343/343. The independent Page Reader suite passed
  11/11; tool-activity/weekly-audit unit checks passed 11/11.
- Offline browser smoke passed health, provider, state, and fixture chat checks
  against a disposable database on loopback port 19473. No live provider key was
  required. Provider benchmarks/database backup/vacuum were not run: this change
  has no live model or durable database behavior to validate.
- AI SDK unchanged-boundary regression check: `kujo test-run
  tests/sdk_contract_tests.kujo -v`, 31/31 passed. Dispatch unchanged bridge
  contract check: `DISPATCH_OFFLINE_FIXTURE=true kujo test-run
  tests/sdk_adapter_tests.kujo -v`, 10/10 passed. Module-exports and offline example
  smoke commands also passed in Agents SDK.
- Runtime: Kujo 1.2.3 and Node 22.17.0. An initial npm run selected an incompatible
  global Node and was stopped; its native-module failures are not reported as
  product regressions. The isolated worktree initially lacked Ability; its
  setup-only failures were resolved using the existing pinned dependency and
  original fixture outputs, with no source fixture refresh.
- The full gate in the original shared Agents SDK checkout encountered an
  untracked maintenance-agent test with two failures plus its snapshot failure.
  The same two behavioral failures reproduce on unchanged baseline `9c8763d`.
  Those files belong to other work and were not modified or committed here.
- The weekly runtime audit was generated as required by the AI Chat workflow.
  It reports a historical retry-rate threshold breach in existing runtime data;
  this is not a feature regression or a new capture-worthy diagnosis. Runtime
  reports were not committed.
- Other work continued in AI Chat during the audit (browser containment commits
  and later admission/stream changes). This task committed only its own reviewed
  files; isolated verification excludes the later uncommitted changes.
- Local detailed logs: `/tmp/kujo-negotiation-agents-clean-final.log`,
  `/tmp/kujo-negotiation-chat-clean.log`, `/tmp/kujo-negotiation-chat-smoke.log`,
  `/tmp/kujo-negotiation-ai-sdk-contract.log`,
  `/tmp/kujo-negotiation-dispatch-contract.log`, and
  `/tmp/kujo-negotiation-maintenance-baseline.log`. These are local receipts,
  not permanent public artifacts; test commands and outcomes are retained here.
