#!/bin/bash

CONFIG_FILE="/etc/V2bX/sing_origin.json"
BACKUP_FILE="/etc/V2bX/sing_origin.json.bak"

# 备份原始配置文件
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "已备份配置文件到 $BACKUP_FILE"
else
    echo "配置文件不存在，请检查路径是否正确：$CONFIG_FILE"
    exit 1
fi

# 修改配置文件
jq '.dns.fakeip = {"enabled": true}' "$CONFIG_FILE" | \
jq '(.route.rules |= . + [{"ip_cidr": ["198.18.0.0/16", "fc00::/18"], "outbound": "direct"}]) | .route.rules |= map(if .outbound == "direct" and .network == ["udp", "tcp"] then . else . end)' > "${CONFIG_FILE}.tmp"

if [ $? -ne 0 ]; then
    echo "配置文件修改失败，请手动检查。"
    exit 1
fi

# 替换原始配置文件
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# 重启 V2bX 服务
v2bx restart

if [ $? -eq 0 ]; then
    echo "配置文件修改成功，并已重启 V2bX 服务。"
else
    echo "配置修改成功，但服务重启失败，请手动检查服务状态。"
fi
