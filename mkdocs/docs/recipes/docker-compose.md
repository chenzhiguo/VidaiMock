---
title: Docker Compose
---

# Docker Compose

The simplest production-style way to run VidaiMock. One compose file,
three modes, no bootstrap step.

## Quick start

```bash
curl -O https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/docker/docker-compose.yml
docker compose up -d
curl http://localhost:8100/health    # {"status":"ok"}
```

That's it. The mock is listening on port 8100 with the full bundled
provider set (OpenAI, Anthropic, Gemini, Bedrock, …) serving immediately.

## Three modes

### Just evaluate

Don't create anything else. The embedded providers + templates serve out
of the box — same as `docker run --rm -p 8100:8100 ghcr.io/vidaiuk/vidaimock:latest`.

### Override one or more providers / templates

Create an `./overrides` directory next to the compose file. Drop your
YAMLs and templates in using the same path layout as the bundled tree:

```bash
mkdir -p overrides/providers
curl -o overrides/providers/openai.yaml \
  https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/config/providers/openai.yaml
vim overrides/providers/openai.yaml
docker compose restart
```

The binary uses **disk shadows embedded** semantics: any file under
`./overrides/` with the same path as a bundled file replaces the bundled
one wholesale. Files you don't touch keep their bundled behaviour.

To see what's bundled and pick what to override, browse the source:
<https://github.com/vidaiUK/VidaiMock/tree/main/config>

See [Overriding bundled defaults](../configuration/overriding.md) for the
full additive-overlay model.

### Lock the surface down (production CI rigs)

Set one env var to make the mock serve **only** what's in `./overrides`,
skipping the embedded layer entirely. Useful for security review or
fail-loud CI tests where a missing provider should 404 rather than
silently fall back to a bundled default.

```bash
echo "VIDAIMOCK_ISOLATED=true" > .env
docker compose up -d --force-recreate
curl http://localhost:8100/status   # "isolated": true
```

!!! warning "Isolated mode gotchas"
    In isolated mode the embedded **templates** are also skipped, not
    just providers. If your override `providers/openai.yaml` references
    `templates/openai/chat.json.j2`, you must also drop that template
    into `./overrides/templates/openai/chat.json.j2` — otherwise the
    render returns *Template not found*. Full list of gotchas:
    [Isolated mode](../configuration/overriding.md#isolated-mode).

## Configuration

Optional env vars live in `.env` next to `docker-compose.yml` (copy from
[`.env.example`](https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/docker/.env.example)).
The compose file works without `.env` — every var has a sensible default.

| Variable | Default | Effect |
|---|---|---|
| `VIDAIMOCK_VERSION` | `latest` | Docker image tag to run |
| `VIDAIMOCK_PORT` | `8100` | Host port to publish (container always listens on 8100 internally) |
| `VIDAIMOCK_LOG_LEVEL` | `info` | `error`, `warn`, `info`, `debug` |
| `VIDAIMOCK_ISOLATED` | `false` | Skip embedded defaults; serve only `./overrides` |

For artificial latency, add `--latency <ms>` to the compose `command:`
array (latency is a nested struct — top-level env var doesn't work).

## Pin to a specific version

For CI and production rigs, pin the image tag rather than running
`:latest`:

```bash
echo "VIDAIMOCK_VERSION=0.2.9" > .env
docker compose up -d
```

For maximum reproducibility, pin by digest instead — see
[CI/CD Integration → Why pin by digest](ci-cd.md#why-pin-by-digest).

## Verify the signed image

Every image is cosign-signed against the Vidai release key, published
at <https://vidai.uk/.well-known/cosign.pub>:

```bash
cosign verify \
  --key https://vidai.uk/.well-known/cosign.pub \
  --insecure-ignore-tlog \
  ghcr.io/vidaiuk/vidaimock:latest
```

See [Installation → Verify](../getting-started/installation.md#verify-release-signatures-cosign)
for the full trust model.

## Teardown

```bash
docker compose down
```

Removes the container and the docker network. Your `./overrides/`
directory and any `.env` stay on disk for your next `up`.

## Source

The compose file is part of the source repo at
[`docker/docker-compose.yml`](https://github.com/vidaiUK/VidaiMock/tree/main/docker).
PRs welcome.
