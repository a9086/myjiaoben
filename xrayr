#!/bin/bash

# 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
  echo "错误：此脚本必须以 root 身份运行。" >&2
  exit 1
fi

# 步骤 1 & 2: 下载并自动运行安装脚本，选择选项 5
echo "正在下载并安装 XrayR..."
echo -e "5\n" | bash <(curl -Ls https://raw.githubusercontent.com/a9086/XrayR-release/master/install.sh)

# 检查 XrayR 配置文件是否存在
config_file="/etc/XrayR/config.yml"
if [ ! -f "$config_file" ]; then
    echo "错误：未找到 XrayR 配置文件 ($config_file)。安装可能失败了。"
    exit 1
fi

echo "XrayR 安装完成。"
echo "------------------------------------------"

# 步骤 3: 提示用户输入 NodeID
while true; do
  read -p "请输入您的节点 ID (NodeID): " node_id
  # 检查输入是否为纯数字
  if [[ "$node_id" =~ ^[0-9]+$ ]]; then
    break
  else
    echo "输入无效，NodeID 必须是数字。请重新输入。"
  fi
done

echo "您输入的 NodeID 是: $node_id"
echo "------------------------------------------"
echo "正在配置 config.yml 文件..."

# 步骤 4: 修改配置文件
# 使用 sed 命令直接替换文件中的内容
# -i 表示直接修改文件
# s|pattern|replacement| 是替换命令的格式，使用 | 作为分隔符以避免与 URL 中的 /冲突
sed -i "s|PanelType:.*|PanelType: NewV2board|" "$config_file"
sed -i "s|ApiHost:.*|ApiHost: https://1.12099600.xyz|" "$config_file"
sed -i "s|ApiKey:.*|ApiKey: sdfgdehsrtjrsjahjah|" "$config_file"
sed -i "s|NodeID:.*|NodeID: $node_id|" "$config_file"
sed -i "s|NodeType:.*|NodeType: Vless|" "$config_file"
sed -i "s|EnableVless:.*|EnableVless: true|" "$config_file"
sed -i "s|DisableLocalREALITYConfig:.*|DisableLocalREALITYConfig: true|" "$config_file"
sed -i "s|EnableREALITY:.*|EnableREALITY: true|" "$config_file"
# 确保 CertMode 在 ControllerConfig 下，如果不在，这个简单的替换可能不够健壮，但对于默认配置通常有效
sed -i "s|CertMode:.*|CertMode: none|" "$config_file"

echo "配置文件已更新！"
echo "------------------------------------------"

# 重启 XrayR 服务以应用新配置
echo "正在重启 XrayR 服务..."
xrayr restart

echo "XrayR 已重启。请稍后使用 'xrayr log' 命令检查日志以确认其正常运行。"
echo "脚本执行完毕。"
