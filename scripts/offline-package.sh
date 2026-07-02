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
# 步骤：
#   1. 用 docker/Dockerfile.from-release 从文件夹构建镜像
#   2. 导出镜像 + 配置文件
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

# ---- 步骤 1：构建 Docker 镜像 ----
echo "==> [1/4] 从官方预编译文件夹构建 Docker 镜像: $IMAGE_FULL"
echo "    来源: $RELEASE_DIR/vidaimock"

# 为不同架构选择不同的 Dockerfile
if [ "$RELEASE_TARGET" = "linux-arm64" ]; then
  # 为 ARM64 做一个临时的 Dockerfile
  cat > "$DIST_DIR/Dockerfile.tmp" << 'EOF'
FROM --platform=linux/arm64 gcr.io/distroless/cc-debian12:nonroot
COPY --chown=nonroot:nonroot release/vidaimock-linux-arm64 /vidaimock/
WORKDIR /vidaimock
EXPOSE 8100
ENTRYPOINT ["/vidaimock/vidaimock"]
CMD ["--host", "0.0.0.0", "--port", "8100"]
EOF
  mkdir -p "$DIST_DIR"
  docker build -t "$IMAGE_FULL" -f "$DIST_DIR/Dockerfile.tmp" .
  rm -f "$DIST_DIR/Dockerfile.tmp"
else
  docker build -t "$IMAGE_FULL" -f docker/Dockerfile.from-release .
fi

# ---- 步骤 2：准备打包目录 ----
echo ""
echo "==> [2/4] 准备打包目录"
mkdir -p "$DIST_DIR/package"

echo "    导出 Docker 镜像..."
docker save -o "$DIST_DIR/package/vidaimock-${IMAGE_TAG}.tar" "$IMAGE_FULL"

# 复制 docker-compose 配置
cp "$ROOT_DIR/docker/docker-compose.yml" "$DIST_DIR/package/"
if [ -f "$ROOT_DIR/docker/docker-compose.local.yml" ]; then
  cp "$ROOT_DIR/docker/docker-compose.local.yml" "$DIST_DIR/package/"
fi

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
if [ -f docker-compose.local.yml ]; then
  VIDAIMOCK_VERSION="$IMAGE_TAG" docker compose -f docker-compose.local.yml up -d
else
  VIDAIMOCK_VERSION="$IMAGE_TAG" docker compose up -d
fi

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
构建来源: 官方预编译文件夹 ($RELEASE_TARGET)

文件列表:
  vidaimock-${IMAGE_TAG}.tar    Docker 镜像文件
  docker-compose.yml            Docker Compose 配置
  docker-compose.local.yml      本地构建配置（可选）
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


自定义配置:
--------------------------------------------------------------------------------
如需覆盖配置，创建 overrides 目录并放入配置文件：

  mkdir -p overrides/providers
  mkdir -p overrides/templates
  # 放入你的自定义配置...

  然后重启服务:
  docker compose restart

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
