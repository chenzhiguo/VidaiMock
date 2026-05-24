# Releasing VidaiMock

This is the operational runbook for cutting a VidaiMock release. The release
flow is **tag-driven**: pushing a `v*` tag to `origin` triggers two parallel
GitHub Actions workflows that build, sign, and publish all artefacts.

For the *why* behind the design (key custody, signing model, trust anchor),
see [SECURITY.md](SECURITY.md).

---

## What a release publishes

A single tag push produces three independently signed artefact families, all
verifiable against the same public key at
[release-assets/cosign.pub](release-assets/cosign.pub):

| Artefact | Location | Signature |
|---|---|---|
| Five platform tarballs (linux x64/arm64, macos x64/arm64, windows x64) | GitHub Releases page | `<tarball>.bundle` next to each |
| The bare binary inside each tarball | Inside the tarball as `vidaimock` + `vidaimock.bundle` | Same as above, ships inside |
| Multi-arch Docker image (`linux/amd64` + `linux/arm64`) | `ghcr.io/vidaiuk/vidaimock:<version>` + `:latest` | Cosign sibling artifact at `:sha256-<hash>.sig` |

---

## Prerequisites (one-time)

These are already in place; included here so a future reset can re-derive
them.

- **GitHub Secrets** on `vidaiUK/VidaiMock`:
  - `COSIGN_PRIVATE_KEY` — PEM-encoded cosign private key
  - `COSIGN_PASSWORD` — passphrase for the key
  - Source of truth: 1Password `op://Private/Vidai Cosign Release Key`
- **Public key** committed at [release-assets/cosign.pub](release-assets/cosign.pub) —
  same key as the Vidai Deployment repo (single trust anchor).
- **Branch protection** on `main`:
  - PRs required, CODEOWNERS review enforced on `.github/workflows/`
  - No force push, no branch deletion
- **GHCR package visibility** (after the first push): set to **public** at
  `https://github.com/orgs/vidaiUK/packages/container/vidaimock/settings`
  — required for external `docker pull`. One-time UI step.

---

## Release flow

### 1. Bump version + commit

```bash
# Edit Cargo.toml: version = "X.Y.Z"
cargo build --release           # regenerates Cargo.lock with new version
git add Cargo.toml Cargo.lock
git commit -m "Bump version to X.Y.Z"
```

PR + merge to `main` per branch protection. After merge, pull the latest:

```bash
git checkout main && git pull
```

### 2. Cut a release candidate first

Pre-release tags (`-rc1`, `-rc2`, etc.) let you exercise the full pipeline
without affecting `:latest` semantics for users — pre-release tags are
flagged as such on the GitHub Releases page and do **not** become the
"latest" download.

```bash
git tag vX.Y.Z-rc1
git push origin vX.Y.Z-rc1
```

Both workflows fire in parallel. Watch them at
`https://github.com/vidaiUK/VidaiMock/actions`.

### 3. First-release-only: flip GHCR package to public

If this is the **very first** push to GHCR for this repo, the package
defaults to private. Visit
`https://github.com/orgs/vidaiUK/packages/container/vidaimock/settings`
and click *Change visibility → Public*. Subsequent releases inherit the
setting.

### 4. Verify the RC end-to-end from your laptop

```bash
VERSION=X.Y.Z-rc1
PUBKEY_URL="https://raw.githubusercontent.com/vidaiUK/VidaiMock/main/release-assets/cosign.pub"

# Verify the Docker image
cosign verify --key "$PUBKEY_URL" --insecure-ignore-tlog \
  ghcr.io/vidaiuk/vidaimock:$VERSION

# Verify a tarball (pick any platform)
curl -LO "https://github.com/vidaiUK/VidaiMock/releases/download/v$VERSION/vidaimock-linux-x64.tar.gz"
curl -LO "https://github.com/vidaiUK/VidaiMock/releases/download/v$VERSION/vidaimock-linux-x64.tar.gz.bundle"
cosign verify-blob --key "$PUBKEY_URL" --insecure-ignore-tlog \
  --bundle vidaimock-linux-x64.tar.gz.bundle \
  vidaimock-linux-x64.tar.gz

# Verify the bare binary inside (extract first)
tar -xzf vidaimock-linux-x64.tar.gz
cosign verify-blob --key "$PUBKEY_URL" --insecure-ignore-tlog \
  --bundle vidaimock/vidaimock.bundle \
  vidaimock/vidaimock

# Smoke-test the image actually starts
docker run --rm -d -p 8101:8100 --name vmtest ghcr.io/vidaiuk/vidaimock:$VERSION
sleep 2
curl -s http://localhost:8101/health    # expect {"status":"ok"}
curl -s http://localhost:8101/status | head
docker rm -f vmtest
```

All three `verify` commands must print `Verified OK`. Any failure means
**do not promote to stable** — investigate first.

### 5. Promote: cut the stable tag

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Workflows run again, producing the production artefacts. `:latest` updates
automatically.

### 6. Verify the stable release the same way

Repeat step 4 with `VERSION=X.Y.Z`. Also `cosign verify` the `:latest` tag
to confirm it now points at the new digest:

