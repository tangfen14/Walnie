# Walnie iOS 安装清单（Xcode 逐步勾选）

适用目标：
- 两台 iPhone 安装 Walnie 验证版
- 使用云端后端 `http://47.100.221.135:8080`
- 无 Apple Developer 付费账号（个人 Apple ID 签名）

快速路径（推荐）：

```bash
./scripts/ios_deploy_with_signing.sh --account cc --device <DEVICE_ID>
./scripts/ios_deploy_with_signing.sh --account wang --device <DEVICE_ID>
```

该脚本会自动同步 Runner/Extension 的签名与 App Group，避免手工切换遗漏。

## 0. 开始前检查

- [ ] 手机已通过数据线连接到 Mac（建议先做第 1 台）
- [ ] 手机已解锁并“信任这台电脑”
- [ ] `Xcode -> Settings -> Accounts` 已登录个人 Apple ID
- [ ] 在项目根目录执行过：

```bash
./scripts/ios_preflight.sh
./scripts/check_backend_health.sh
./scripts/build_ios_release_cloud.sh
```

## 1. 打开 iOS 工程

- [ ] 打开 `ios/Runner.xcworkspace`（不要打开 `.xcodeproj`）
- [ ] 左侧 Project Navigator 中选中 `Runner`（蓝色项目图标）
- [ ] 中间区域切到 `TARGETS -> Runner`

## 1.1 固定 Scheme 为 Release（一次性）

仓库已将共享 Scheme 默认改为 `Run = Release`，首次打开 Xcode 后仍建议人工确认一次：

- [ ] 顶部菜单点 `Product -> Scheme -> Edit Scheme...`
- [ ] 左侧选择 `Run`
- [ ] `Info` 页签里确认 `Build Configuration = Release`
- [ ] 点击 `Close`

## 2. 配置签名（Signing）

- [ ] 打开 `Signing & Capabilities`
- [ ] 勾选 `Automatically manage signing`
- [ ] `Team` 选择你的个人 Apple ID 团队
- [ ] `Bundle Identifier` 保持唯一（当前建议：`com.wang.babyTracker`）
- [ ] 若提示冲突，改成你的唯一值（例如 `com.<你的名字>.walnie`）

## 3. 选择真机并安装第 1 台

- [ ] 顶部 Scheme 保持 `Runner`
- [ ] 顶部设备下拉框选择第 1 台 iPhone（非模拟器）
- [ ] 菜单 `Product -> Run`（或点击左上角运行按钮）
- [ ] 等待构建和安装完成，手机出现 Walnie 图标

## 4. 手机侧信任开发者证书

首次安装通常需要手动信任：
- [ ] iPhone 打开“设置”
- [ ] 进入“通用 -> VPN 与设备管理”（新系统可能名称略有差异）
- [ ] 找到你的开发者证书并点击“信任”
- [ ] 返回桌面，打开 Walnie 成功进入首页

## 5. 安装第 2 台手机

- [ ] 断开第 1 台，连接第 2 台并解锁
- [ ] Xcode 顶部设备切换到第 2 台 iPhone
- [ ] 再次执行 `Product -> Run`
- [ ] 在第 2 台手机完成同样的开发者证书信任
- [ ] 第 2 台手机打开 Walnie 成功

## 6. 双机联调验收（必须都过）

- [ ] A 机新增一条事件（如“吃奶 90ml”）
- [ ] B 机刷新后可见 A 机新增记录
- [ ] B 机再新增一条事件，A 机可见
- [ ] 两台手机都可完成语音录入权限申请
- [ ] 两台手机都可完成通知权限申请
- [ ] 后端临时不可用时，应用不崩溃且有失败提示

## 7. 常见问题快速处理

### A. `No signing certificate` / `Signing for Runner requires a development team`
- [ ] 到 `Signing & Capabilities` 重新选择 Team
- [ ] 确保 Apple ID 已在 Xcode 登录
- [ ] 再次 `Product -> Run`

### B. `Bundle Identifier already in use`
- [ ] 修改 `Bundle Identifier` 为全局唯一值
- [ ] 建议格式：`com.<yourname>.walnie`

### C. 手机上“无法验证 App”或打不开
- [ ] 到手机系统设置里完成开发者证书信任
- [ ] 重新启动 App

### D. 安装成功但无法同步云端
- [ ] 在 Mac 上执行 `./scripts/check_backend_health.sh`
- [ ] 确认服务器 8080 端口可访问
- [ ] 若服务器地址变更，重新执行构建脚本并安装

## 8. 维护提醒（免费账号）

- [ ] 记录安装日期
- [ ] 设一个每 6 天提醒“重签/重装 Walnie”
- [ ] 重装前先确认后端健康状态：`curl http://47.100.221.135:8080/health`
