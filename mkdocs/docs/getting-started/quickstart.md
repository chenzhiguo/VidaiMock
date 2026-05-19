---
title: Quickstart
---

# Quickstart

Start the server and exercise the main surfaces. **No API key is ever
required** — VidaiMock ignores `Authorization` on mock routes.

```bash
./vidaimock          # listens on http://localhost:8100 by default
```

## Chat completion

```bash
curl http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
```

## Tool calling

The bundled chat template auto-detects `tools` and returns a `tool_calls`
response echoing the **caller's** tool name (not a hard-coded one).

```bash
curl http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o", "messages": [{"role": "user", "content": "Weather?"}],
       "tools": [{"type": "function", "function": {"name": "get_weather", "parameters": {}}}]}'
```

## Reasoning models

Models matching `o1`/`o3`/`o4` return reasoning token accounting.

```bash
curl http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "o4-mini", "messages": [{"role": "user", "content": "2+2"}]}'
```

## OpenAI Responses API

```bash
# non-streaming
curl http://localhost:8100/v1/responses \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "input": "Say hello", "max_output_tokens": 50}'

# streaming — typed SSE events (response.output_text.delta, …)
curl -N http://localhost:8100/v1/responses \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o-mini", "input": "Say hello", "stream": true}'
```

## Streaming with usage

```bash
curl -N http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o", "stream": true,
       "stream_options": {"include_usage": true},
       "messages": [{"role": "user", "content": "Hi"}]}'
```

## Embeddings, images, moderations

```bash
curl http://localhost:8100/v1/embeddings -H "Content-Type: application/json" \
  -d '{"model": "text-embedding-3-small", "input": "Hello"}'

curl http://localhost:8100/v1/images/generations -H "Content-Type: application/json" \
  -d '{"model": "dall-e-2", "prompt": "a red circle", "n": 1}'

curl http://localhost:8100/v1/moderations -H "Content-Type: application/json" \
  -d '{"model": "omni-moderation-latest", "input": "Hello"}'
```

## Gemini

```bash
# generateContent
curl http://localhost:8100/v1beta/models/gemini-2.5-flash:generateContent \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Hello"}]}]}'

# embedContent / countTokens / model listing
curl http://localhost:8100/v1beta/models/gemini-embedding-001:embedContent \
  -H "Content-Type: application/json" -d '{"content": {"parts": [{"text": "Hello"}]}}'
curl http://localhost:8100/v1beta/models/gemini-2.5-flash:countTokens \
  -H "Content-Type: application/json" -d '{"contents": [{"role": "user", "parts": [{"text": "Hello"}]}]}'
curl http://localhost:8100/v1beta/models
```

## Anthropic

```bash
curl http://localhost:8100/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-haiku-4-5-20251001", "max_tokens": 200,
       "messages": [{"role": "user", "content": "Hi"}]}'
```

!!! note "Anthropic validates required fields"
    A `/v1/messages` request **without** `max_tokens` returns HTTP 400 with
    a real `invalid_request_error` envelope (`max_tokens: Field required`),
    matching live Anthropic.

## Error simulation

```bash
curl http://localhost:8100/error/400 -H "Content-Type: application/json" -d '{}'
curl http://localhost:8100/error/429 -H "Content-Type: application/json" -d '{}'

# Force any status on a real endpoint, keeping a parseable error body:
curl -H "X-Mock-Status: 503" http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
```

## Latency + chaos

```bash
# realistic mode adds TTFT + token pacing
./vidaimock --latency 500 --mode realistic

# probabilistic failure injection per request (returns provider-shaped 500 JSON)
curl -H "X-Vidai-Chaos-Drop: 100" http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
```

Next: explore [Providers](../providers/index.md),
[Agentic testing](../agentic-testing.md), or
[Chaos & error injection](../chaos-and-errors.md).
