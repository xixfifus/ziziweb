#!/bin/bash

# 检查参数个数
if [ "$#" -ne 5 ]; then
    echo "用法: $0 <ss_port> <ss_passwd> <vless_port> <vless_id> <vless_path>"
    echo "例如: $0 111 '1111==' 1111 '111-111-111-111' '111-111-111-111'"
    exit 1
fi

# 分配参数给变量
ss_port_val="$1"
ss_passwd_val="$2"
vless_port_val="$3"
vless_id_val="$4"
vless_path_val="$5"

# 定义拆分配置文件的目录
config_parts_dir="/ziziweb/fastgo/config"
# 创建目录 (如果不存在)
mkdir -p "$config_parts_dir"

# 获取本机公网IP
localip=$(curl -s https://ipinfo.io/ip)
if [ -z "$localip" ]; then
    echo "错误：无法获取公网IP地址。"
    # 考虑是否在此处退出，或者使用一个默认/回退IP
    # localip="127.0.0.1" # 示例回退
fi

# 1. 生成 log.json
cat << EOF > "$config_parts_dir/log.json"
{
  "log": {
    "access": "/ziziweb/fastgo/log/access.log",
    "error": "/ziziweb/fastgo/log/error.log",
    "loglevel": "warning"
  }
}
EOF

# 2. 生成 inbounds.json
cat << EOF > "$config_parts_dir/inbounds.json"
{
  "inbounds": [
    {
      "tag": "$ss_port_val",
      "port": $ss_port_val,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-128-gcm",
        "password": "$ss_passwd_val",
        "network": "tcp,udp"
      }
    },
    {
      "tag": "$vless_port_val",
      "port": $vless_port_val,
      "listen": "127.0.0.1",
      "protocol": "VLESS",
      "settings": {
        "clients": [
          {
            "id": "$vless_id_val",
            "alterId": 0
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$vless_path_val"
        }
      }
    }
  ]
}
EOF

# 3. 生成 outbounds.json
cat << EOF > "$config_parts_dir/outbounds.json"
{
  "outbounds": [
    {
      "tag": "$vless_port_val",
      "protocol": "freedom",
      "sendThrough": "$localip",
      "settings": {}
    }
  ]
}
EOF

# 4. 生成 routing.json
cat << EOF > "$config_parts_dir/routing.json"
{
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "inboundTag": ["$vless_port_val"],
        "outboundTag": "$vless_port_val",
        "type": "field"
      },
      {
        "inboundTag": ["$ss_port_val"],
        "outboundTag": "$vless_port_val",
        "type": "field"
      }
    ]
  }
}
EOF

# 5. 生成 dns.json
cat << EOF > "$config_parts_dir/dns.json"
{
  "dns": {
    "servers": [
      "https+local://1.1.1.1/dns-query",
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8",
      "8.8.4.4",
      "localhost",
      "2001:4860:4860::8888",
      "2001:4860:4860::8844"
    ]
  }
}
EOF

echo "拆分的配置文件已生成到 $config_parts_dir"

# 7. 重启 Xray 服务
echo "正在重启 Xray 服务..."

SUDO_CMD=""
if command -v sudo &> /dev/null; then
    if sudo -n true 2>/dev/null; then
        SUDO_CMD="sudo"
        echo "检测到 sudo 可用且无需密码，将使用 sudo 执行需要提升权限的命令。"
    else
        echo "警告: sudo 命令存在但需要密码或当前用户无法无需密码执行 sudo。将尝试以当前用户权限执行需要提升权限的命令。"
    fi
else
    echo "警告: sudo 命令未找到。将尝试以当前用户权限执行需要提升权限的命令。"
fi

if [ -n "$SUDO_CMD" ]; then
    $SUDO_CMD systemctl restart xray
else
    systemctl restart xray
fi

if [ $? -eq 0 ]; then
    echo "Xray 服务已成功重启/尝试重启。"
else
    echo "警告: 重启 Xray 服务失败。返回码: $?。请检查 Xray 状态、日志以及执行权限。"
fi

# 8. 防火墙配置
echo "正在配置防火墙..."

# 禁用 ufw
echo "尝试禁用 ufw..."
if [ -n "$SUDO_CMD" ]; then
    $SUDO_CMD ufw disable
else
    ufw disable
fi
if [ $? -eq 0 ]; then
    echo "ufw 已成功禁用/尝试禁用。"
else
    echo "警告: 禁用 ufw 失败。返回码: $?。"
fi

# 停止并禁用 firewalld (如果存在)
# 使用 systemctl is-active 来检查服务是否正在运行，is-enabled 检查是否开机自启
# systemctl list-units 更通用地检查服务是否存在
if systemctl list-units --type=service --all | grep -q 'firewalld.service'; then
    echo "检测到 firewalld 服务，尝试停止并禁用..."
    if [ -n "$SUDO_CMD" ]; then
        $SUDO_CMD systemctl stop firewalld
        $SUDO_CMD systemctl disable firewalld
    else
        systemctl stop firewalld
        systemctl disable firewalld
    fi
    echo "已尝试停止并禁用 firewalld。"
else
    echo "firewalld 服务未找到或未列出 (可能未安装或已移除)。"
fi

# 9. 完成
echo "Is ok!" 
