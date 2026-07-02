# syntax=docker/dockerfile:1.7
#
# Runtime-only image. Binaries are built natively in the GitHub Actions
# matrix in .github/workflows/release.yml and copied in below. No
# cargo build happens during docker build.
#
# The config/ tree is embedded into the binary at compile time via
# rust-embed, so this image carries no on-disk config by default. Mount
# a directory at /config and pass --config-dir /config to override.

FROM gcr.io/distroless/cc-debian12:nonroot

ARG TARGETARCH

COPY --chown=nonroot:nonroot bin/linux-${TARGETARCH}/vidaimock /usr/local/bin/vidaimock

EXPOSE 8100

ENTRYPOINT ["/usr/local/bin/vidaimock"]
CMD ["--host", "0.0.0.0", "--port", "8100"]
