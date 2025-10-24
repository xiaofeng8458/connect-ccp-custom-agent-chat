# Amazon Connect CCP 自定义聊天界面

这是一个基于 Amazon Connect 的自定义代理聊天界面，提供现代化的用户体验和多会话支持。

#### 界面截图
<img width="1677" height="885" alt="Image" src="https://github.com/user-attachments/assets/ba756333-5e45-441b-a892-23902a32a704" />

## 项目特性

- 🎯 **单页应用**: 纯 JavaScript/HTML/CSS，无需构建过程
- 💬 **多会话支持**: 同时处理多个客户聊天
- 🎨 **现代化界面**: 基于 Bootstrap 5 的响应式设计
- 🔊 **音频通知**: 新消息提醒功能
- 🌐 **中文界面**: 完整的中文本地化

## 快速开始

### 本地开发

```bash
# 方式1: 直接打开
open ChatDemo.html

# 方式2: Python 服务器
python3 -m http.server 8000
# 访问: http://localhost:8000/ChatDemo.html

# 方式3: Node.js 服务器
npx http-server -p 8000
```

## CloudFront 部署方案

### 自动部署

```bash
# 1. 设置执行权限
chmod +x deploy.sh update-config.sh

# 2. 执行自动部署
./deploy.sh

# 3. 更新配置
./update-config.sh
```

### 手动部署步骤

#### 1. 创建 S3 存储桶

```bash
BUCKET_NAME="connect-ccp-chat-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region us-east-1
aws s3 website s3://$BUCKET_NAME --index-document ChatDemo.html
```

#### 2. 配置存储桶策略

```bash
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }]
}
EOF

aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json
```

#### 3. 上传文件

```bash
aws s3 sync . s3://$BUCKET_NAME --exclude "*.sh" --exclude "*.json" --exclude "*.md"
```

#### 4. 创建 CloudFront 分发

```bash
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

#### 5. 更新配置文件

更新 `ChatDemo.html` 中的配置：

```javascript
// 第300行左右
const instanceURL = "https://your-instance.my.connect.aws/";

// 第345行左右
ringtoneUrl: "https://your-cloudfront-domain.cloudfront.net/ringtone.mp3"
```

#### 6. 重新部署

```bash
aws s3 cp ChatDemo.html s3://$BUCKET_NAME/
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Amazon Connect 配置

### 1. CORS 设置

在 Amazon Connect 控制台 > 应用程序集成中添加：

```
https://your-cloudfront-domain.cloudfront.net
```

### 2. 必需配置

- ✅ 启用聊天功能
- ✅ 创建代理账户
- ✅ 配置路由规则
- ✅ 设置队列和联系流

## 项目结构

```
├── ChatDemo.html                    # 主应用文件 (48KB)
├── amazon-connect-chat-interface.js # 聊天接口库 (1.1MB)
├── ringtone.mp3                     # 音频通知文件
├── deploy.sh                        # 自动部署脚本
├── update-config.sh                 # 配置更新脚本
└── cors-setup.md                    # CORS配置指南
```

## 核心功能

### 联系人管理
- `AcceptContact()` - 接受聊天
- `RejectContact()` - 拒绝聊天
- `EndContact()` - 结束聊天
- `selectParticipant()` - 切换会话

### 消息处理
- `sendChatMessage()` - 发送消息
- `addChatMessage()` - 显示消息
- `loadChatMessages()` - 加载历史消息

### 代理操作
- `SetAgentState()` - 更改状态
- `TransferChat()` - 转接聊天
- `Logout()` - 退出登录

## 技术要求

- 现代浏览器 (支持 ES6+)
- Amazon Connect 实例
- 有效的代理账户
- HTTPS 协议

## 常见问题

### CORS 错误
确保 CloudFront 域名已添加到 Connect 应用程序集成中。

### 音频无法播放
检查 `ringtone.mp3` 文件路径和 CloudFront 配置。

### 连接失败
验证 Connect 实例 URL 和代理账户配置。

## 监控命令

```bash
# 查看分发状态
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# 查看存储桶内容
aws s3 ls s3://YOUR_BUCKET_NAME

# 清除缓存
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## 许可证

MIT License

