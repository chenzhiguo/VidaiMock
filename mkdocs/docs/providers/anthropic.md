---
title: Anthropic
---

# Anthropic

Anthropic's API is a single endpoint — `/v1/messages` — with a rich typed
streaming lifecycle. VidaiMock replicates the **complete** wire contract,
including the 2025+ cost-accounting fields and strict event ordering that the
official SDK asserts on.

## Messages — `POST /v1/messages`

The bundled `anthropic/message.json.j2` template branches on the request:

- **`tools` present** → `tool_use` content block, `stop_reason: "tool_use"`,
  with `caller.type` and the caller's declared tool name.
- **`tools` + prior `tool_result` in history** → text content,
  `stop_reason: "end_turn"` (see [Agentic testing](../agentic-testing.md)).
- **default** → text content, `stop_reason: "end_turn"`.

```bash
curl http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-haiku-4-5-20251001", "max_tokens": 200,
       "messages": [{"role": "user", "content": "Hi"}]}'
```

### Full usage shape

Every response carries the 2025+ accounting fields real Anthropic returns:

```json
"usage": {
  "input_tokens": 16,
  "cache_creation_input_tokens": 0,
  "cache_read_input_tokens": 0,
  "cache_creation": { "ephemeral_5m_input_tokens": 0, "ephemeral_1h_input_tokens": 0 },
  "output_tokens": 10,
  "service_tier": "standard",
  "inference_geo": "not_available"
}
```

plus a top-level `stop_details: null`.

## Request validation

A `/v1/messages` request missing a required field returns **HTTP 400** with
the real Anthropic error envelope and a per-field message:

```bash
curl http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude", "messages": [{"role": "user", "content": "Hi"}]}'
```

```json
{"type":"error","error":{"type":"invalid_request_error","message":"max_tokens: Field required"}}
```

This matches live Anthropic, so client code that catches
`anthropic.BadRequestError` can be tested in mock mode.

## Streaming — all 7 event types

`"stream": true` emits the complete Anthropic SSE lifecycle in strict order:

```
event: message_start
event: content_block_start
event: ping
event: content_block_delta   (one or more)
event: content_block_stop
event: message_delta          (final stop_reason + usage)
event: message_stop
```

Events are blank-line separated so SDK parsers attribute each `data:` to the
correct `event:`. Tool-mode streaming emits a `tool_use` content block with
`input_json_delta` deltas and `stop_reason: "tool_use"` in `message_delta`.

```bash
curl -N http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-haiku-4-5-20251001", "max_tokens": 200,
       "stream": true, "messages": [{"role": "user", "content": "Count to 5"}]}'
```

## Tool calling

```bash
curl http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-haiku-4-5-20251001", "max_tokens": 500,
       "messages": [{"role": "user", "content": "Weather in London?"}],
       "tools": [{"name": "get_weather", "description": "Get weather",
                  "input_schema": {"type": "object",
                  "properties": {"city": {"type": "string"}}}}]}'
```

## Error envelopes

Chaos/override errors render Anthropic's
`{"type":"error","error":{"type","message"}}` shape, with `error.type`
selected per status (`authentication_error`, `rate_limit_error`,
`overloaded_error`, `api_error`, …).
