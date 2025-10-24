#!/bin/bash

# 更新配置脚本
echo "请输入您的Amazon Connect实例URL (例如: https://your-instance.my.connect.aws/):"
read CONNECT_URL

echo "请输入CloudFront域名 (例如: d1234567890.cloudfront.net):"
read CLOUDFRONT_DOMAIN

# 备份原文件
cp ChatDemo.html ChatDemo.html.backup

# 更新ChatDemo.html中的配置
sed -i.tmp "s|https://connect-us-1.my.connect.aws/|$CONNECT_URL|g" ChatDemo.html
sed -i.tmp "s|http://127.0.0.1:54093/agent-chat-demo-customized/|https://$CLOUDFRONT_DOMAIN/|g" ChatDemo.html

echo "配置已更新："
echo "- Connect实例URL: $CONNECT_URL"
echo "- 音频文件路径: https://$CLOUDFRONT_DOMAIN/ringtone.mp3"

# 清理临时文件
rm -f ChatDemo.html.tmp

echo "请运行以下命令重新部署："
echo "aws s3 cp ChatDemo.html s3://YOUR_BUCKET_NAME/"
echo "aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths '/*'"