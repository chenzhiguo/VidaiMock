#!/usr/bin/env bash
#
# VidaiMock — 内网离线完整打包脚本
#
# 从官方预编译的文件夹构建 Docker 镜像，完全不自己编译。
#
# 前提条件：
#   把官方预编译压缩包解压后的文件夹放在 ./release/ 目录下：
#     ./release/vidaimock-linux-x64/      (默认，用于 x86_64 架构)
#     ./release/vidaimock-linux-arm64/    (可选，用于 ARM64 架构)
#   文件夹内应包含二进制文件 vidaimock
#
# 用法：
#   ./scripts/offline-package.sh [IMAGE_TAG]
#
# 可选环境变量：
#   RELEASE_TARGET  指定使用哪个预编译文件夹：linux-x64 或 linux-arm64
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

IMAGE_TAG="${1:-local}"
IMAGE_NAME="vidaimock"
IMAGE_FULL="${IMAGE_NAME}:${IMAGE_TAG}"

RELEASE_TARGET="${RELEASE_TARGET:-linux-x64}"

cd "$ROOT_DIR"

# 校验 RELEASE_TARGET
case "$RELEASE_TARGET" in
  linux-x64)   PLATFORM="linux/amd64" ;;
  linux-arm64) PLATFORM="linux/arm64" ;;
  *)
    echo "❌ 不支持的 RELEASE_TARGET: $RELEASE_TARGET"
    echo "   可选值: linux-x64, linux-arm64"
    exit 1
    ;;
esac

# 检查官方文件夹是否存在
RELEASE_DIR="release/vidaimock-${RELEASE_TARGET}"
if [ ! -f "$RELEASE_DIR/vidaimock" ]; then
  echo "❌ 找不到官方预编译二进制: $RELEASE_DIR/vidaimock"
  echo ""
  echo "请按以下步骤操作："
  echo "  1. 创建 release/ 目录: mkdir -p release"
  echo "  2. 从 https://github.com/vidaiuk/vidaimock/releases 下载压缩包"
  echo "  3. 解压到 release/ 目录下，确保有以下文件存在："
  echo "       $RELEASE_DIR/vidaimock"
  echo ""
  echo "例如："
  echo "  mkdir -p release"
  echo "  tar -xzf vidaimock-linux-x64.tar.gz -C release/"
  echo "  # 解压后得到 release/vidaimock/，重命名为 release/vidaimock-linux-x64/"
  echo "  mv release/vidaimock release/vidaimock-linux-x64"
  exit 1
fi

mkdir -p "$DIST_DIR"

# 生成与目标架构匹配的 Dockerfile（统一流程，避免两套逻辑）
DOCKERFILE_GEN="$DIST_DIR/Dockerfile.from-release.gen"
cat > "$DOCKERFILE_GEN" << EOF
# syntax=docker/dockerfile:1.7
# 自动生成，目标: $RELEASE_TARGET ($PLATFORM)

FROM --platform=$PLATFORM busybox:stable AS fixperm
COPY release/vidaimock-${RELEASE_TARGET} /vidaimock/
RUN chmod 0755 /vidaimock/vidaimock && \\
    find /vidaimock -type d -exec chmod 0755 {} \\; && \\
    find /vidaimock -type f ! -name vidaimock -exec chmod 0644 {} \\;

FROM --platform=$PLATFORM gcr.io/distroless/cc-debian12:nonroot
COPY --from=fixperm --chown=nonroot:nonroot /vidaimock /vidaimock
WORKDIR /vidaimock
EXPOSE 8100
ENTRYPOINT ["/vidaimock/vidaimock"]
CMD ["--host", "0.0.0.0", "--port", "8100"]
EOF

# ---- 步骤 1：构建 Docker 镜像 ----
echo "==> [1/4] 从官方预编译文件夹构建 Docker 镜像: $IMAGE_FULL"
echo "    来源: $RELEASE_DIR/vidaimock"
echo "    平台: $PLATFORM"

docker build \
  -t "$IMAGE_FULL" \
  -f "$DOCKERFILE_GEN" \
  .
rm -f "$DOCKERFILE_GEN"

# ---- 步骤 2：准备打包目录 ----
echo ""
echo "==> [2/4] 准备打包目录"
mkdir -p "$DIST_DIR/package"

