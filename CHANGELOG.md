# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.9] - 2026-05-24
### Added
- **Docker Compose setup** at [`docker/`](docker/) — `curl -O … && docker
  compose up` flow with optional `./overrides` mount for editing
  providers/templates, and `VIDAIMOCK_ISOLATED=true` env var to lock
  the surface down. See [docker/README.md](docker/README.md) and
  [Docker Compose recipe](https://vidai.uk/docs/mock/recipes/docker-compose/).
- `workflow_dispatch` on `.github/workflows/docker.yml` lets us push
  Docker-only RC images without re-running the entire Release pipeline
  (sources binaries from a previously published tarball).

### Changed
- README + mkdocs lead with Docker Compose as the recommended Docker
  path; bare `docker run` kept as the throwaway evaluator one-liner.
- No Rust code changes in this release — binary is byte-identical to
  v0.2.8. Docker image at `:0.2.9` and `:latest` cosign-signed against
  the same Vidai release key.

## [0.2.8] - 2026-05-24
### Added
- `--isolated` flag (also `VIDAIMOCK_ISOLATED` env / `isolated = true`
  in TOML) — skip embedded providers + templates and serve only what
  `--config-dir` declares. For production CI rigs and security audits.
  Closes issue #6.
- Signed multi-arch Docker image at `ghcr.io/vidaiuk/vidaimock` with
  cosign — `linux/amd64` + `linux/arm64`. Closes issue #5.
- Release tarballs (all 5 platforms) now ship with `.bundle` sidecar
  cosign signatures for the binary AND the tarball. Verifiable against
  the Vidai release key at `https://vidai.uk/.well-known/cosign.pub`.
- 404 response in isolated mode includes a mode-aware hint pointing
  users at `/status` for diagnostics.

### Changed
- `models_handler` no longer returns a misleading `gpt-4` fallback when
  no providers are loaded — returns an empty list instead.

## [Unreleased]
### Added
- Vertex AI provider with support for Google Cloud endpoint patterns.
- Robust Google Gemini AI Studio vs Vertex AI matching logic.
- Comprehensive documentation restructure (10+ new guides).
- Enhanced `extract_content_from_str` for better Gemini/Vertex streaming support.
- **Provider Priority**: New `priority` field in YAML configs for deterministic matching when patterns overlap.
- **Stable Context Variables**: `{{ uuid }}` and `{{ timestamp }}` (Number) are now stable across the entire request.

### Fixed
- Route conflict between Gemini POST and Anthropic GET paths.
- Tera template syntax for `random_int` (requires named arguments).
- Regression in template context variables (`uuid`, `timestamp`).

## [0.1.0] - 2025-12-15

### Added
- Initial release of VidaiMock
- Multi-provider support: OpenAI, Anthropic, Gemini, OpenRouter formats
- High-performance async server using Axum and Tokio
- `mimalloc` allocator for improved performance
- Latency simulation modes: `benchmark` (zero-latency) and `realistic` (configurable delay + jitter)
- Custom preset support via JSON files in `presets/` directory
- Custom response file override via `--response-file` flag
- Configurable endpoints via CLI or TOML config file
- Prometheus metrics endpoint (`/metrics`)
- Health check endpoint (`/health`)
- Status endpoint (`/status`)
- Echo handler for debugging
- Path traversal protection (security hardened)
- Fuzz testing with proptest
- Configurable bind address via `--host` flag
- Graceful shutdown on SIGTERM/SIGINT
- Structured JSON logging via tracing

### Security
- Path traversal protection tested and verified
- No `unsafe` code blocks
- Configurable network binding (localhost vs all interfaces)

### Documentation
- README with quick start guide
- USER_GUIDE with detailed configuration
- TUNING guide for performance optimization
- SECURITY.md for vulnerability reporting
- CONTRIBUTING.md for contributors
