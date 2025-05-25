#!/bin/bash

# 脚本出错时立即退出
set -e

# 定义变量
DOWNLOAD_URL="https://raw.githubusercontent.com/xixfifus/ziziweb/main/fastgo.tar.gz"
INSTALL_DIR="/ziziweb"
TAR_FILE="fastgo.tar.gz"
SERVICE_NAME="fastgo"
BIN_PATH="${INSTALL_DIR}/${SERVICE_NAME}/bin/${SERVICE_NAME}"
SERVICE_FILE_SOURCE="${INSTALL_DIR}/${SERVICE_NAME}/bin/${SERVICE_NAME}.service"
SERVICE_FILE_DEST="/etc/systemd/system/${SERVICE_NAME}.service"

echo "开始安装 ${SERVICE_NAME}..."

# 1. 下载
echo "正在下载 ${TAR_FILE}..."
if command -v curl &> /dev/null; then
    curl -L -o "${TAR_FILE}" "${DOWNLOAD_URL}"
elif command -v wget &> /dev/null; then
    wget -O "${TAR_FILE}" "${DOWNLOAD_URL}"
else
    echo "错误：未找到 curl 或 wget。请先安装其中一个。"
    exit 1
fi
echo "下载完成。"

# 2. 在根目录新建 ziziweb 目录
echo "正在创建目录 ${INSTALL_DIR}..."
if [ -d "${INSTALL_DIR}" ]; then
    echo "目录 ${INSTALL_DIR} 已存在。"
else
    mkdir -p "${INSTALL_DIR}"
    echo "目录 ${INSTALL_DIR} 创建成功。"
fi

# 3. 将 fastgo.tar.gz 移动到 /ziziweb
echo "正在移动 ${TAR_FILE} 到 ${INSTALL_DIR}..."
mv "${TAR_FILE}" "${INSTALL_DIR}/"
echo "${TAR_FILE} 移动完成。"

# 4. 进入 ziziweb 目录并解压 fastgo.tar.gz
echo "正在进入目录 ${INSTALL_DIR} 并解压 ${TAR_FILE}..."
cd "${INSTALL_DIR}"
tar -xzvf "${TAR_FILE}"
echo "解压完成。"

# 5. 设置权限
echo "正在设置权限 ${BIN_PATH}..."
chmod +x "${BIN_PATH}"
echo "权限设置完成。"

# 6. 移动 fastgo.service 到 /etc/systemd/system/
echo "正在移动服务文件 ${SERVICE_FILE_SOURCE} 到 ${SERVICE_FILE_DEST}..."
mv "${SERVICE_FILE_SOURCE}" "${SERVICE_FILE_DEST}"
echo "服务文件移动完成。"

# 7. 执行刷新并启动
echo "正在刷新 systemd 并启动 ${SERVICE_NAME} 服务..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
systemctl start "${SERVICE_NAME}.service"

echo "${SERVICE_NAME} 安装并启动成功！"

exit 0
