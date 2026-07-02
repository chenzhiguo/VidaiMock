#!/usr/bin/env bash
#
# VidaiMock — 生成类似官方 Release 的离线二进制包
#
# 打包内容与官方 Release 一致：
#   - 二进制文件
#   - config/ (providers + templates)
#   - examples/
#   - README.md / LICENSE / CHANGELOG.md
#
# 用法：
#   ./scripts/release-binaries.sh [TARGET...]
#
# TARGET: linux-x64 / linux-arm64 / macos-x64 / macos-arm64 / windows-x64 / all
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

cd "$ROOT_DIR"

# 将平台名称映射为参数，用 case 兼容 macOS bash 3.2
resolve_target() {
  case "$1" in
    linux-x64)
      RUST_TARGET="x86_64-unknown-linux-gnu"
      ARCHIVE_EXT="tar.gz"
      USE_CROSS=true
      ;;
    linux-arm64)
      RUST_TARGET="aarch64-unknown-linux-gnu"
      ARCHIVE_EXT="tar.gz"
      USE_CROSS=true
      ;;
    macos-x64)
      RUST_TARGET="x86_64-apple-darwin"
      ARCHIVE_EXT="tar.gz"
      USE_CROSS=false
      ;;
    macos-arm64)
      RUST_TARGET="aarch64-apple-darwin"
      ARCHIVE_EXT="tar.gz"
      USE_CROSS=false
      ;;
    windows-x64)
      RUST_TARGET="x86_64-pc-windows-msvc"
      ARCHIVE_EXT="zip"
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
if [ $# -eq 0 ] || [ "${1:-}" = "all" ]; then
  TARGETS=("linux-x64" "linux-arm64" "macos-x64" "macos-arm64" "windows-x64")
  echo "==> 编译所有平台"
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

# 确保 dist 目录存在
mkdir -p "$DIST_DIR"

# 编译并打包每个目标
for NAME in "${TARGETS[@]}"; do
  # 解析目标平台参数
  RUST_TARGET=""
  ARCHIVE_EXT=""
  USE_CROSS=false
  if ! resolve_target "$NAME"; then
    continue
  fi

  echo ""
  echo "==> 编译与打包: $NAME"
  echo "    Target: $RUST_TARGET"

  # 编译
  if $USE_CROSS; then
    cross build --release --target "$RUST_TARGET"
  else
    cargo build --release --target "$RUST_TARGET"
  fi

  # 确定二进制文件名
  if [[ "$NAME" == windows-* ]]; then
    BIN_FILENAME="vidaimock.exe"
  else
    BIN_FILENAME="vidaimock"
  fi

  # 创建打包目录结构（与官方一致）
  PKG_DIR="$DIST_DIR/vidaimock-pkg-$NAME"
  rm -rf "$PKG_DIR"
  mkdir -p "$PKG_DIR"

  # 复制二进制
  cp "target/$RUST_TARGET/release/$BIN_FILENAME" "$PKG_DIR/"
  chmod +x "$PKG_DIR/$BIN_FILENAME"

  # 复制配置和示例
  cp -r config "$PKG_DIR/"
  cp -r examples "$PKG_DIR/"

  # 复制文档
  cp README.md "$PKG_DIR/"
  cp LICENSE "$PKG_DIR/"
  cp CHANGELOG.md "$PKG_DIR/"

  # 创建压缩包
  ARCHIVE_NAME="vidaimock-$NAME"
  cd "$DIST_DIR"
  if [[ "$NAME" == windows-* ]]; then
    if command -v zip &>/dev/null; then
      zip -rq "${ARCHIVE_NAME}.zip" "vidaimock-pkg-$NAME/"
    else
      echo "⚠️  zip 命令不可用，改用 tar.gz"
      tar -czf "${ARCHIVE_NAME}.tar.gz" "vidaimock-pkg-$NAME"
    fi
  else
    # 打包时把目录内的内容打包成 vidaimock/ 开头（与官方结构一致）
    mv "vidaimock-pkg-$NAME" "vidaimock"
    tar -czf "${ARCHIVE_NAME}.tar.gz" vidaimock
    mv "vidaimock" "vidaimock-pkg-$NAME"
  fi
  cd "$ROOT_DIR"

  # 清理临时打包目录
  rm -rf "$PKG_DIR"

  echo "    输出: $DIST_DIR/${ARCHIVE_NAME}.${ARCHIVE_EXT}"
done

echo ""
echo "✅ 打包完成！"
echo ""
echo "dist/ 目录内容:"
ls -lh "$DIST_DIR/" 2>/dev/null | grep -E "vidaimock-" || true
echo ""
echo "每个压缩包包含（与官方 Release 一致）:"
echo "  - vidaimock (二进制)"
echo "  - config/ (providers + templates)"
echo "  - examples/ (示例配置)"
echo "  - README.md / LICENSE / CHANGELOG.md"
echo ""
