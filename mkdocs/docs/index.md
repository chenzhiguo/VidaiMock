---
title: VidaiMock
---

# VidaiMock

**Batteries-included mock server for LLM APIs and agents.** Works instantly
with OpenAI, Anthropic, Gemini, Bedrock, and more. Run ADK / LangGraph /
LangChain agentic workflows against it without a single live-provider token.
Zero config required.

VidaiMock is a single ~7 MB Rust binary that emulates the **exact wire format**
of production AI providers — including streaming physics, typed SSE events,
tool-call shapes, and error envelopes — so SDK and integration tests pass
against it the same way they would against the real APIs, deterministically
and for free.

!!! tip "Built for the Vidai AI Control Plane"
    VidaiMock is the simulation engine we use to validate the
    [Vidai AI Control Plane](https://vidai.uk), our high-density,
    enterprise-grade control plane for LLM infrastructure. The same logic
    that simulates network jitter, latency, and failure modes here is used
    in production to keep the Vidai Control Plane resilient.

## 30-second demo

```bash
# Download + unpack (macOS Apple Silicon shown — see Installation for others)
curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-macos-arm64.tar.gz
tar -xzf vidaimock-macos-arm64.tar.gz && cd vidaimock

# Run
./vidaimock

# In another terminal — note: no API key needed
curl -N http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "stream": true, "messages": [{"role": "user", "content": "Hello!"}]}'
```

Tokens stream back one by one — that is realistic LLM simulation, not a
static download.

## Why VidaiMock

| Capability | Traditional mocks | VidaiMock |
|---|---|---|
| Streaming | Chunked / static download | Real-time token simulation with TTFT + jitter |
| Provider support | Manual per-endpoint config | Batteries-included (OpenAI, Anthropic, Gemini, …) |
| Wire accuracy | Best-effort JSON | Byte-level match, regression-tested against real captures |
| Tool calling | Static canned response | Auto-detects tools, echoes caller's tool name |
| Agentic loops | Infinite-loops or breaks tool tests | Terminates correctly like a real provider |
| Error testing | Hard-coded status | Provider-shaped error envelopes, four injection modes |
| Extensibility | Webhooks / static JSON | Dynamic Tera templates, override anything |
| Runtime | Node/JVM overhead | Microsecond-native Rust, 50,000+ RPS |

## What's covered

- **OpenAI** — chat completions, Responses API (typed SSE), embeddings,
  images, moderations
- **Anthropic** — `/v1/messages` with full 7-event streaming lifecycle and
  `tool_use`
- **Gemini** — generate / embed / countTokens / models listing, plus the
  OpenAI-compatible shim
- **Azure OpenAI, Bedrock, Vertex, Cohere, Mistral, Groq** — out of the box
- **Error simulator** — any HTTP status, provider-shaped body

Read the [Providers overview](providers/index.md) for the full endpoint table.

## Where to go next

<div class="grid cards" markdown>

-   :material-download: **[Install](getting-started/installation.md)**

    Grab the binary or build from source.

-   :material-rocket-launch: **[Quickstart](getting-started/quickstart.md)**

    First request in under a minute, no API key.

-   :material-robot: **[Agentic testing](agentic-testing.md)**

    Run ADK / LangGraph loops in CI with zero token spend.

-   :material-cog: **[Configuration](configuration/provider-config.md)**

    Override any provider or template via `--config-dir`.

</div>

## License

Apache 2.0. Source: [github.com/vidaiUK/VidaiMock](https://github.com/vidaiUK/VidaiMock).
