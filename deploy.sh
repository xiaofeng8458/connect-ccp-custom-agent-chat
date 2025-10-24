#!/bin/bash

# 配置变量
BUCKET_NAME="connect-ccp-chat-$(date +%s)"
REGION="us-east-1"
DISTRIBUTION_NAME="connect-ccp-distribution"

echo "开始部署 Amazon Connect CCP 自定义聊天界面..."

# 1. 创建S3存储桶
echo "创建S3存储桶: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# 2. 配置存储桶为静态网站托管
echo "配置静态网站托管..."
aws s3 website s3://$BUCKET_NAME --index-document ChatDemo.html

# 3. 设置存储桶策略（公共读取）
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# 4. 上传文件到S3
echo "上传文件到S3..."
aws s3 sync . s3://$BUCKET_NAME --exclude "*.sh" --exclude "*.json" --exclude "*.md" --exclude ".git/*"

# 5. 创建CloudFront分发
echo "创建CloudFront分发..."
cat > cloudfront-config.json << EOF
{
    "CallerReference": "connect-ccp-$(date +%s)",
    "Comment": "Amazon Connect CCP Custom Agent Chat Distribution",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            },
            "Headers": {
                "Quantity": 3,
                "Items": [
                    "Origin",
                    "Access-Control-Request-Method",
                    "Access-Control-Request-Headers"
                ]
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "Compress": true
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                }
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_All",
    "DefaultRootObject": "ChatDemo.html"
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)

echo "CloudFront分发创建成功，ID: $DISTRIBUTION_ID"
echo "等待分发部署完成..."

# 6. 等待分发部署完成
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID

# 7. 获取分发域名
DOMAIN_NAME=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)

echo "部署完成！"
echo "S3存储桶: $BUCKET_NAME"
echo "CloudFront分发ID: $DISTRIBUTION_ID"
echo "访问地址: https://$DOMAIN_NAME"
echo ""
echo "请更新ChatDemo.html中的instanceURL配置，然后重新上传："
echo "aws s3 cp ChatDemo.html s3://$BUCKET_NAME/"
echo "aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"

# 清理临时文件
rm -f bucket-policy.json cloudfront-config.json