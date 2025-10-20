#!/bin/bash

# --- 配置 ---
NEW_PORT=9086
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
# --- 结束配置 ---

# 1. 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
   echo "错误：此脚本必须以 root 身份运行。"
   echo "请尝试使用 'sudo ./change_ssh_port.sh' 运行"
   exit 1
fi

echo "--- SSH 端口修改脚本 (Debian 12) ---"
echo "目标端口: $NEW_PORT"
echo ""

# 2. 备份 SSH 配置文件
# 仅在备份文件不存在时才创建备份
if [ ! -f "$SSH_CONFIG_FILE.bak" ]; then
    cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.bak"
    echo " [INFO] 已备份 $SSH_CONFIG_FILE 为 $SSH_CONFIG_FILE.bak"
else
    echo " [INFO] 备份 $SSH_CONFIG_FILE.bak 已存在，跳过备份。"
fi

# 3. 修改 SSH 端口
# 使用 sed 删除所有现有的 'Port' 或 '#Port' 行（不区分大小写）
sed -i -e '/^[#\s]*Port\s\+/Id' "$SSH_CONFIG_FILE"

# 然后，在文件末尾添加新的 Port 配置
echo "" >> "$SSH_CONFIG_FILE"
echo "# 由 change_ssh_port.sh 脚本设置于 $(date)" >> "$SSH_CONFIG_FILE"
echo "Port $NEW_PORT" >> "$SSH_CONFIG_FILE"

echo " [SUCCESS] 配置文件 $SSH_CONFIG_FILE 已更新。"

# 4. (可选) 处理防火墙 (UFW)
# 检查 ufw 是否安装并处于活动状态
if command -v ufw >/dev/null && ufw status | grep -q 'Status: active'; then
    echo " [INFO] 检测到 UFW 已激活。正在开放端口 $NEW_PORT/tcp ..."
    ufw allow $NEW_PORT/tcp
    echo " [SUCCESS] UFW 规则已添加 (ufw allow $NEW_PORT/tcp)。"
else
    echo " [WARN] 未检测到 UFW 或 UFW 未激活。"
    echo " [WARN] 请手动检查防火墙设置 (如 firewalld, iptables)，确保 $NEW_PORT 端口已开放。"
fi

# 5. 重启 SSH 服务并添加安全检查
echo " [INFO] 正在重启 SSH 服务 (ssh.service)..."
systemctl restart ssh

# 6. 验证 SSH 服务状态
if systemctl is-active --quiet ssh; then
    echo " [SUCCESS] SSH 服务已成功重启。"
    echo ""
    echo "===================================================================="
    echo "            !! 重要提醒 !! "
    echo "===================================================================="
    echo " SSH 端口已修改为 $NEW_PORT。"
    echo ""
    echo " 1. 请不要关闭您当前的 SSH 会话！"
    echo " 2. 请立即打开一个新的终端窗口，使用新端口尝试连接："
    echo "    ssh your_username@your_server_ip -p $NEW_PORT"
    echo ""
    echo " 3. 确认新连接成功后，再关闭此会话。"
    echo " 4. (如果使用了 UFW) 确认成功后，您可以选择性地关闭旧的 22 端口："
    echo "    sudo ufw delete allow 22/tcp"
    echo "===================================================================="
else
    # 紧急回滚！
    echo " [ERROR] SSH 服务重启失败！"
    echo " [ERROR] 这可能意味着配置文件有误。"
    echo " [INFO] 正在立即从备份 $SSH_CONFIG_FILE.bak 恢复..."
    
    mv "$SSH_CONFIG_FILE.bak" "$SSH_CONFIG_FILE"
    
    echo " [INFO] 正在尝试使用恢复的配置重启 SSH..."
    systemctl restart ssh
    
    if systemctl is-active --quiet ssh; then
        echo " [SUCCESS] SSH 服务已成功恢复到原始配置。"
        echo " [INFO] 您的 SSH 端口未更改（仍为 22 或原始端口）。"
    else
        echo " [FATAL] 致命错误！SSH 服务无法启动，即使是恢复了备份。"
        echo " [FATAL] 请不要断开连接，并立即手动检查配置！"
        echo " [FATAL] 运行 'journalctl -xeu ssh' 和 'systemctl status ssh' 查看错误。"
    fi
fi
