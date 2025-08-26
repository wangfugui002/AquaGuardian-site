@echo off
REM 部署脚本 - 将Vue应用部署到Nginx服务器 (Windows版本)
REM 使用方法: deploy.bat [服务器IP] [用户名] [目标路径]

if "%3"=="" (
    echo 使用方法: %0 ^<服务器IP^> ^<用户名^> ^<目标路径^>
    echo 示例: %0 192.168.1.100 ubuntu /var/www/aquaguardian
    pause
    exit /b 1
)

set SERVER_IP=%1
set USERNAME=%2
set TARGET_PATH=%3

echo 开始部署到服务器: %SERVER_IP%
echo 目标路径: %TARGET_PATH%

REM 1. 构建生产版本
echo 构建生产版本...
call npm run build

if %ERRORLEVEL% neq 0 (
    echo 构建失败，退出部署
    pause
    exit /b 1
)

echo 构建完成

REM 2. 创建远程目录
echo 创建远程目录...
ssh %USERNAME%@%SERVER_IP% "sudo mkdir -p %TARGET_PATH% && sudo chown %USERNAME%:%USERNAME% %TARGET_PATH%"

REM 3. 上传文件
echo 上传文件到服务器...
scp -r dist/* %USERNAME%@%SERVER_IP%:%TARGET_PATH%/

if %ERRORLEVEL% neq 0 (
    echo 文件上传失败
    pause
    exit /b 1
)

REM 4. 设置权限
echo 设置文件权限...
ssh %USERNAME%@%SERVER_IP% "sudo chown -R www-data:www-data %TARGET_PATH% && sudo chmod -R 755 %TARGET_PATH%"

REM 5. 重启Nginx
echo 重启Nginx服务...
ssh %USERNAME%@%SERVER_IP% "sudo systemctl reload nginx"

echo 部署完成！
echo 请确保Nginx配置正确，并访问您的网站
pause 