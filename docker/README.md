# VidaiMock — Docker Compose setup

The simplest Docker setup for VidaiMock. Three modes, one compose file,
no bootstrap step.

## Quick start

```bash
# 1. Get the compose file (one-time, anywhere you want to run the mock)
curl -O https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/docker/docker-compose.yml

# 2. Run it
docker compose up -d

# 3. Confirm
curl http://localhost:8100/health      # {"status":"ok"}
```

That's it. The mock is listening on port 8100 with the full bundled
provider set (OpenAI, Anthropic, Gemini, Bedrock, …) serving immediately.

## Three usage modes

### 1. Just evaluate

Don't create anything else. The bundled providers + templates serve out
of the box — same as `docker run --rm -p 8100:8100 ghcr.io/vidaiuk/vidaimock:latest`.

### 2. Override one or more providers / templates

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

### 3. Lock the surface down (production CI rigs)

Set one env var to make the mock serve **only** what's in `./overrides`,
skipping the embedded layer entirely. Useful for security review or
fail-loud CI tests where a missing provider should 404 rather than
silently fall back to a bundled default.

```bash
echo "VIDAIMOCK_ISOLATED=true" > .env
docker compose up -d --force-recreate
curl http://localhost:8100/status   # "isolated": true
```

## Configuration

Optional env vars live in `.env` (copy from `.env.example`). The compose
file works without `.env` — every var has a sensible default.

| Variable | Default | Effect |
|---|---|---|
| `VIDAIMOCK_VERSION` | `latest` | Docker image tag to run |
| `VIDAIMOCK_PORT` | `8100` | Host port to publish (container always listens on 8100 internally) |
| `VIDAIMOCK_LOG_LEVEL` | `info` | `error`, `warn`, `info`, `debug` |
| `VIDAIMOCK_ISOLATED` | `false` | Skip embedded defaults; serve only `./overrides` |

For artificial latency, add `--latency <ms>` to the compose `command:`
array (latency is a nested struct — top-level env var doesn't work).

## Verify the signed image (optional)

The image is cosign-signed against the Vidai release key:

```bash
cosign verify \
  --key https://vidai.uk/.well-known/cosign.pub \
  --insecure-ignore-tlog \
  ghcr.io/vidaiuk/vidaimock:latest
```

See <https://vidai.uk/cosign> for the trust model.

## Full docs

<https://vidai.uk/docs/mock/>
