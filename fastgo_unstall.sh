#!/bin/bash

# 脚本出错时立即退出
set -e

# 定义变量
INSTALL_DIR="/ziziweb"
SERVICE_NAME="fastgo"
SERVICE_FILE_DEST="/etc/systemd/system/${SERVICE_NAME}.service"
PROGRAM_DIR="${INSTALL_DIR}/${SERVICE_NAME}"
TAR_FILE_PATH="${INSTALL_DIR}/fastgo.tar.gz"

echo "开始卸载 ${SERVICE_NAME}..."

# 停止并禁用服务
echo "正在停止并禁用 ${SERVICE_NAME} 服务..."
if systemctl list-units --full -all | grep -Fq "${SERVICE_NAME}.service"; then
    systemctl stop "${SERVICE_NAME}.service" || echo "服务 ${SERVICE_NAME} 未运行或停止失败，继续卸载。"
    systemctl disable "${SERVICE_NAME}.service" || echo "服务 ${SERVICE_NAME} 未启用或禁用失败，继续卸载。"
else
    echo "服务 ${SERVICE_NAME} 未找到，可能已被卸载。"
fi
echo "服务停止并禁用完成（如果存在）。"

# 删除服务文件
if [ -f "${SERVICE_FILE_DEST}" ]; then
    echo "正在删除服务文件 ${SERVICE_FILE_DEST}..."
    rm -f "${SERVICE_FILE_DEST}"
    echo "服务文件删除完成。"

    # 刷新 systemd
    echo "正在刷新 systemd 配置..."
    systemctl daemon-reload
    echo "systemd 配置刷新完成。"
else
    echo "服务文件 ${SERVICE_FILE_DEST} 未找到，跳过删除。"
fi

# 删除程序目录
if [ -d "${PROGRAM_DIR}" ]; then
    echo "正在删除程序目录 ${PROGRAM_DIR}..."
    rm -rf "${PROGRAM_DIR}"
    echo "程序目录删除完成。"
else
    echo "程序目录 ${PROGRAM_DIR} 未找到，跳过删除。"
fi

# 删除压缩包文件
if [ -f "${TAR_FILE_PATH}" ]; then
    echo "正在删除压缩包文件 ${TAR_FILE_PATH}..."
    rm -f "${TAR_FILE_PATH}"
    echo "压缩包文件删除完成。"
else
    echo "压缩包文件 ${TAR_FILE_PATH} 未找到，跳过删除。"
fi

# 尝试删除 ziziweb 目录，如果为空
if [ -d "${INSTALL_DIR}" ] && [ -z "$(ls -A ${INSTALL_DIR})" ]; then
    echo "正在删除空的安装目录 ${INSTALL_DIR}..."
    rmdir "${INSTALL_DIR}"
    echo "安装目录 ${INSTALL_DIR} 删除完成。"
elif [ -d "${INSTALL_DIR}" ]; then
    echo "安装目录 ${INSTALL_DIR} 不为空，未删除。"
else
    echo "安装目录 ${INSTALL_DIR} 未找到。"
fi

echo "${SERVICE_NAME} 卸载完成！"

exit 0
