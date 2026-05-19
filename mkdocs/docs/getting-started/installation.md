---
title: Installation
---

# Installation

VidaiMock ships as a single static binary. Releases come bundled with the
binary, the default provider configs, the bundled templates, and the
examples folder.

## Download a release

Each archive extracts to a `vidaimock/` directory containing the binary plus
`config/` and `examples/`.

=== "macOS (Apple Silicon)"

    ```bash
    curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-macos-arm64.tar.gz
    tar -xzf vidaimock-macos-arm64.tar.gz && cd vidaimock
    ./vidaimock
    ```

=== "macOS (Intel)"

    ```bash
    curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-macos-x64.tar.gz
    tar -xzf vidaimock-macos-x64.tar.gz && cd vidaimock
    ./vidaimock
    ```

=== "Linux (ARM64)"

    ```bash
    curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-linux-arm64.tar.gz
    tar -xzf vidaimock-linux-arm64.tar.gz && cd vidaimock
    ./vidaimock
    ```

=== "Linux (x64)"

    ```bash
    curl -LO https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-linux-x64.tar.gz
    tar -xzf vidaimock-linux-x64.tar.gz && cd vidaimock
    ./vidaimock
    ```

=== "Windows (x64)"

    ```powershell
    Invoke-WebRequest -Uri https://github.com/vidaiUK/VidaiMock/releases/latest/download/vidaimock-windows-x64.zip -OutFile vidaimock-windows-x64.zip
    Expand-Archive vidaimock-windows-x64.zip -DestinationPath .
    cd vidaimock
    .\vidaimock.exe
    ```

!!! warning "OS security notice (macOS / Windows)"
    Because VidaiMock is an unsigned open-source binary, your OS may block it
    on first run.

    - **macOS**: `xattr -d com.apple.quarantine vidaimock`
    - **Windows**: click *More info* in the SmartScreen dialog, then *Run anyway*

## Build from source

Requires a recent stable Rust toolchain (1.70+).

```bash
git clone https://github.com/vidaiUK/VidaiMock.git
cd VidaiMock
cargo build --release
./target/release/vidaimock
```

The bundled `config/` (providers + templates) is embedded into the binary at
compile time, so the binary works standalone with no files alongside it. A
local `config/` directory or `--config-dir` only *overrides* the embedded
defaults — see [Overriding bundled defaults](../configuration/overriding.md).

## Verify

```bash
./vidaimock --version
curl -s http://localhost:8100/health      # {"status":"ok"} once running
```

Next: [Quickstart](quickstart.md).
