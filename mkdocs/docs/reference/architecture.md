---
title: Architecture
---

# Architecture

VidaiMock is a single Rust binary built on Axum + Tokio, with `mimalloc` for
allocation throughput. It's deliberately small and stateless — that's what
makes it microsecond-fast and trivially CI-friendly.

## Request lifecycle

```
HTTP request
  → router match (Axum)
  → provider match: first provider whose `matcher` regex hits,
                     ordered by `priority` then load order
  → build Tera context (json, headers, query, path_segments)
  → resolve status (chaos roll → X-Mock-Status → ?chaos_status
                     → provider status_code → 200)
  → pick template (status ≥ 400 → error_template, else response_template)
  → render Tera → response
       (streaming providers run the on_start/on_chunk/on_stop lifecycle)
```

## Components

### Provider registry

At startup the binary loads every embedded provider YAML (compiled in via
`rust-embed`), then overlays any same-named files from `--config-dir`
(disk beats embedded — see
[Overriding bundled defaults](../configuration/overriding.md)). The result
is an **immutable** registry: a `Vec<ProviderConfig>` plus pre-compiled
matcher regexes. Immutability is deliberate — request-time matching is a
lock-free regex scan, which is why throughput is high.

### Tera engine

One Tera instance holds every template (embedded + overridden) plus the
registered helper functions (`uuid`, `timestamp`, `random_int`,
`has_tool_result`, …). Templates are parsed once at load.

### Status resolution

A single function decides the HTTP status with a fixed precedence:
chaos dice-roll → `X-Mock-Status` header → `?chaos_status` query →
provider `status_code` (static or Tera) → default 200. It returns both the
status **and** a `StatusSource` so the caller knows whether to render the
`error_template`.

### Streaming engine

For streaming providers the engine renders the response, extracts the
streamable content (text → word-chunked; tool calls → a single structured
chunk), and runs the `on_start` / `on_chunk` / `on_stop` lifecycle.
`frame_format: raw` hands SSE framing to the templates and preserves blank
lines as event separators, enabling typed multi-event providers.

### Content extraction

`extract_content_value` recognises each provider's "what should I stream"
shape — OpenAI `choices[].message.content` / `tool_calls`, Anthropic
`content[].text` / `tool_use`, Gemini `candidates[].content.parts[].text` /
`functionCall`, plus Bedrock/Responses-API shapes. Tool-call shapes are
returned as a single structured chunk so streaming doesn't mangle them into
fake text.

## Design properties

- **Stateless.** No DB, no persisted state, nothing to clean between CI
  runs. Each request is a pure function of (request, loaded config).
- **Immutable hot path.** No locks during matching/rendering → 50,000+ RPS
  in benchmark mode.
- **Embedded-then-overlay config.** The binary is self-contained;
  `--config-dir` is purely additive/overriding.
- **Template-driven.** Behaviour lives in Tera templates, not Rust. New
  providers/behaviour usually need zero code changes.
- **Wire-shape regression-tested.** The test suite asserts byte-level
  framing against captured real-provider output, so accuracy doesn't
  silently drift.

## Project layout

```
src/
  main.rs        # startup, config load, server boot
  server.rs      # Axum router, middleware, route registration
  handlers.rs    # request handlers, status resolution, streaming engine
  provider.rs    # registry, Tera setup, helper functions
  replacer.rs    # Tera context construction
  aws_event_stream.rs  # Bedrock binary event-stream encoding
config/
  providers/     # bundled provider YAMLs (embedded at compile time)
  templates/     # bundled Tera templates (embedded at compile time)
examples/        # 20+ advanced example templates (shipped in releases)
```

## Multi-tenant runtime (evaluation branch)

A multi-tenant runtime — per-tenant isolated provider registries with
atomic reload and management endpoints — exists on the
[`integration/multi-tenant-runtime`](https://github.com/vidaiUK/VidaiMock/tree/integration/multi-tenant-runtime)
branch. It is **not** on `main` and not part of the released binary; it's a
forward-looking foundation for a future Team/Cloud edition. The released
single-tenant model documented here is unaffected.
