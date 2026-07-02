---
title: Chaos & Error Injection
---

# Chaos & Error Injection

Real AI providers fail — they rate-limit, time out, return 500s, and sever
streams mid-generation. Code that doesn't handle that fails in production.
VidaiMock lets you reproduce every one of these conditions deterministically,
and **every injected error returns a provider-shaped JSON envelope** so your
SDK's error parser and retry/fallback logic engage exactly as they would
against the real API.

## Four ways to inject a failure

All four funnel through the same `error_template` pipeline, so the body is
always provider-accurate regardless of how the failure was triggered.

| Trigger | Scope | Use case |
|---|---|---|
| `?chaos_status=503` URL query | Per URL | Your routing layer registers one "broken" upstream and one "healthy" upstream against the same mock instance — fallback / circuit-breaker testing without forwarding client headers. |
| `X-Mock-Status: 429` header | Per request | An SDK-level test wants a specific status on a real provider route. |
| `X-Vidai-Chaos-Drop: 100` header | Probabilistic | Chaos testing — N% of requests return a provider-shaped 500. |
| Provider `status_code` Tera expression | Per request field | Request validation, e.g. Anthropic returning 400 when `max_tokens` is missing. |

### URL query — primary/fallback testing

```
primary  endpoint: http://vidaimock:8100/v1?chaos_status=500   # always fails
fallback endpoint: http://vidaimock:8100/v1                     # healthy
```

Same instance, same path, different outcome based on the query string. The
system under test can't tell it's the same mock.

```bash
curl -s "http://localhost:8100/v1/chat/completions?chaos_status=503" \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"hi"}]}'
```

### `X-Mock-Status` header

```bash
curl -H "X-Mock-Status: 429" http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
# -> HTTP 429, OpenAI-shape {"error": {...}}
```

### Probabilistic chaos

```bash
curl -H "X-Vidai-Chaos-Drop: 100" http://localhost:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hi"}]}'
# -> HTTP 500, application/json, provider-shaped error envelope
```

Configure persistently in `mock-server.toml`:

```toml
[chaos]
enabled = true
drop_pct = 0.01        # 1% provider-shaped 500
malformed_pct = 0.005  # 0.5% deliberately broken JSON body
trickle_ms = 50        # per-chunk streaming delay
disconnect_pct = 0.05  # 5% of streams sever mid-generation
```

### Provider-side validation

A provider's `status_code` can be a Tera expression that inspects the
request, so the mock can enforce real provider validation rules. The bundled
Anthropic provider does this for `max_tokens`:

```yaml
status_code: "{% if json.max_tokens %}200{% else %}400{% endif %}"
```

A missing `max_tokens` yields HTTP 400 with the real Anthropic error
envelope and a per-field message.

## Provider-shaped error envelopes

When the resolved status is ≥ 400, the provider's `error_template` is
rendered instead of the success template. Bundled templates produce:

| Provider | Envelope |
|---|---|
| OpenAI | `{"error": {"message", "type", "param", "code"}}` |
| Anthropic | `{"type": "error", "error": {"type", "message"}}` |
| Gemini | `{"error": {"code", "message", "status"}}` (gRPC-style status) |

The `type`/`status` is selected per HTTP code — `429` → OpenAI
`rate_limit_exceeded` / Anthropic `rate_limit_error` / Gemini
`RESOURCE_EXHAUSTED`, etc. The rendered template has a `status_code`
variable in scope so it can self-describe.

## The `/error/{code}` simulator

A provider-agnostic endpoint that returns any HTTP status with a generic
JSON error envelope — useful when you just need a failing endpoint at a
known path:

```bash
curl http://localhost:8100/error/400 -H "Content-Type: application/json" -d '{}'
curl http://localhost:8100/error/429 -H "Content-Type: application/json" -d '{}'
curl http://localhost:8100/error/503 -H "Content-Type: application/json" -d '{}'
```

## Stream chaos

`X-Vidai-Chaos-Trickle` slows each chunk; `X-Vidai-Chaos-Disconnect` severs
the stream mid-flight. A chaos-triggered error on a *streaming* request
returns a non-streaming HTTP error with a JSON body — matching real
providers, which respond with an HTTP 5xx + JSON rather than an SSE error
when the upstream fails.
