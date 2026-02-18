# Walnie (Baby Tracker)

新生儿吃喝拉撒记录 App。现在支持两种存储模式：
- 本地模式：Flutter + Drift(SQLite)
- 云端模式：Flutter + Walnie Backend + MySQL

## 功能

- 手动记录：`吃奶` / `便便` / `尿尿` / `换尿布` / `吸奶`
- 首页：今日汇总 + 时间线
- 提醒：按“上次喂奶 + 间隔小时”计算
- 语音流程：语音转写 -> 规则解析（可选 LLM 兜底）-> 确认 -> 入库

## 项目结构

- `lib/` Flutter 客户端（Clean Architecture）
- `backend/` Node.js 后端（Express + MySQL）
- `deploy/docker-compose.aliyun.yml` 阿里云部署编排
- `docs/openapi.yaml` API 文档

## 1. 本地开发（客户端）

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## 2. 本地开发（后端）

```bash
cd backend
npm install
cp .env.example .env
# 修改 .env 的数据库连接
npm run start
```

后端默认监听 `8080`，健康检查：

```bash
curl http://127.0.0.1:8080/health
```

## 3. 阿里云轻量服务器部署（后端 + MySQL）

以下步骤在服务器上执行（例如你的 `47.100.221.135`）：

```bash
# 1) 上传项目后进入仓库
cd /path/to/Walnie

# 2) 准备环境变量
cp deploy/.env.example deploy/.env
# 编辑 deploy/.env，至少设置强密码

# 3) 启动 MySQL + API
docker compose --env-file deploy/.env -f deploy/docker-compose.aliyun.yml up -d --build

# 4) 检查服务
docker compose --env-file deploy/.env -f deploy/docker-compose.aliyun.yml ps
curl http://127.0.0.1:8080/health
```

服务器安全组建议仅放行：
- `22`（SSH）
- `8080`（API，若客户端直连）

不建议对公网暴露 `3306`。

## 4. Flutter 切换到云端 API

给 Flutter 传入后端地址：

```bash
flutter run --dart-define=EVENT_API_BASE_URL=http://47.100.221.135:8080
```

不传 `EVENT_API_BASE_URL` 时，默认仍使用本地 SQLite（兼容原有行为）。
`ios/Runner/Info.plist` 已为 `47.100.221.135` 和 `127.0.0.1` 配置 ATS 例外，允许 HTTP 联调。

## 5. LLM 兜底配置

默认参数在：
- `lib/infrastructure/voice/llm_fallback_parser.dart`

可通过 `--dart-define` 覆盖：
- `LLM_PARSER_ENDPOINT`
- `LLM_PARSER_API_KEY`
- `LLM_PARSER_MODEL`
- `LLM_MAX_INPUT_WORDS`
- `LLM_MAX_TRANSCRIPT_CHARS`
- `LLM_MAX_TOKENS_PER_WORD`
- `LLM_MAX_TOTAL_OUTPUT_TOKENS`
- `LLM_MIN_OUTPUT_TOKENS`
- `LLM_HTTP_TIMEOUT_MS`
- `LLM_TEMPERATURE`

## 测试

```bash
flutter analyze
flutter test
```
