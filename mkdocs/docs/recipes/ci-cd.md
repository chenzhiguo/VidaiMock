---
title: CI/CD Integration
---

# CI/CD Integration

VidaiMock's whole reason for existing is to make AI integration tests
**deterministic, free, and offline**. A single static binary, no Docker, no
DB, no persistent state to clean up between runs — it's purpose-built for
CI pipelines that can't (and shouldn't) burn live-provider tokens per run.

## The pattern

```bash
# 1. Start the mock in the background
./vidaimock --port 8100 &
MOCK_PID=$!

# 2. Wait for liveness
until curl -sf http://localhost:8100/health >/dev/null; do sleep 0.1; done

# 3. Point your app's provider base URL at the mock
export OPENAI_BASE_URL=http://localhost:8100/v1
export ANTHROPIC_BASE_URL=http://localhost:8100

# 4. Run your test suite
pytest

# 5. Tear down
kill $MOCK_PID
```

No API keys needed — VidaiMock ignores `Authorization` on mock routes.

## Zero-token agentic CI

Because VidaiMock terminates tool-calling loops correctly (see
[Agentic workflow testing](../agentic-testing.md)), full ADK / LangGraph /
LangChain Runner tests run start-to-finish in CI without a single live
token. This is the difference between "we test our agent logic on every PR"
and "we test it manually before release because real tokens cost money."

## Resilience / fallback testing

Verify retry and circuit-breaker logic by registering a forced-failure
upstream alongside a healthy one — same instance, different URL:

```
primary  endpoint: http://localhost:8100/v1?chaos_status=500
fallback endpoint: http://localhost:8100/v1
```

Or inject probabilistic chaos for soak tests:

```bash
./vidaimock --port 8100 &
# 5% of requests fail with a provider-shaped 500, 5% of streams disconnect
curl -H "X-Vidai-Chaos-Drop: 5" ...
```

See [Chaos & error injection](../chaos-and-errors.md).

## Per-pipeline custom behaviour

Ship a `--config-dir` with your test fixtures so the mock returns exactly
what a given suite needs, without touching the binary:

```bash
./vidaimock --config-dir ./tests/mock-fixtures --port 8100 &
```

See [Overriding bundled defaults](../configuration/overriding.md).

## GitHub Actions sketch

```yaml
- name: Start VidaiMock
  run: |
    curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-linux-x64.tar.gz
    tar -xzf vidaimock-linux-x64.tar.gz
    ./vidaimock/vidaimock --port 8100 &
    until curl -sf http://localhost:8100/health; do sleep 0.1; done

- name: Run tests
  env:
    OPENAI_BASE_URL: http://localhost:8100/v1
  run: pytest -q
```

The binary is ~7 MB and starts instantly, so this adds negligible time to
the pipeline.

## Why not a recorded-cassette mock?

Cassette/VCR-style mocks replay static captures. They can't simulate
streaming physics, won't terminate an agentic loop, and drift the moment
the provider changes a field. VidaiMock generates responses dynamically
from templates that are regression-tested byte-level against real captures —
so it stays accurate without re-recording.
