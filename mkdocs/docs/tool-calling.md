---
title: Tool Calling
---

# Tool Calling

When a request declares `tools`, VidaiMock returns a correctly-shaped
tool-call response for that provider — **echoing the caller's declared tool
name**, not a hard-coded demo tool. This means SDK tests that assert "the
tool I registered was invoked" pass against the mock.

## Per-provider shapes

| Provider | Request field | Response shape |
|---|---|---|
| OpenAI | `tools[].function.name` | `choices[].message.tool_calls[]`, `finish_reason: "tool_calls"` |
| Anthropic | `tools[].name` | `content[].type == "tool_use"`, `stop_reason: "tool_use"` |
| Gemini | `tools[].functionDeclarations[].name` | `candidates[].content.parts[].functionCall`, `finishMessage` set |

Arguments default to an empty object (`{}` / `args: {}` / `input: {}`).
Tests assert on the tool *name* and shape, not synthesised argument values;
if you need specific arguments, override the template (see below).

## OpenAI example

```bash
curl http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o",
       "messages": [{"role": "user", "content": "Weather?"}],
       "tools": [{"type": "function",
                  "function": {"name": "get_weather", "parameters": {}}}]}'
```

Response:

```json
{"choices":[{"message":{"role":"assistant","content":null,
  "tool_calls":[{"id":"call_mock_...","type":"function",
    "function":{"name":"get_weather","arguments":"{}"}}]},
  "finish_reason":"tool_calls"}]}
```

If you had declared `broken_tool` instead, the response would name
`broken_tool` — the mock does not substitute its own tool.

## Anthropic example

```bash
curl http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude", "max_tokens": 200,
       "messages": [{"role": "user", "content": "Weather?"}],
       "tools": [{"name": "get_weather", "description": "x",
                  "input_schema": {"type": "object"}}]}'
```

Returns a `tool_use` content block with `caller.type: "direct"`.

## Gemini example

```bash
curl http://localhost:8100/v1beta/models/gemini-2.5-flash:generateContent \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Weather?"}]}],
       "tools": [{"functionDeclarations": [{"name": "get_weather",
                  "parameters": {"type": "OBJECT"}}]}]}'
```

## Streaming tool calls

A streaming request that returns a tool call emits the call as a **single
structured frame** — not word-chunked text. OpenAI streams a single
`tool_calls` delta; Anthropic streams a `tool_use` `content_block_start`
followed by `input_json_delta`; Gemini streams a single `functionCall`
frame. All single-line JSON, parseable by the real SDKs. See
[Streaming](streaming.md).

## Loop termination

The interesting part: a tool call alone is not enough — real agents loop.
When the request history *already contains a tool result*, VidaiMock stops
returning tool calls and answers in plain text, exactly like a real model.
This is what makes agentic testing work. See
[Agentic workflow testing](agentic-testing.md).

## Customising the tool response

The bundled templates pick the first declared tool with empty args. To
return specific arguments, a fixed tool, or multiple parallel tool calls,
override the provider's template — see
[Writing templates](configuration/templates.md). The bundled
`openai/tool_call.json.j2` is kept as a static-demo template you can point a
provider at if you want fixed `get_weather` behaviour.
