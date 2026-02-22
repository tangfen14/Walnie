# iOS 双机安装验证（云端同步）

本文用于首批 2 人 iOS 安装验证版交付，目标是:
- 两台 iPhone 都能安装并启动
- 使用同一个云端后端同步数据
- 通过基础功能和稳定性验收

## 1. 前置条件

- macOS + Xcode + Flutter 环境可用
- 已连接至少一台真机并可在 Xcode 看到设备
- 后端健康检查可用（当前默认: `http://47.100.221.135:8080`）

## 2. 一键预检

在项目根目录执行:

```bash
./scripts/ios_preflight.sh
```

该脚本会依次执行:
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test`

## 3. 检查后端健康

```bash
./scripts/check_backend_health.sh
```

可传入自定义后端地址:

```bash
./scripts/check_backend_health.sh http://your-host:8080
```

## 4. 构建 iOS Release（固定云端地址）

```bash
./scripts/build_ios_release_cloud.sh
```

默认 `EVENT_API_BASE_URL`:
- `http://47.100.221.135:8080`

可覆盖:

```bash
./scripts/build_ios_release_cloud.sh https://your-domain
```

构建产物:
- `build/ios/iphoneos/Runner.app`

## 5. 安装到两台真机

推荐直接按以下勾选清单执行：
- `docs/ios-xcode-install-checklist.md`

也可直接使用一键脚本（自动切签名 + 安装）：

```bash
# 安装到 cc 账号
./scripts/ios_deploy_with_signing.sh --account cc --device <DEVICE_ID>

# 安装到 wang 账号
./scripts/ios_deploy_with_signing.sh --account wang --device <DEVICE_ID>
```

1. 打开 `ios/Runner.xcworkspace`
2. 选择 `Runner` target
3. 在 `Signing & Capabilities` 中选择个人 Apple ID Team
4. 确认 Bundle Identifier 唯一（当前: `com.wang.babyTracker`）
5. 选择设备后点击 Run 安装到第 1 台手机
6. 切换设备后重复同样操作安装第 2 台手机
7. 两台手机在系统设置中完成开发者证书信任

## 6. 双机验收清单

- 应用可以正常启动并进入首页
- 手动新增事件成功写入云端
- A 机新增事件后，B 机刷新可见同一记录
- 语音录入可请求权限并正常记录
- 通知权限可请求并完成配置
- 后端断开时，应用不崩溃且有可理解失败反馈

## 7. 运维提醒（免费签名）

- 免费 Apple ID 签名有有效期限制（通常约 7 天）
- 到期后需要重新通过 Xcode 安装
- 建议建立重复提醒，避免内测中断

保留后端健康检查命令:

```bash
curl http://47.100.221.135:8080/health
```

## 8. 下一阶段（TestFlight）

当开通 Apple Developer Program 后:
- 在 App Store Connect 创建 App 并绑定 Bundle ID
- 后端切换为域名 + HTTPS
- Flutter 构建时改为 `https://<your-domain>`
- 清理 iOS ATS 中对 HTTP 的例外配置
- 上传构建并邀请测试员通过 TestFlight 下载
