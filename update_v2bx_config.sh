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
jq '
(
    # 添加 fakeip 配置
    .dns.fakeip = {
        "enabled": true,
        "inet4_range": "198.18.0.0/16",
        "inet6_range": "fc00::/18"
    }
    |
    # 在指定位置插入新的规则
    .route.rules |= (
        . as $rules | reduce range(0; length) as $i (
            []; . + 
            if $rules[$i] | .outbound == "block" and .domain_regex then 
                [$rules[$i], 
                 {
                     "ip_cidr": ["198.18.0.0/16", "fc00::/18"],
                     "outbound": "direct"
                 }]
            else 
                [$rules[$i]] 
            end
        )
    )
)' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"

# 检查修改是否成功
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
