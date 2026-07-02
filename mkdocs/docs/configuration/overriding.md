---
title: Overriding Bundled Defaults
---

# Overriding Bundled Defaults

This is the single most important thing to understand about customising
VidaiMock — and it's by design simple: **disk beats embedded.**

The binary embeds the entire `config/` tree (every provider YAML and every
`.j2` template) at compile time, so it runs standalone. Anything with the
same path in your `--config-dir` **shadows** the embedded default. No
forking, no rebuilds, no patching the binary.

```bash
./vidaimock --config-dir ./my-config
```

## Override a provider's behaviour

Drop a `providers/openai.yaml` into your config dir. VidaiMock loads yours
instead of the bundled one:

```
my-config/
└── providers/
    └── openai.yaml      # shadows the embedded openai provider
```

## Override a template, keep the provider

Templates are overridable **independently** of provider configs. To change
how OpenAI chat responds without touching the provider YAML, just shadow the
template:

```
my-config/
└── templates/
    └── openai/
        └── chat.json.j2   # shadows the embedded chat template
```

## Add a brand-new endpoint

Drop any YAML into `providers/` with a unique `matcher`. Use `priority` to
make it win over a broad catch-all:

```yaml
# my-config/providers/acme.yaml
name: "acme"
matcher: "^/acme/v1/generate$"
priority: 100
response_template: "acme/response.j2"
```

…with the matching template at
`my-config/templates/acme/response.j2`.

## Mental model

```
request → match against (your providers ∪ embedded providers, by priority)
        → render (your template if present, else embedded template)
```

It's a layered overlay, file-level: a same-named file replaces the embedded
one wholesale (it does **not** deep-merge field-by-field). That keeps the
model predictable and means bundled defaults can change between VidaiMock
versions without disrupting your customisations.

## Isolated mode

`--config-dir` is **additive** — bundled providers you don't override still
load. For most users that's the right default ("batteries included"). But if
you want the mock to serve *only* what you declare — typical for production
test rigs where you want zero ambiguity about what's responding — add
`--isolated`:

```bash
./vidaimock --config-dir ./my-config --isolated
```

Or via `mock-server.toml`:

```toml
isolated = true
```

Or env var:

```bash
VIDAIMOCK_ISOLATED=true ./vidaimock --config-dir ./my-config
```

In isolated mode:

- **Only** providers/templates from `--config-dir` are loaded. Bundled
  defaults are skipped entirely.
- `/v1/models` lists only your providers (no canned fallback either —
  if you load zero providers it returns an empty list).
- `/status` reports `"isolated": true` so you can confirm the runtime mode.
- The 404 response on an unmatched route mentions isolated mode in its
  body, so you can diagnose quickly when a request you expected to work
  doesn't match a provider in your dir.
- A warning is logged at startup if your dir is empty: "Every request
  will return 404 until you add a provider YAML."

### Gotchas to know

- **Bundled provider routes stop working.** Endpoints like
  `/v1/chat/completions`, `/v1/messages`, and `/error/{code}` are served by
  bundled providers. In isolated mode you must supply your own provider
  for any route you want to serve. (To restore `/error/{code}`, copy the
  4-line bundled `error_simulator.yaml` into your config dir.)
- **Templates aren't shared either.** If your custom provider references a
  bundled template path like `openai/chat.json.j2`, the render will fail
  with a Tera "template not found" error — that template isn't in the
  registry in isolated mode. Either copy the template into your
  `templates/` dir, or write your own.
- **Chaos & override headers still work** (`X-Mock-Status`,
  `?chaos_status=`, `X-Vidai-Chaos-Drop`) — but they only fire **after**
  one of your providers matches the request. With zero providers loaded,
  nothing matches, so chaos is inert.

### When to use isolated mode

| Situation | Default mode | Isolated mode |
|---|---|---|
| Trying VidaiMock for the first time | ✓ | |
| CI pipeline against a single SDK | ✓ | better |
| Production test rig — must guarantee only your configured providers serve | | ✓ |
| Security/auditability — no surprise bundled routes | | ✓ |
| Custom-provider tests that should fail loudly if your config is wrong | | ✓ |

## Static-demo escape hatch

The bundled `templates/openai/tool_call.json.j2` is kept as a fixed-shape
demo template (always `get_weather`). If you specifically want the old
"always the same tool" behaviour, point a provider's `response_template` at
it rather than the smart-branching `openai/chat.json.j2`.

## Verify what loaded

```bash
curl -s http://localhost:8100/status | jq .
```

Run with `--mode debug` for verbose provider/template load logging.

Next: [Writing templates](templates.md).
