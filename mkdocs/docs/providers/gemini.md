---
title: Gemini
---

# Gemini

Gemini has the most distinct wire format of the three majors — three
separate response shapes (`generateContent`, `embedContent`, `countTokens`),
no `[DONE]` sentinel, and a terminal-only `finishReason`. VidaiMock matches
all of it, plus the OpenAI-compatible shim Google ships.

## generateContent — `POST /v1beta/models/{model}:generateContent`

```bash
curl http://localhost:8100/v1beta/models/gemini-2.5-flash:generateContent \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Hello"}]}]}'
```

The response carries Gemini 2.5 fidelity fields: `thoughtsTokenCount`,
`promptTokensDetails`, `modelVersion`, `responseId`. When `tools` are
declared it returns a `functionCall` part (echoing the caller's tool name);
when a prior `functionResponse` is in `contents` it returns plain text
instead — see [Agentic testing](../agentic-testing.md).

### Streaming — `:streamGenerateContent?alt=sse`

Critically, Gemini does **not** use an OpenAI-style `[DONE]` sentinel — the
stream simply ends. VidaiMock matches this:

- Intermediate chunks: text deltas, `finishReason: null`, **no**
  `usageMetadata`.
- Terminal chunk: `finishReason: "STOP"` **plus** `usageMetadata`.
- No `[DONE]` frame — emitting one would break the `google-genai` SDK.

```bash
curl -N "http://localhost:8100/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse" \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Count to 5"}]}]}'
```

Tool-mode streaming emits the `functionCall` as a single structured frame,
single-line JSON, no multi-line bleed.

## embedContent — `POST /v1beta/models/{model}:embedContent`

A different envelope from generateContent — `{ "embedding": { "values": [...] } }`:

```bash
curl http://localhost:8100/v1beta/models/gemini-embedding-001:embedContent \
  -H "Content-Type: application/json" \
  -d '{"content": {"parts": [{"text": "Hello"}]}}'
```

## countTokens — `POST /v1beta/models/{model}:countTokens`

```bash
curl http://localhost:8100/v1beta/models/gemini-2.5-flash:countTokens \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"role": "user", "parts": [{"text": "Hello"}]}]}'
```

## Model listing — `GET /v1beta/models`

```bash
curl http://localhost:8100/v1beta/models
```

## OpenAI-compatible shim — `/v1beta/openai/*`

Google ships an OpenAI-shaped shim. VidaiMock serves it too:

```bash
curl http://localhost:8100/v1beta/openai/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-embedding-001", "input": "Hello"}'

curl http://localhost:8100/v1beta/openai/models
```

## Error envelopes

Chaos/override errors render Gemini's gRPC-style
`{"error":{"code","message","status"}}` shape, with `status` mapped per
HTTP code (`INVALID_ARGUMENT`, `UNAUTHENTICATED`, `RESOURCE_EXHAUSTED`,
`INTERNAL`, …).
