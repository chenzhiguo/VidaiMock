---
title: Providers Overview
---

# Providers Overview

No configuration needed — these endpoints work the moment the binary starts.
Every response is rendered from a bundled Tera template that you can override
(see [Overriding bundled defaults](../configuration/overriding.md)).

| Provider | Endpoint | Streaming |
|---|---|---|
| **OpenAI Chat** | `POST /v1/chat/completions` | ✅ |
| **OpenAI Responses** | `POST /v1/responses` | ✅ (typed SSE events) |
| **OpenAI Embeddings** | `POST /v1/embeddings` | — |
| **OpenAI Images** | `POST /v1/images/generations` | — |
| **OpenAI Moderations** | `POST /v1/moderations` | — |
| **Anthropic** | `POST /v1/messages` | ✅ (all 7 SSE event types) |
| **Gemini Generate** | `POST /v1beta/models/*:generateContent` | ✅ (text deltas + terminal `finishReason: STOP` chunk, no `[DONE]`) |
| **Gemini Embeddings** | `POST /v1beta/models/*:embedContent` | — |
| **Gemini Token Count** | `POST /v1beta/models/*:countTokens` | — |
| **Gemini Models** | `GET /v1beta/models` | — |
| **Gemini OpenAI Shim** | `/v1beta/openai/*` | ✅ |
| **Azure OpenAI** | `POST /openai/deployments/*` | ✅ |
| **Bedrock** | `POST /model/*/invoke` | ✅ |
| **Vertex AI** | `POST /v1/projects/*/...:generateContent` | ✅ |
| **Cohere, Mistral, Groq** | OpenAI-compatible | ✅ |
| **Error Simulator** | `ANY /error/{code}` | — |

## Beyond the basics

- **Tool calling** — OpenAI `tool_calls`, Anthropic `tool_use`, Gemini
  `functionCall`. The response echoes the caller's declared tool name.
  See [Tool calling](../tool-calling.md).
- **Agentic loop termination** — when a tool result is already in the
  request history, the mock switches to a plain-text answer instead of
  looping another tool call. See [Agentic testing](../agentic-testing.md).
- **Reasoning model tokens** — o-series models return
  `completion_tokens_details.reasoning_tokens`.
- **Gemini 2.5 fidelity** — `thoughtsTokenCount`, `promptTokensDetails`,
  `modelVersion`, `responseId`.
- **Anthropic cost fields** — `cache_creation`, `service_tier`,
  `inference_geo`, `stop_details`.

## Provider deep-dives

- [OpenAI](openai.md)
- [Anthropic](anthropic.md)
- [Gemini](gemini.md)
- [Other providers](others.md) — Azure, Bedrock, Vertex, Cohere/Mistral/Groq
