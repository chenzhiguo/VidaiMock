---
title: VidaiMock
---

# VidaiMock

**Batteries-included mock server for LLM APIs and agents.** Works instantly
with OpenAI, Anthropic, Gemini, Bedrock, and more. Run ADK / LangGraph /
LangChain agentic workflows against it without a single live-provider token.
Zero config required.

VidaiMock ships as a signed multi-arch Docker image and a single ~7 MB Rust
binary that emulates the **exact wire format** of production AI providers —
including streaming physics, typed SSE events, tool-call shapes, and error
envelopes — so SDK and integration tests pass against it the same way they
would against the real APIs, deterministically and for free.

[:fontawesome-brands-github: View on GitHub](https://github.com/vidaiUK/VidaiMock){ .md-button .md-button--primary }
[:material-rocket-launch: Quickstart](getting-started/quickstart.md){ .md-button }

!!! tip "Built for the Vidai AI Control Plane"
    VidaiMock is the simulation engine we use to validate the
    [Vidai AI Control Plane](https://vidai.uk), our high-density,
    enterprise-grade control plane for LLM infrastructure. The same logic
    that simulates network jitter, latency, and failure modes here is used
    in production to keep the Vidai Control Plane resilient.

## 30-second demo

**Docker Compose:**

```bash
curl -O https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/docker/docker-compose.yml
docker compose up -d

# No API key needed — VidaiMock ignores Authorization on mock routes.
curl -N http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "stream": true, "messages": [{"role": "user", "content": "Hello!"}]}'
```

Full Docker flow — overrides, isolated mode, env vars:
[Docker Compose recipe](recipes/docker-compose.md).

**Binary** (no Docker needed, macOS Apple Silicon shown — see
[Installation](getting-started/installation.md) for other OSes):

```bash
curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-macos-arm64.tar.gz
tar -xzf vidaimock-macos-arm64.tar.gz && cd vidaimock
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
- **Isolated mode** — lock the surface down to exactly what you declare in
  `--config-dir`; bundled providers skip loading entirely. See
  [Overriding bundled defaults → Isolated mode](configuration/overriding.md#isolated-mode).
- **Signed releases** — every Docker image, tarball, and bare binary is
  cosign-signed against the public key at
  [vidai.uk/.well-known/cosign.pub](https://vidai.uk/.well-known/cosign.pub).
  See [Installation → Verify](getting-started/installation.md#verify-release-signatures-cosign).

Read the [Providers overview](providers/index.md) for the full endpoint table.

## Where to go next

<div class="grid cards" markdown>

-   :material-download: **[Install](getting-started/installation.md)**

    Pull the Docker image, grab the binary, or build from source.

-   :material-rocket-launch: **[Quickstart](getting-started/quickstart.md)**

    First request in under a minute, no API key.

-   :material-robot: **[Agentic testing](agentic-testing.md)**

    Run ADK / LangGraph loops in CI with zero token spend.

-   :material-pipe-leak: **[Run in CI](recipes/ci-cd.md)**

    Docker-first CI pattern with digest pinning and cosign verification.

-   :material-cog: **[Configuration](configuration/provider-config.md)**

    Override any provider or template via `--config-dir`.

</div>

## License

Apache 2.0. Source: [github.com/vidaiUK/VidaiMock](https://github.com/vidaiUK/VidaiMock).
