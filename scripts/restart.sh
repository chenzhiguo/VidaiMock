#!/bin/bash

# Configuration
PORT=8100
BINARY_NAME="vidaimock"
LOG_FILE="vidaimock.log"

echo "========================================="
echo "   VidaiMock 重启/启动 脚本管理工具        "
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
    echo "[SUCCESS] 已成功停止原进程。"
else
    echo "[INFO] 未检测到正在运行的进程，将执行纯启动。"
fi

# 2. 清理 macOS 自动生成的隐藏 .DS_Store 文件以防止 UTF-8 编码解析错误
if [ -d "config" ]; then
    echo "[INFO] 正在清理 config 目录下的隐藏 .DS_Store 文件..."
    find config -name ".DS_Store" -delete 2>/dev/null
fi

# 3. 启动应用
if [ -f "./${BINARY_NAME}" ]; then
    echo "[INFO] 正在后台启动 ${BINARY_NAME}..."
    nohup ./${BINARY_NAME} > ${LOG_FILE} 2>&1 &
    
    # 获取后台启动进程的 PID
    NEW_PID=$!
    
    # 稍等 2 秒，检查进程是否持续存活（防止启动即闪退）
    sleep 2
    if kill -0 ${NEW_PID} 2>/dev/null; then
        echo "[SUCCESS] ${BINARY_NAME} 启动成功！"
        echo "[SUCCESS] 新进程 PID: ${NEW_PID}"
        echo "[SUCCESS] 服务运行于: http://127.0.0.1:${PORT}"
        echo "[SUCCESS] 日志文件: ${LOG_FILE}"
    else
        echo "[ERROR] ${BINARY_NAME} 启动失败！请检查日志 ${LOG_FILE} 查看原因。"
        if [ -f "${LOG_FILE}" ]; then
            echo "--- 日志末尾 5 行 ---"
            tail -n 5 ${LOG_FILE}
            echo "---------------------"
        fi
    fi
else
    echo "[ERROR] 未在当前目录下找到二进制文件 '${BINARY_NAME}'，请确认路径是否正确。"
    exit 1
fi
echo "========================================="
