# VidaiMock 内网离线部署

最简单的方案：**从官方预编译压缩包构建 Docker 镜像，完全不用自己编译！**

---

## 方案 1：Docker 部署（推荐）

### 外网机器（能联网）

```bash
# 步骤 1: 创建 release/ 目录
mkdir -p release

# 步骤 2: 从 GitHub 下载官方预编译压缩包到 release/ 目录
# 下载地址：https://github.com/vidaiuk/vidaimock/releases
# 下载 vidaimock-linux-x64.tar.gz（x86_64 架构内网）或 vidaimock-linux-arm64.tar.gz（ARM64 架构内网）
# 放到 release/ 目录下

# 步骤 3: 打包 Docker 镜像
./scripts/offline-package.sh 0.2.9

# 输出: dist/vidaimock-offline-0.2.9.tar.gz
```

要构建 ARM64 版本：
```bash
RELEASE_TARGET=linux-arm64 ./scripts/offline-package.sh 0.2.9
```

### 内网机器（不能联网）

```bash
tar -xzf vidaimock-offline-0.2.9.tar.gz
cd vidaimock-offline-0.2.9
./install.sh 0.2.9
```

---

## 方案 2：直接运行官方二进制

### 外网机器（能联网）

直接从 GitHub Release 下载对应平台的压缩包，把整个压缩包传输到内网。

### 内网机器（不能联网）

```bash
# 解压官方压缩包
tar -xzf vidaimock-linux-x64.tar.gz
cd vidaimock

# 直接运行
./vidaimock
```

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `docker/Dockerfile.from-release` | 从官方压缩包构建 Docker 镜像 |
| `scripts/offline-package.sh` | 一键把官方压缩包打包成 Docker 内网部署包 |
| `scripts/build-binaries.sh` | 自己编译多平台二进制（可选，现在基本不用了） |
| `scripts/release-binaries.sh` | 自己打包类似官方 Release 的二进制包（可选，现在基本不用了） |