```bash
cosign verify --key "$PUBKEY_URL" --insecure-ignore-tlog \
  ghcr.io/vidaiuk/vidaimock:latest
```

---

## Rollback / fixing a bad release

### If the RC fails before promotion

```bash
git push --delete origin vX.Y.Z-rc1     # delete the remote tag
git tag -d vX.Y.Z-rc1                   # delete the local tag
gh release delete vX.Y.Z-rc1 --yes --repo vidaiUK/VidaiMock
```

GHCR will keep the package version but it's unreferenced — list and delete
specific versions with:

```bash
gh api -X GET /orgs/vidaiUK/packages/container/vidaimock/versions \
  | jq '.[] | {id, name: .name, tags: .metadata.container.tags}'
gh api -X DELETE /orgs/vidaiUK/packages/container/vidaimock/versions/<ID>
```

Fix the issue, re-tag (`-rc2`), retry.

### If a stable release is broken

Don't delete it — that breaks any user who already pulled it. Cut a
patch release (`vX.Y.Z+1`) with the fix. `:latest` automatically follows
the new tag.

### If the cosign key is ever leaked

This is the worst case. The fix:

1. Generate a new cosign keypair (`cosign generate-key-pair`).
2. Update the 1Password entry to the new private key + new password.
3. Update the two GitHub Secrets:
   ```bash
   op read 'op://Private/Vidai Cosign Release Key/cosign/key' \
     | gh secret set COSIGN_PRIVATE_KEY --repo vidaiUK/VidaiMock
   op read 'op://Private/Vidai Cosign Release Key/password' \
     | gh secret set COSIGN_PASSWORD --repo vidaiUK/VidaiMock
   ```
4. Commit the **new** public key as `release-assets/cosign.pub` (don't delete
   the old one — historical releases are still signed with it. Move it to
   `release-assets/cosign-rotated-YYYY-MM-DD.pub` and document the rotation
   date in [SECURITY.md](SECURITY.md)).
5. Cut a new release. Future verifications use the new key.

Existing users verifying old releases need to either use the rotated old
pubkey, or accept the new release. Document the rotation publicly.

---

## Two-workflow architecture: why and how

There are two separate workflow files, both triggered on the same tag:

- **[`.github/workflows/release.yml`](.github/workflows/release.yml)** — 5-platform
  matrix. Each job: builds binary natively → signs binary → packages tarball
  → signs tarball → uploads as artifact. Final job assembles GitHub Release
  with all artefacts.
- **[`.github/workflows/docker.yml`](.github/workflows/docker.yml)** — waits for
  `release.yml`'s two linux jobs → downloads their tarballs → extracts the
  binaries → buildx multi-arch image referencing pre-built binaries
  (no Rust toolchain in the docker job) → pushes to GHCR → signs the
  manifest-list digest → self-verifies.

Why separate: a Docker failure shouldn't block tarball publication; a
tarball failure should block the Docker image (which depends on linux
tarballs). The wait-for-checks step in `docker.yml` enforces that ordering.

---

## Cosign notes

The workflows use cosign **without** the Sigstore transparency log
(Rekor). Trust anchor is the public key committed to this repo, not a
public log entry. This means:

- All `cosign sign` / `sign-blob` calls pass `--signing-config <path>` with
  a config that has no Rekor URLs (built fresh per workflow run from
  `cosign signing-config create | jq 'del(.rekorTlogUrls)'`).
- All `cosign verify` / `verify-blob` calls pass `--insecure-ignore-tlog`.
  The flag name sounds scary but is correct for a keyed-trust model — the
  warning is aimed at users of the keyless flow.
- `--tlog-upload=false` is **deprecated** in cosign v2.5+ and cannot be
  combined with a signing-config. We use `--signing-config` instead.

This mirrors the pattern in
[Vidai Deployment scripts/cosign.sh](../Deployment/scripts/cosign.sh) —
same key, same trust model, two surfaces (public OSS via GHCR; private
Vidai Control Plane via Harbor).

---

## Future migrations

- **1Password Service Account in CI** (currently GitHub Secrets): swap the
  two `secrets.COSIGN_*` references for `1password/load-secrets-action`
  reading the same `op://Private/Vidai Cosign Release Key/...` paths the
  Makefile already uses. Cosign step is unchanged. Requires a 1Password
  Business plan (~$20/mo for unlimited service accounts). Planned
  post-revenue.
- **Harbor mirror**: when first airgap customer asks, add a
  `make mirror-vidaimock V=...` target to the Vidai Deployment repo that
  pulls from GHCR, verifies the signature, re-pushes to Harbor, signs at
  Harbor. Same digest, same key, two registry locations. VidaiMock CI
  stays GHCR-only.
- **SBOM + provenance attestation**: `docker buildx` can emit SLSA
  provenance + an SBOM. Currently disabled (`provenance: false`) because
  buildx's attestation manifest confuses `cosign verify` against the
  *tag* form. When customers need SBOMs we'll move to digest-only
  verification in the install docs and re-enable provenance.
