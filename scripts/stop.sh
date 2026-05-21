#!/bin/bash

# Configuration
PORT=8100
BINARY_NAME="vidaimock"

echo "========================================="
echo "   VidaiMock 停止服务 脚本管理工具        "
echo "========================================="

# 1. 检测进程是否正在运行（优先通过端口，其次通过二进制名称）
PID=$(lsof -t -i:${PORT} 2>/dev/null)
if [ -z "$PID" ]; then
    PID=$(pgrep -x "${BINARY_NAME}" 2>/dev/null)
fi

if [ -n "$PID" ]; then
    echo "[INFO] 检测到应用正在运行 (PID: $PID)，正在停止该进程..."
    kill $PID
    
    # 等待最多 5 秒让进程优雅退出
    for i in {1..5}; do
        if ! kill -0 $PID 2>/dev/null; then
            break
        fi
        sleep 1
    done
    
    # 如果进程依然存在，则进行强制结束
    if kill -0 $PID 2>/dev/null; then
        echo "[WARNING] 进程未响应，正在强制结束 (kill -9)..."
        kill -9 $PID
    fi
    echo "[SUCCESS] 已成功停止 VidaiMock 服务。"
else
    echo "[INFO] 未检测到正在运行的 VidaiMock 进程，无需操作。"
fi
echo "========================================="
