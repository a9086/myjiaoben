#!/bin/bash

# ===================================================
# 3x-ui 自定义安装与配置脚本 (v2 - 修正 tty)
#
# 功能:
# 1. 自动安装 3x-ui (跳过交互)
# 2. 交互式提示用户输入新密码 (安全输入, 修正 tty)
# 3. 按指定值配置 用户名, 端口, 和 访问路径
# ===================================================

# --- 固定的配置 ---
FIXED_USERNAME="xianyu"
FIXED_PORT="19086"
FIXED_PATH="/908624991"
# --------------------


# 1. 权限检查：必须以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
   echo "错误：此脚本必须以 root 身份运行。"
   echo "请尝试使用 'sudo bash' 或 'sudo ./your_script.sh' 运行"
   exit 1
fi

# 2. 交互式获取密码
# 循环直到密码匹配且不为空
while true; do
    echo "--- 3x-ui 自定义安装 ---"
    echo "将配置以下固定值:"
    echo "  用户名: $FIXED_USERNAME"
    echo "  端  口: $FIXED_PORT"
    echo "  访问路径: $FIXED_PATH"
    echo "---------------------------"

    # -s: Silent (静默) 模式，不显示输入
    # -p: Prompt (提示)
    # 
    # 【!!! 修正点 !!!】
    # 必须从 /dev/tty (终端) 读取, 否则 read 会读取 curl 的管道 (即空)
    read -s -p "请输入您要设置的密码 (输入将被隐藏): " user_password </dev/tty
    echo "" # 换行

    # 【!!! 修正点 !!!】
    read -s -p "请再次输入密码以确认: " user_password_confirm </dev/tty
    echo "" # 换行
    echo "" # 增加空行

    # 检查密码是否为空
    if [ -z "$user_password" ]; then
        echo "错误：密码不能为空。请重试。"
        continue
    fi

    # 检查两次输入是否一致
    if [ "$user_password" == "$user_password_confirm" ]; then
        echo "[INFO] 密码确认成功。"
        break # 跳出循环
    else
        echo "错误：两次输入的密码不匹配。请重试。"
    fi
done

# 3. 开始安装
echo "[INFO] 正在开始安装 3x-ui (将自动应答 'n' 以跳过默认交互)..."
# 使用 echo 'n' 自动应答安装脚本中 "是否自定义?" 的提问
echo 'n' | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# 检查安装是否成功
if [ $? -ne 0 ]; then
    echo "[ERROR] 3x-ui 安装失败。脚本已退出。"
    exit 1
fi

echo "[INFO] 3x-ui 安装完成。正在应用自定义配置..."

# 4. 应用所有自定义配置
# 注意：密码变量 $user_password 需要加引号
/usr/local/x-ui/x-ui setting \
    -username "$FIXED_USERNAME" \
    -password "$user_password" \
    -port "$FIXED_PORT" \
    -webBasePath "$FIXED_PATH"

if [ $? -ne 0 ]; then
    echo "[ERROR] 应用 3x-ui 配置失败。脚本已退出。"
    exit 1
fi

# 5. 重启服务使配置生效
echo "[INFO] 配置已应用。正在重启 3x-ui 服务..."
systemctl restart x-ui

# 6. 最终结果
echo ""
echo "================================================="
echo "       🎉 3x-ui 安装并配置成功! 🎉"
echo "================================================="
echo "您的访问地址 (URL):"
echo "  http://<您的服务器IP>:$FIXED_PORT$FIXED_PATH"
echo ""
echo "您的登录信息:"
echo "  用户名: $FIXED_USERNAME"
echo "  密  码: (您刚才设置的密码)"
echo "================================================="
echo ""