echo "    导出 Docker 镜像..."
docker save -o "$DIST_DIR/package/vidaimock-${IMAGE_TAG}.tar" "$IMAGE_FULL"

# 复制内网专用 compose 配置（不拉取 ghcr.io、不 build）
cp "$ROOT_DIR/docker/docker-compose.offline.yml" "$DIST_DIR/package/docker-compose.yml"

# 复制环境变量模板
if [ -f "$ROOT_DIR/docker/.env.example" ]; then
  cp "$ROOT_DIR/docker/.env.example" "$DIST_DIR/package/.env"
fi

# 创建快速启动脚本
cat > "$DIST_DIR/package/install.sh" << 'EOF'
#!/usr/bin/env bash
# VidaiMock 内网安装/启动脚本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_TAG="${1:-local}"

echo "==> 加载镜像"
docker load -i "vidaimock-${IMAGE_TAG}.tar"

echo ""
echo "==> 启动服务"
VIDAIMOCK_VERSION="$IMAGE_TAG" docker compose up -d

echo ""
echo "==> 等待服务启动..."
sleep 2

PORT="${VIDAIMOCK_PORT:-8100}"
if curl -s "http://localhost:${PORT}/health" >/dev/null 2>&1; then
  echo "✅ 服务已启动"
  echo "   访问: http://localhost:${PORT}"
  echo "   健康检查: curl http://localhost:${PORT}/health"
else
  echo "⚠️  请手动检查: curl http://localhost:${PORT}/health"
  echo "   查看日志: docker compose logs"
fi
EOF
chmod +x "$DIST_DIR/package/install.sh"

# 创建使用说明
cat > "$DIST_DIR/package/README_OFFLINE.txt" << EOF
================================================================================
  VidaiMock 内网部署包
================================================================================

版本: ${IMAGE_TAG}
打包时间: $(date)
构建来源: 官方预编译文件夹 ($RELEASE_TARGET, $PLATFORM)

文件列表:
  vidaimock-${IMAGE_TAG}.tar    Docker 镜像文件
  docker-compose.yml            Docker Compose 配置（内网专用，本地镜像）
  .env                          环境变量模板
  install.sh                    一键安装/启动脚本

快速开始:
--------------------------------------------------------------------------------
1. 加载并启动（推荐）:

   ./install.sh ${IMAGE_TAG}


2. 或者手动操作:

   # 步骤 1: 加载镜像
   docker load -i vidaimock-${IMAGE_TAG}.tar

   # 步骤 2: 启动服务
   VIDAIMOCK_VERSION=${IMAGE_TAG} docker compose up -d

   # 步骤 3: 验证
   curl http://localhost:8100/health


自定义配置（可选）:
--------------------------------------------------------------------------------
镜像内置了完整的 config/（在 /vidaimock/config）。如需覆盖某个 provider 或
template，创建 overrides 目录并放入同路径文件：

  mkdir -p overrides/providers
  mkdir -p overrides/templates
  # 放入你的自定义配置...

  然后编辑 docker-compose.yml，在 command 里加上:
    - "--config-dir"
    - "/overrides"
  之后重启: docker compose restart

详细文档请参考原项目 README.md。

================================================================================
EOF

# ---- 步骤 3：创建压缩包 ----
echo ""
echo "==> [3/4] 创建压缩包"
cd "$DIST_DIR"
PACKAGE_NAME="vidaimock-offline-${IMAGE_TAG}"
tar -czf "${PACKAGE_NAME}.tar.gz" -C package/ .
cd "$ROOT_DIR"

# 清理临时打包目录
rm -rf "$DIST_DIR/package"

# ---- 步骤 4：完成 ----
echo ""
echo "==> [4/4] 完成"
echo ""
echo "压缩包: $DIST_DIR/${PACKAGE_NAME}.tar.gz"
echo "大小: $(du -h "$DIST_DIR/${PACKAGE_NAME}.tar.gz" | cut -f1)"
echo ""
echo "========== 使用说明 =========="
echo ""
echo "1. 将压缩包传输到内网机器"
echo "2. 解压: tar -xzf ${PACKAGE_NAME}.tar.gz"
echo "3. 运行: ./install.sh ${IMAGE_TAG}"
echo ""
