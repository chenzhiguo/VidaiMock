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
