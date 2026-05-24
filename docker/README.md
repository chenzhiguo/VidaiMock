# VidaiMock — Docker Compose setup

Production-style Docker setup. Three commands to a working mock server,
with the bundled providers + templates extracted to a local `./config/`
folder you can edit with any text editor.

## Quick start

```bash
# 1. Get the compose file (one-time)
curl -O https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/docker/docker-compose.yml

# 2. Start the mock — first run bootstraps ./config with the bundled tree
docker compose up -d

# 3. Confirm
curl http://localhost:8100/health      # {"status":"ok"}
```

That's it. After `docker compose up` returns:

- The server is listening on port 8100.
- A `./config/` directory has appeared next to the compose file,
  pre-populated with every bundled provider YAML and template.
- A `./config/.bootstrapped` marker file records which version seeded it.

## Three usage modes

### Just evaluate

Don't touch `./config`. The mock works with the embedded defaults — same
behaviour as `docker run --rm -p 8100:8100 ghcr.io/vidaiuk/vidaimock:latest`.

### Override one or more providers / templates

Edit any file in `./config/providers/` or `./config/templates/`. The
binary's loader uses **disk shadows embedded** semantics: a file with the
same path in `./config/` replaces the embedded one wholesale. Files you
*don't* touch keep their bundled behaviour.

```bash
vim ./config/providers/openai.yaml
docker compose restart
```

### Lock the surface down (production CI rigs)

Set one env var to make the mock serve **only** what's in `./config`,
skipping the embedded layer entirely. Useful for security review or
fail-loud CI tests.

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
| `VIDAIMOCK_VERSION` | `latest` | Image tag to run (and version to bootstrap config from) |
| `VIDAIMOCK_PORT` | `8100` | Host port to publish (container always listens on 8100 internally) |
| `VIDAIMOCK_LOG_LEVEL` | `info` | `error`, `warn`, `info`, `debug` |
| `VIDAIMOCK_ISOLATED` | `false` | Skip embedded defaults; serve only `./config` |

For artificial latency, add `--latency <ms>` to the compose `command:`
array (latency is a nested struct — top-level env var doesn't work).

## How the bootstrap works

`docker compose up` runs an init container (`curlimages/curl`) that
downloads the matching release tarball, extracts just the `config/`
directory, and copies it to the host's `./config`. Subsequent `up`
commands see the `.bootstrapped` marker and skip the copy — your edits
survive.

To re-bootstrap (e.g. after upgrading to a newer image version):

```bash
rm -f ./config/.bootstrapped
docker compose up --force-recreate
```

## Re-verify the signed image (optional)

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
