# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |

## Reporting a Vulnerability

Vidai's security disclosure entry point is:

**<https://vidai.uk/.well-known/security.txt>** (RFC 9116)

That file is the canonical, machine-readable place we publish current
contact details, response expectations, and our PGP key. Always check
it for the latest information.

**Do NOT create public GitHub issues for security vulnerabilities.**

## Release verification

Every VidaiMock release (binary, tarball, Docker image) is signed
with the Vidai cosign release key. The trust anchor is published at
**<https://vidai.uk/.well-known/cosign.pub>** — fetch from there and
verify with `cosign verify` / `cosign verify-blob`.

## Security Features

VidaiMock includes several security features:

- **Path Traversal Protection**: Preset file loading validates paths to prevent directory traversal attacks (tested)
- **No Unsafe Code**: The codebase contains no `unsafe` Rust blocks
- **Configurable Bind Address**: Use `--host 127.0.0.1` to bind only to localhost
- **Dependency Auditing**: We recommend running `cargo audit` regularly

## Recommended Deployment

For production use:

```bash
# Bind to localhost only (recommended for local development)
vidaimock --host 127.0.0.1 --port 8100

# For container deployments, use 0.0.0.0 (default)
vidaimock --port 8100
```

When exposing to networks:
- Place behind a reverse proxy (nginx, traefik) with rate limiting
- Use firewall rules to restrict access
- Consider TLS termination at the proxy level
