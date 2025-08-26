#!/bin/bash

# 部署脚本 - 将Vue应用部署到Nginx服务器
# 使用方法: ./deploy.sh [服务器IP] [用户名] [目标路径]

# 检查参数
if [ $# -lt 3 ]; then
    echo "使用方法: $0 <服务器IP> <用户名> <目标路径>"
    echo "示例: $0 192.168.1.100 ubuntu /var/www/aquaguardian"
    exit 1
fi

SERVER_IP=$1
USERNAME=$2
TARGET_PATH=$3

echo "开始部署到服务器: $SERVER_IP"
echo "目标路径: $TARGET_PATH"

# 1. 构建生产版本
echo "构建生产版本..."
npm run build

if [ $? -ne 0 ]; then
    echo "构建失败，退出部署"
    exit 1
fi

echo "构建完成"

# 2. 创建远程目录
echo "创建远程目录..."
ssh $USERNAME@$SERVER_IP "sudo mkdir -p $TARGET_PATH && sudo chown $USERNAME:$USERNAME $TARGET_PATH"

# 3. 上传文件
echo "上传文件到服务器..."
scp -r dist/* $USERNAME@$SERVER_IP:$TARGET_PATH/

if [ $? -ne 0 ]; then
    echo "文件上传失败"
    exit 1
fi

# 4. 设置权限
echo "设置文件权限..."
ssh $USERNAME@$SERVER_IP "sudo chown -R www-data:www-data $TARGET_PATH && sudo chmod -R 755 $TARGET_PATH"

# 5. 重启Nginx
echo "重启Nginx服务..."
ssh $USERNAME@$SERVER_IP "sudo systemctl reload nginx"

echo "部署完成！"
echo "请确保Nginx配置正确，并访问您的网站" 