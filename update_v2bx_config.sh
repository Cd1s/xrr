#!/bin/bash

# 定义配置文件路径
CONFIG_FILE="/etc/V2bX/sing_origin.json"

# 检查文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 备份原始配置文件
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
echo "已备份配置文件到 ${CONFIG_FILE}.bak"

# 添加 "fakeip" 到 "dns"
sed -i '/"dns": {/a\        "fakeip": {\n          "enabled": true\n        },' "$CONFIG_FILE"

# 添加 IP CIDR 规则
sed -i '/"outbound": "direct",/i\        {\n          "ip_cidr": ["198.18.0.0/16", "fc00::/18"],\n          "outbound": "direct"\n        },' "$CONFIG_FILE"

# 检查修改是否成功
if grep -q '"fakeip": {' "$CONFIG_FILE" && grep -q '"ip_cidr": ["198.18.0.0/16", "fc00::/18"]' "$CONFIG_FILE"; then
    echo "配置文件修改完成。"
else
    echo "配置文件修改失败，请手动检查。"
    exit 1
fi

# 重启 V2bX 服务
if systemctl restart V2bX; then
    echo "V2bX 服务已成功重启。"
else
    echo "V2bX 服务重启失败，请检查服务状态。"
fi
