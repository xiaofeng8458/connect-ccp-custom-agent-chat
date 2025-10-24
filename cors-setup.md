# Amazon Connect CORS配置指南

## 1. 登录Amazon Connect控制台

访问 AWS Console > Amazon Connect > 选择您的实例

## 2. 配置应用程序集成

1. 在左侧导航栏选择 **应用程序集成**
2. 点击 **添加源**
3. 添加以下域名：

### 必需的域名配置：
```
https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net
https://d1234567890.cloudfront.net  # 替换为实际的CloudFront域名
```

### 可选的本地开发域名：
```
http://localhost:8000
http://127.0.0.1:8000
file://
```

## 3. 验证配置

确保以下设置正确：
- ✅ 启用了聊天功能
- ✅ CCP URL已配置
- ✅ 代理账户已创建
- ✅ 路由配置已设置

## 4. 测试连接

部署完成后，访问 `https://YOUR_CLOUDFRONT_DOMAIN.cloudfront.net` 进行测试。

## 常见问题

### CORS错误
如果遇到CORS错误，检查：
1. CloudFront域名是否已添加到Connect应用程序集成
2. 域名格式是否正确（包含https://）
3. 是否有多余的斜杠或路径

### 音频文件无法播放
确保ringtone.mp3文件已正确上传到S3，并且CloudFront可以访问。