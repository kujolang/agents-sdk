# Retrieval preferences: completed P0–P2 rollout

Verified 2026-09-06. Scope: four repositories. Branch in each repository: `codex/retrieval-preferences-complete`. All four implementation branches are now merged into `origin/main` and the local main checkouts. AI Chat was restarted through its existing launchd service on port 4174 and its new preference UI is verified. A persistent RAG endpoint/corpus has not been configured; deployment target selection remains pending. Unrelated shared-checkout work and the separate AI Chat soak were preserved.

## Repository and implementation checklist

| Repository | Completed work | Implementation commits |
| --- | --- | --- |
| [agents-sdk](https://github.com/kujolang/agents-sdk/tree/codex/retrieval-preferences-complete) | Single-call retrieval normalization; explicit RAG HTTP adapter; live handoff example | `a66ae54`, `e776000`, `4da0f6b` |
| [rag](https://github.com/kujolang/rag/tree/codex/retrieval-preferences-complete) | Equivalent-example grouping, upstream selection, cache variants, MIME-aware ingestion, measured pilot | `f00f68b`, `9092ddd`, `ef0d640` |
| [ai-chat](https://github.com/kujolang/ai-chat/tree/codex/retrieval-preferences-complete) | Persisted code-example selector, explicit request override/clear, configured documentation tool | `407ed2e` |
| [dispatch](https://github.com/kujolang/dispatch/tree/codex/retrieval-preferences-complete) | Workflow/run/step preferences, disk persistence, retry/resume, opt-in RAG plugin | `83eea7d` |

- [x] P0: normalize the original provider response without a second request; preserve errors, explicit empty results, legacy wrappers, documents and real citations.
- [x] P1: ship a working RAG `/query` recipient and actual Python/JavaScript API examples with explicit equivalence groups.
- [x] P1: select examples upstream while retaining shared prose, warnings, links, setup code and original citation ranges.
- [x] P1: isolate normalized preference cache variants; preserve unsupported-language, unannotated-corpus and no-match behavior.
- [x] P1: exercise actual HTTP retrieval through Agents SDK, including absent/explicit preferences and task preference across a handoff with a conflicting target default.
- [x] P1: measure response bytes, exact tokenizer counts, actual model-input content, latency, request counts and retained evidence.
- [x] P2: persist AI Chat preferences, expose an editable language control and connect its real tool loop to RAG.
- [x] P2: carry Dispatch workflow defaults, run overrides and explicit step clears through retries, approval pause, disk reload and resume.
- [x] P2: negotiate Markdown with HTML/plain fallback and choose ingestion parsers from final response MIME type.
- [x] P2: assess additional dimensions and adapters. Framework/library-version selection and third-party negotiation are deferred because this corpus and those recipients do not establish compatible semantics. No extra repository is required for this decision.

## Contract and enablement

Task-owned `metadata.retrieval_preferences.programming_language` is normalized as an optional bounded identifier. Explicit empty/invalid input clears a default. It is not inferred from the repository, model or runtime. `Accept-Language` and inference-provider options remain unchanged.

RAG's opt-in `KUJO_RAG_MARKDOWN_EXAMPLES_ENABLED=true` preserves annotated Markdown on ingestion; reingest after enabling it. `retrieval-example=GROUP` identifies interchangeable fenced examples. Only alternatives in a group containing the requested language may be removed. Original source line ranges can span omitted alternatives. A complete tagged fence can exceed the target chunk size, bounded by the existing document byte limit.

AI Chat uses `AI_CHAT_RAG_URL`, optional namespace/token, and `AI_CHAT_RAG_SUPPORTS_PREFERENCES=1`. Dispatch uses the corresponding `DISPATCH_RAG_*` settings with `--plugin rag`. The Agents SDK adapter uses explicit `supports_preferences` configuration. No adapter probes for capability or retries to discover support. Endpoint credentials belong to host configuration.

See each repository's retrieval-preferences documentation for commands and contract details. All endpoints used for verification were local disposable services; model callbacks were fixtures.

## Measured results

Same question, same indexed document, `cl100k_base`, tiktoken 0.14.0:

| Measurement | All examples | Python | JavaScript |
| --- | ---: | ---: | ---: |
| HTTP response bytes, first uncached lookup | 4,729 | 4,113 | 4,074 |
| Retrieved text bytes | 2,078 | 1,487 | 1,466 |
| Retrieved text tokens | 476 | 332 | 323 |
| Actual Agents SDK model-input content tokens | 509 | 365 | 356 |
| Actual AI Chat tool-message content tokens | 589 | 422 | 413 |
| First uncached lookup latency, milliseconds | 726.431 | 721.729 | 778.132 |
| Requests per lookup | 1 | 1 | 1 |

Actual Agents SDK model-input content is reduced by 28.3% for Python and 30.1% for JavaScript. Counts exclude provider-specific framing. The handoff makes one target retrieval with Python overriding the target's JavaScript default; its differently worded messages are measured separately. Dispatch completes its documentation step in one attempt, returning 332 content tokens.

The baseline is the new opt-in corpus with all examples preserved. It is not the legacy parser, which strips fenced code. Latency varies on this shared host; this does not establish a latency improvement. Retained guidance, matching examples and citation provenance are verified. No paid-model answer-quality improvement is claimed.

Portable receipts and replay scripts are committed in RAG:

- [HTTP and host pilot receipts](https://github.com/kujolang/rag/blob/codex/retrieval-preferences-complete/docs/audits/retrieval-preferences-pilot.json)
- [MIME ingestion receipts](https://github.com/kujolang/rag/blob/codex/retrieval-preferences-complete/docs/audits/http-document-ingestion.json)
- `scripts/verify_retrieval_preferences.py` and `scripts/verify_http_document_ingestion.py`

## Verification

Runtime: Kujo 1.2.3, Node 22.17.0. Installed pinned dependencies and disposable databases/indexes were used in isolated worktrees.

| Repository | Verification result |
| --- | --- |
| agents-sdk | Full no-network gate: 30 checks, zero failures. Module/export and example smoke passed. Three single-call regressions fail pristine baseline and pass the fix. Final live pilot verifies the later handoff-example change. |
| rag | Full suite: 72/73 passed on the initial loaded run; the sole canary failure was its absolute latency gate. The unchanged canary then passed in isolation with `KUJO_BIN` configured. Opt-in malformed/group/fence and multi-chunk tests pass after the final selection edit. Unit/integration, OpenAPI parity, config-schema parity, existing connector tests, five MIME cases and the final all-host HTTP pilot pass. |
| ai-chat | Final serial suite: 377 tests, 376 passed, zero failed, one platform skip. Real browser selection/save/reload/clear and offline browser smoke passed. Live SSE/tool loop verifies saved default, explicit task override, explicit clear and one RAG request per turn. |
| dispatch | All 24 contract shards (101 source tests), focused integrations, command/version smoke, and release workload passed. The final workload used the existing AI SDK path explicitly: 3/3 runs. Three additional preference/persistence/retry/resume tests pass and are included in the release gate. |

Earlier AI Chat parallel execution exposed an unrelated browser replay timing failure; the serial full suite passes. An accidental preference field in usage aggregation was corrected before that final suite. Weekly-audit execution on the test-generated audit log correctly flags intentionally cancelled `local_file_read` calls; this synthetic history is not production reliability evidence. An empty isolated smoke audit is also not counted as tool coverage.

Detailed local logs: `/tmp/kujo-retrieval-rollout/agents-final-gate.log`, `rag-full-tests.log`, `rag-canary-retry.log`, `chat-final-tests.log`, `chat-browser.log`, `dispatch-gate.log`, `dispatch-release-evidence.log`, `dispatch-preferences.log`, and `final-pilot.log`. Portable measured receipts above survive removal of temporary worktrees.

## Review and rollout

The requested implementation checklist is complete. The four branches were merged on 2026-09-06. AI Chat merge `feaf11a` preserves the newer execution-resume work; the combined suite passed 383 tests with one platform skip, and the all-host HTTP pilot passed again. Its live database was backed up before the existing launchd service was restarted. Health and the deployed selector/normalization assets passed checks. Agents SDK and Dispatch are library/CLI repositories with no separate persistent service to restart. RAG still needs the intended service target and corpus before feature enablement and reingestion.

The earlier empty-retrieval SignalBox finding is resolved by `a66ae54`; no new unresolved finding warrants a capture. Other dimensions remain explicit product decisions, not unfinished implementation requirements.

### Merge/deployment verification and outstanding environment decisions

- Main implementation heads: Agents SDK `2677c18` (followed by this status record), RAG `ef0d640`, AI Chat `feaf11a`, Dispatch `83eea7d`. Shared checkout updates used fast-forward merges, without stashing or deleting unrelated work.
- AI Chat live service: `com.kujo.ai-chat`, loopback port 4174. New UI is deployed; `documentation_query` remains unavailable until `AI_CHAT_RAG_URL` is configured. Existing credentials and settings were retained. Backup: `ai-chat/data/backups/retrieval-rollout/ai-chat-2026-09-06T19-59-37-453Z.db` (private ignored runtime data).
- RAG hosted run [34056498353](https://github.com/kujolang/rag/actions/runs/34056498353) passed all 73 tests and the runtime/platform/security-boundary jobs, but release-gates stopped at the unchanged threat-model cadence check: `review_not_overdue=false`. The plan and checker are byte-identical to baseline `2005da7`; no review timestamp was advanced. Existing SignalBox Capture `cap_7e639398-80e8-43a4-b1b1-7fa5bc30ab12` already records this blocker; duplicate skipped. A current evidence-backed review is required before claiming release readiness.
- No permanent RAG production service was discovered. Its Cloudflare staging workflow is explicitly a temporary security test, not a hosting deployment. The intended endpoint and corpus were requested from the user; no cloud resources or arbitrary corpus were selected.
