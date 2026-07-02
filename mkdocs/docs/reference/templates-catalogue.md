---
title: Templates & Configs Catalogue
---

# Templates & Configs Catalogue

VidaiMock ships a rich library of templates and provider configs. This page
catalogues **exactly what's in the box** so you can find a working starting
point instead of writing from scratch. Everything here is bundled in every
release archive and embedded in the binary.

Two locations:

- **`config/`** — the *active* bundled providers + templates that serve
  requests out of the box.
- **`examples/`** — *reference* templates and provider configs demonstrating
  techniques. Copy them into your `--config-dir` to use them.

## Bundled providers (`config/providers/`)

These are live by default. Override any by dropping a same-named file in
`--config-dir` ([Overriding](../configuration/overriding.md)).

| Provider YAML | Serves |
|---|---|
| `openai.yaml` | `/v1/chat/completions` — smart-branching chat (tools, reasoning, structured output, loop termination) |
| `openai_responses.yaml` | `/v1/responses` — Responses API, typed SSE streaming |
| `openai_images.yaml` | `/v1/images/generations` |
| `openai_moderations.yaml` | `/v1/moderations` |
| `openai_tools_mock.yaml` | Static-demo tool-call provider |
| `openai_compatible.yaml` | OpenAI-compatible catch-all (Cohere/Mistral/Groq style) |
| `embeddings.yaml` | `/v1/embeddings` |
| `anthropic.yaml` | `/v1/messages` — tool_use branching, 7-event streaming, `max_tokens` validation |
| `gemini.yaml` | `:generateContent` / `:streamGenerateContent` |
| `gemini_embed.yaml` | `:embedContent` |
| `gemini_count_tokens.yaml` | `:countTokens` |
| `azure.yaml` | `/openai/deployments/*` |
| `bedrock.yaml` | `/model/*/invoke` |
| `bedrock_converse.yaml` | `/model/*/converse` |
| `vertex.yaml` | Vertex AI generateContent |
| `cohere.yaml`, `mistral.yaml`, `groq.yaml` | Provider-named OpenAI-compatible routes |
| `openrouter.yaml` | OpenRouter-style chat |
| `error_simulator.yaml` | `/error/{code}` provider-agnostic error endpoint |
| `blackbox-demo.yaml` | Minimal demo provider for testing the override mechanism |

## Bundled templates (`config/templates/`)

Grouped by provider. These are the rendering bodies the providers above
reference.

### OpenAI

| Template | Role |
|---|---|
| `openai/chat.json.j2` | Multi-branch chat (tools / reasoning / structured / loop termination) |
| `openai/chat_completion.json.j2` | Simpler chat completion shape |
| `openai/responses.json.j2` | Responses API envelope |
| `openai/responses_stream/{start,delta,stop}.j2` | Typed Responses API SSE lifecycle |
| `openai/stream_chunk.json.j2` | Chat streaming delta |
| `openai/stream_stop.sse.j2` | Terminal finish/usage/`[DONE]` sequence |
| `openai/embeddings.json.j2` | Embeddings list |
| `openai/images_generations.json.j2` | Image generation |
| `openai/moderations.json.j2` | Moderation results |
| `openai/tool_call.json.j2` | Static-demo tool call (fixed `get_weather`) |
| `openai/error.json.j2` | OpenAI-shaped error envelope |

### Anthropic

| Template | Role |
|---|---|
| `anthropic/message.json.j2` | Messages response (text / tool_use branching) |
| `anthropic/stream/{start,delta,stop}.json.j2` | 7-event streaming lifecycle |
| `anthropic/error.json.j2` | Anthropic-shaped error envelope |

### Gemini

| Template | Role |
|---|---|
| `gemini/response.json.j2` | generateContent (text / functionCall / loop termination) |
| `gemini/generate.json.j2` | Alternate generate shape |
| `gemini/stream_chunk.json.j2` | Streaming intermediate chunk |
| `gemini/stream_final.json.j2` | Terminal chunk (`finishReason` + `usageMetadata`) |
| `gemini/embed_content.json.j2` | embedContent envelope |
| `gemini/count_tokens.json.j2` | countTokens envelope |
| `gemini/error.json.j2` | Gemini gRPC-style error envelope |

### Others

| Template | Role |
|---|---|
| `bedrock/invoke.json.j2`, `bedrock/converse.json.j2` | Bedrock shapes |
| `vertex/response.json.j2` | Vertex AI generateContent |
| `cohere/*.json.j2` | Cohere chat + streaming lifecycle |
| `groq/chat.json.j2` | Groq chat |
| `openrouter/chat.json.j2` | OpenRouter chat |
| `error/generic.json.j2` | Generic error body for `/error/{code}` |

## Example templates (`examples/templates/`)

Reference recipes demonstrating techniques. Each is self-contained — copy
into `--config-dir/templates/` and point a provider at it.

| Example | Technique demonstrated |
|---|---|
| `01_simple_echo.json.j2` | Reflecting request data back |
| `02_logic_control.json.j2` | Conditional branching on message content |
| `03_reflection.json.j2` | Echoing structured request fields |
| `04_random_data_loop.json.j2` | `{% for %}` loops + `random_int` for bulk data |
| `05_tool_calling.json.j2` | Tool-call response shape |
| `06_rate_limit_error.json.j2` | 429 rate-limit error body |
| `07_openai_stream_chunk.json.j2` | OpenAI streaming chunk |
| `08_anthropic_message.json.j2` | Anthropic message shape |
| `09_gemini_candidates.json.j2` | Gemini candidates shape |
| `10_rag_citations.json.j2` | RAG response with citations |
| `11_security_fuzz.json.j2` | Bulk fuzz payload for buffer/UI stress |
| `12_image_gen.json.j2` | Image generation response |
| `13_maintenance.json.j2` | "Model overloaded" maintenance error |
| `14_complex_nested.json.j2` | Deeply nested JSON structure |
| `15_html_page.html.j2` | Non-JSON: full HTML page |
| `16_data.csv.j2` | Non-JSON: CSV (RAG ingestion tests) |
| `17_math_solver.json.j2` | Computed/derived response content |
| `18_soap_response.xml.j2` | Non-JSON: SOAP/XML (legacy enterprise mocks) |
| `19_graphql_response.json.j2` | GraphQL-shaped response |
| `20_empty.txt.j2` | Empty/edge-case body |

## Example providers (`examples/providers/`)

| Example | Wires up |
|---|---|
| `01_echo.yaml` | The echo template at a custom path |
| `05_tools.yaml` | A tool-calling provider |
| `07_streaming.yaml` | A streaming provider with a lifecycle |
| `10_rag.yaml` | A RAG-with-citations provider |

## Using an example

```bash
mkdir -p my-config/templates my-config/providers
cp examples/templates/16_data.csv.j2 my-config/templates/
cat > my-config/providers/csv.yaml <<'EOF'
name: "csv-export"
matcher: "^/export/data$"
response_template: "16_data.csv.j2"
EOF

./vidaimock --config-dir ./my-config --content-type text/csv &
curl http://localhost:8100/export/data
```

See [Overriding bundled defaults](../configuration/overriding.md) and
[Writing templates](../configuration/templates.md) for the full mechanics.
