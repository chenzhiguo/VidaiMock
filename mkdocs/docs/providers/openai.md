---
title: OpenAI
---

# OpenAI

VidaiMock implements the OpenAI surface area that real applications actually
exercise — chat completions, the newer Responses API, embeddings, image
generation, and moderations — with wire-shape fidelity validated byte-level
against captured production responses.

## Chat completions — `POST /v1/chat/completions`

The bundled `openai/chat.json.j2` template branches on the request:

- **`tools` present** → `tool_calls` response, `finish_reason: "tool_calls"`,
  echoing the caller's declared tool name with `{}` arguments.
- **`tools` + a prior tool result in history** → plain-text synthesis with
  `finish_reason: "stop"` (see [Agentic testing](../agentic-testing.md)).
- **`response_format` present** → structured JSON-string content.
- **o-series model** (`o1`/`o3`/`o4…`) → `completion_tokens_details.reasoning_tokens`.
- **default** → assistant text.

```bash
curl http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
```

### Streaming

`"stream": true` produces real token-by-token SSE. The terminal sequence
matches real OpenAI exactly: a final empty-delta chunk carrying
`finish_reason: "stop"`, then (when `stream_options.include_usage` is set)
a usage-only chunk, then `data: [DONE]`. Every event is blank-line
terminated per the SSE spec, so strict SDK parsers iterate it cleanly.

```bash
curl -N http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o", "stream": true,
       "stream_options": {"include_usage": true},
       "messages": [{"role": "user", "content": "Hi"}]}'
```

See [Streaming](../streaming.md) for the full framing contract.

## Responses API — `POST /v1/responses`

OpenAI's newer unified surface. Non-streaming returns the typed `output[]`
envelope; streaming emits the typed event lifecycle
(`response.created`, `response.output_text.delta`,
`response.completed`, …) rather than plain `data:` chunks.

```bash
# non-streaming
curl http://localhost:8100/v1/responses -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "input": "Say hello", "max_output_tokens": 50}'

# streaming — typed SSE events
curl -N http://localhost:8100/v1/responses -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "input": "Say hello", "stream": true}'
```

## Embeddings — `POST /v1/embeddings`

```bash
curl http://localhost:8100/v1/embeddings -H "Content-Type: application/json" \
  -d '{"model": "text-embedding-3-small", "input": "Hello"}'
```

Returns the standard `data[].embedding` shape with float vectors.

## Images — `POST /v1/images/generations`

```bash
curl http://localhost:8100/v1/images/generations -H "Content-Type: application/json" \
  -d '{"model": "dall-e-2", "prompt": "a red circle", "n": 1}'
```

## Moderations — `POST /v1/moderations`

```bash
curl http://localhost:8100/v1/moderations -H "Content-Type: application/json" \
  -d '{"model": "omni-moderation-latest", "input": "Hello"}'
```

## Error envelopes

Any chaos/override that yields a 4xx/5xx renders the OpenAI-shaped
`{"error": {"message", "type", "param", "code"}}` envelope, with `type`
selected per status (`invalid_request_error`, `rate_limit_exceeded`,
`server_error`, …). See [Chaos & error injection](../chaos-and-errors.md).
