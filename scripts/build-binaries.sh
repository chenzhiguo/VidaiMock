#!/usr/bin/env bash
#
# VidaiMock — 多平台二进制编译脚本
#
# 编译结果输出到 bin/ 目录，可直接被 Dockerfile 使用
#
# 用法：
#   ./scripts/build-binaries.sh [TARGET...]
#
# 可用 TARGET：
#   linux-x64    (x86_64-unknown-linux-gnu)   ← Docker 需要
#   linux-arm64  (aarch64-unknown-linux-gnu)  ← Docker 需要
#   macos-x64    (x86_64-apple-darwin)
#   macos-arm64  (aarch64-apple-darwin)
#   windows-x64  (x86_64-pc-windows-msvc)
#   all          (编译所有，默认)
#
# 前置要求：
#   - Docker (cross 需要)
#   - Rust + Cargo
#   - cross (脚本会自动安装)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"

cd "$ROOT_DIR"

# 将平台名称映射为 (rust_target, dest_subdir, bin_filename, use_cross)
# 用 case 而非关联数组，兼容 macOS 自带的 bash 3.2
resolve_target() {
  case "$1" in
    linux-x64)
      RUST_TARGET="x86_64-unknown-linux-gnu"
      DEST_SUBDIR="linux-amd64"
      BIN_FILENAME="vidaimock"
      USE_CROSS=true
      ;;
    linux-arm64)
      RUST_TARGET="aarch64-unknown-linux-gnu"
      DEST_SUBDIR="linux-arm64"
      BIN_FILENAME="vidaimock"
      USE_CROSS=true
      ;;
    macos-x64)
      RUST_TARGET="x86_64-apple-darwin"
      DEST_SUBDIR="macos-x64"
      BIN_FILENAME="vidaimock"
      USE_CROSS=false
      ;;
    macos-arm64)
      RUST_TARGET="aarch64-apple-darwin"
      DEST_SUBDIR="macos-arm64"
      BIN_FILENAME="vidaimock"
      USE_CROSS=false
      ;;
    windows-x64)
      RUST_TARGET="x86_64-pc-windows-msvc"
      DEST_SUBDIR="windows-x64"
      BIN_FILENAME="vidaimock.exe"
      USE_CROSS=false
      ;;
    *)
      echo "⚠️  未知目标: $1，跳过"
      return 1
      ;;
  esac
  return 0
}

# 确定要编译的目标
if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  TARGETS=("linux-x64" "linux-arm64")  # Docker 只需要这两个
  echo "==> 编译默认目标 (用于 Docker): linux-x64, linux-arm64"
  echo "    如需编译所有平台，请运行: $0 all"
  echo "    如需指定平台，例如: $0 linux-x64 linux-arm64 macos-arm64"
  if [ "${1:-}" = "all" ]; then
    TARGETS=("linux-x64" "linux-arm64" "macos-x64" "macos-arm64" "windows-x64")
    echo "==> 编译所有平台"
  fi
else
  TARGETS=("$@")
fi

# 检查是否需要 cross
needs_cross=false
for NAME in "${TARGETS[@]}"; do
  case "$NAME" in
    linux-*) needs_cross=true; break ;;
  esac
done

if $needs_cross && ! command -v cross &>/dev/null; then
  echo "==> 安装 cross..."
  cargo install cross
fi

# 创建输出目录
mkdir -p "$BIN_DIR"

# 编译每个目标
for NAME in "${TARGETS[@]}"; do
  # 解析目标平台参数
  RUST_TARGET=""
  DEST_SUBDIR=""
  BIN_FILENAME=""
  USE_CROSS=false
  if ! resolve_target "$NAME"; then
    continue
  fi

  echo ""
  echo "==> 编译: $NAME ($RUST_TARGET)"

  if $USE_CROSS; then
    cross build --release --target "$RUST_TARGET"
  else
    cargo build --release --target "$RUST_TARGET"
  fi

  # 复制到 bin/ 目录
  DEST_DIR="$BIN_DIR/$DEST_SUBDIR"
  mkdir -p "$DEST_DIR"

  cp "target/$RUST_TARGET/release/$BIN_FILENAME" "$DEST_DIR/"
  chmod +x "$DEST_DIR/$BIN_FILENAME"

  echo "    输出: $DEST_DIR/$BIN_FILENAME"
done

echo ""
echo "✅ 编译完成！"
echo ""
echo "bin/ 目录内容:"
find "$BIN_DIR" -type f 2>/dev/null || true
echo ""
echo "现在可以构建 Docker 镜像了:"
echo "  docker build -t vidaimock:local ."
