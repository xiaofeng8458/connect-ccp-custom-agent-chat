#!/bin/bash

# 配置变量
BUCKET_NAME="connect-ccp-chat-$(date +%s)"
REGION="us-east-1"
DISTRIBUTION_NAME="connect-ccp-distribution"

echo "开始安全部署 Amazon Connect CCP 自定义聊天界面..."

# 1. 创建S3存储桶
echo "创建S3存储桶: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# 2. 禁用公共访问（安全最佳实践）
echo "配置S3存储桶安全设置..."
aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 3. 创建Origin Access Control (OAC)
echo "创建Origin Access Control..."
OAC_CONFIG=$(cat << EOF
{
    "Name": "connect-ccp-oac-$(date +%s)",
    "Description": "OAC for Connect CCP Chat Interface",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "always",
    "SigningProtocol": "sigv4"
}
EOF
)

OAC_ID=$(aws cloudfront create-origin-access-control --origin-access-control-config "$OAC_CONFIG" --query 'OriginAccessControl.Id' --output text)
echo "OAC创建成功，ID: $OAC_ID"

# 4. 创建CloudFront分发配置
echo "创建CloudFront分发..."
cat > cloudfront-config.json << EOF
{
    "CallerReference": "connect-ccp-$(date +%s)",
    "Comment": "Amazon Connect CCP Custom Agent Chat Distribution with OAC",
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
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "Compress": true,
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        }
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                },
                "OriginAccessControlId": "$OAC_ID"
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100",
    "DefaultRootObject": "ChatDemo.html",
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 403,
                "ResponsePagePath": "/ChatDemo.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    }
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)
echo "CloudFront分发创建成功，ID: $DISTRIBUTION_ID"

# 5. 获取CloudFront分发ARN用于S3策略
DISTRIBUTION_ARN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.ARN' --output text)

# 6. 创建S3存储桶策略（仅允许CloudFront访问）
echo "配置S3存储桶策略..."
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "$DISTRIBUTION_ARN"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# 7. 上传文件到S3
echo "上传文件到S3..."
aws s3 sync . s3://$BUCKET_NAME --exclude "*.sh" --exclude "*.json" --exclude "*.md" --exclude ".git/*"

# 8. 等待分发部署完成
echo "等待CloudFront分发部署完成..."
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID

# 9. 获取分发域名
DOMAIN_NAME=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)

echo "安全部署完成！"
echo "S3存储桶: $BUCKET_NAME"
echo "CloudFront分发ID: $DISTRIBUTION_ID"
echo "OAC ID: $OAC_ID"
echo "访问地址: https://$DOMAIN_NAME"
echo ""
echo "安全特性："
echo "- ✅ S3存储桶禁用公共访问"
echo "- ✅ 使用Origin Access Control (OAC)"
echo "- ✅ 仅CloudFront可访问S3内容"
echo "- ✅ HTTPS强制重定向"
echo ""
echo "请更新ChatDemo.html中的instanceURL配置，然后重新上传："
echo "aws s3 cp ChatDemo.html s3://$BUCKET_NAME/"
echo "aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"

# 清理临时文件
rm -f bucket-policy.json cloudfront-config.json