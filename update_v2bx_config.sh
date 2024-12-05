#!/bin/bash

CONFIG_FILE="/etc/V2bX/sing_origin.json"
BACKUP_FILE="/etc/V2bX/sing_origin.json.bak"

# 备份配置文件
cp "$CONFIG_FILE" "$BACKUP_FILE"

# 添加 FakeIP 和规则
jq '."dns" |= . + {"fakeip": {"enabled": true, "inet4_range": "198.18.0.0/16", "inet6_range": "fc00::/18"}} |
    ."route"."rules" |= [{"ip_cidr": ["198.18.0.0/16", "fc00::/18"], "outbound": "direct"}] + .' \
    "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# 检查配置是否正确
if [ $? -eq 0 ]; then
    echo "配置文件修改成功，已备份为 $BACKUP_FILE"
    # 重启 V2bX 服务
    v2bx restart
    if [ $? -eq 0 ]; then
        echo "V2bX 服务已成功重启！"
    else
        echo "V2bX 服务重启失败，请检查服务状态。"
    fi
else
    echo "配置文件修改失败，请手动检查。"
    mv "$BACKUP_FILE" "$CONFIG_FILE"
    echo "已恢复原始配置文件。"
fi
