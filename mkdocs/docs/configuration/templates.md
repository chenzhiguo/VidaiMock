---
title: Writing Templates
---

# Writing Templates

A response template is a [Tera](https://keats.github.io/tera/) file under
`config/templates/`. See [Templating](../templating.md) for the request
context and helper catalogue; this page is the practical how-to for authoring
your own.

## A minimal non-streaming template

`my-config/templates/acme/response.j2`:

```jinja2
{
  "id": "resp-{{ uuid() }}",
  "created": {{ timestamp() }},
  "model": "{{ json.model | default(value='acme-1') }}",
  "output": "Echo: {{ json.input | default(value='(none)') }}"
}
```

Wire it up with a provider:

```yaml
# my-config/providers/acme.yaml
name: "acme"
matcher: "^/acme/generate$"
response_template: "acme/response.j2"
```

```bash
./vidaimock --config-dir ./my-config &
curl http://localhost:8100/acme/generate -H 'Content-Type: application/json' \
  -d '{"model":"acme-1","input":"hello"}'
```

## Branching

Use Tera control flow to vary the response by request fields. Always guard
against missing fields with `default` or the `has_tool_result` helper:

```jinja2
{% if json.tools and has_tool_result(messages=json.messages, provider="openai") %}
  { ... plain-text answer, finish_reason: "stop" ... }
{% elif json.tools %}
  { ... tool_calls echoing {{ json.tools.0.function.name }} ... }
{% else %}
  { ... default text ... }
{% endif %}
```

## Streaming templates

A streaming provider declares a `lifecycle`. Each stage is a template:

```yaml
stream:
  enabled: true
  frame_format: raw
  lifecycle:
    on_start: { template_path: "acme/stream_start.j2" }
    on_chunk: { template_path: "acme/stream_delta.j2" }
    on_stop:  { template_path: "acme/stream_stop.j2" }
```

- `on_start` renders once at the beginning.
- `on_chunk` renders once per content chunk; the chunk is available as
  `chunk` (a string for text, or a structured value for a tool call).
- `on_stop` renders once at the end.

### `frame_format`

| Value | Behaviour |
|---|---|
| (unset / default) | Engine wraps each rendered chunk as `data: <chunk>\n\n`. |
| `raw` | Template emits its own framing verbatim. Blank lines in the template output are preserved as SSE event separators, so one template can emit a multi-event sequence. |

Use `raw` for typed-event providers (Responses API, Anthropic). Example
`on_stop` that emits a finish chunk, an optional usage chunk, then `[DONE]`,
each as its own SSE event:

```jinja2
data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

{% if json.stream_options.include_usage %}
data: {"choices":[],"usage":{"total_tokens":42}}

{% endif %}
data: [DONE]
```

### Handling structured chunks (tool calls)

When the response is a tool call, `chunk` is a structured value, not a
string. Branch on its type so you emit a single tool frame rather than
word-chunking JSON as fake text:

```jinja2
{% if chunk is string %}
  {"text": "{{ chunk }}"}
{% else %}
  {{ chunk | json_encode() }}
{% endif %}
```

## Gotchas

- **Deep array indexing is unreliable in Tera.** For history-spanning logic
  use `has_tool_result()`; for first-element access prefer
  `json.tools.0.function.name` with a `| default(...)` fallback.
- **Keep JSON valid after interpolation.** Quote string values and use
  `| json_encode()` when embedding structured data, otherwise a stray quote
  in `chunk` breaks the JSON.
- **`error_template` runs on ≥ 400.** If your provider can return errors,
  give it an `error_template` so the failure body is provider-shaped. The
  `status_code` variable is in scope there.
- **Validate with `--strict`-equivalent thinking.** Run the endpoint and
  pipe the body through `jq` / `od -c` for streaming to confirm framing.

## Where bundled templates live (read them for examples)

`config/templates/` in the repo. Good references:

- `openai/chat.json.j2` — full multi-branch chat (tools, reasoning,
  structured output, loop termination).
- `anthropic/stream/*.json.j2` — typed 7-event streaming with tool-mode
  branching.
- `gemini/stream_chunk.json.j2` / `stream_final.json.j2` — Gemini's
  delta-then-terminal pattern.
- `*/error.json.j2` — provider-shaped error envelopes.
