## ADDED Requirements

### Requirement: ucg_ai_config SHALL be managed in go_ai_talk ai_config.go

Runtime AI settings MUST be loaded by `go_ai_talk/internal/services/ucg/ai_config.go` from table `ucg_ai_config` (singleton id=1) in database `ai_voice_ucg`. Table MUST be registered in `hack/config.yaml` and accessed via `gf gen dao` generated DAO. YAML defaults MUST come from `manifest/config/config.ucg-service.yaml` under `ucg.ai`.

AI 配置运行时须由 go_ai_talk `ai_config.go` 读取 DB 单例行；表在 hack/config.yaml 注册。

#### Scenario: gen dao 注册
- **WHEN** 开发者执行 `gf gen dao` 于 go_ai_talk 根目录
- **THEN** 生成物 SHALL 包含 `ucg_ai_config` 的 dao 与 entity

### Requirement: ucg_ai_config SHALL store singleton runtime AI settings

The database MUST contain table `ucg_ai_config` with singleton row `id = 1` holding `vision_model`, `max_images_per_request`, `updated_at`, and `updated_by`. Deployment MUST seed defaults when row missing.

数据库须含 `ucg_ai_config` 单例行，字段含 vision 模型与单次最大图片数；部署须 seed 默认值。

#### Scenario: 初始 seed
- **WHEN** migration 后无 id=1 行
- **THEN** 部署脚本或 migration SHALL 插入 YAML fallback 默认值

### Requirement: Runtime SHALL load AI config with TTL cache

The ucg-service runtime MUST load `ucg_ai_config` id=1 into memory with approximately 60 seconds TTL. On Admin PUT success, the cache MUST be invalidated immediately. When DB row unavailable, service MUST fall back to YAML/env defaults.

运行时须 ~60s TTL 缓存 AI 配置；Admin PUT 后须立即失效；DB 不可用时回退 YAML。

#### Scenario: 缓存命中
- **WHEN** polish 请求在 TTL 内且缓存未失效
- **THEN** 服务 SHALL 使用缓存的 visionModel 与 maxImagesPerRequest

#### Scenario: PUT 后失效
- **WHEN** Admin 成功 PUT ai-config
- **THEN** 下一次 polish 请求 SHALL 读取最新 DB 值

### Requirement: Admin UI SHALL expose UCG AI configuration card

The go_ai_talk admin site MUST add a navigation card on `admin.html` linking to `ucg-admin.html`. The UCG admin page MUST provide a form to view and edit `visionModel` (dropdown from hardcoded allowlist) and `maxImagesPerRequest` (positive integer), saving via PUT `/ucg/admin/api/ai-config`.

Admin 须在 admin.html 增加 UCG 入口；ucg-admin.html 须提供模型下拉（硬编码 allowlist）与 max images 编辑。

#### Scenario: Admin 打开 UCG AI 页
- **WHEN** 管理员从 admin.html 进入 UCG AI 配置
- **THEN** 页面 SHALL 展示当前 visionModel 与 maxImagesPerRequest

#### Scenario: Admin 保存配置
- **WHEN** 管理员选择 allowlist 内模型并保存
- **THEN** 页面 SHALL 调用 PUT 并展示成功状态

#### Scenario: 非法模型前端约束
- **WHEN** Admin UI 渲染模型下拉
- **THEN** 选项 SHALL 仅包含服务端 allowlist 中的模型

### Requirement: DashScope API key SHALL use dedicated ucg config block in config.ucg-service.yaml

The ucg-service MUST read DashScope API key from `go_ai_talk/manifest/config/config.ucg-service.yaml` block `ucg.ai.dashscope_api_key`, overridable by environment variable `UCG_DASHSCOPE_API_KEY` (legacy `UCG_DEEPSEEK_API_KEY` MAY be accepted for backward compatibility). The key and `ucg.ai.vision_endpoint` MUST target **Alibaba DashScope Qwen vision** via OpenAI-compatible chat completions (`https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`). Admin password MUST use env `UCG_ADMIN_PASSWORD` or yaml `ucg.admin.password`.

DashScope Key 须位于 config.ucg-service.yaml `ucg.ai` 块；须配合 Qwen vision endpoint；env `UCG_DASHSCOPE_API_KEY`；Admin 口令 `UCG_ADMIN_PASSWORD`。

#### Scenario: env 覆盖 yaml
- **WHEN** 环境变量 `UCG_DASHSCOPE_API_KEY` 已设置
- **THEN** polish 模块 SHALL 使用该 env 值而非 yaml 明文

#### Scenario: 独立配置块
- **WHEN** ucg-service 启动
- **THEN** polish 模块 SHALL 读取 `ucg.ai` 配置块而非 voice 运行时共享变量

#### Scenario: 缺 key 时 polish 失败
- **WHEN** ucg.ai.dashscope_api_key 与 `UCG_DASHSCOPE_API_KEY` 均为空
- **THEN** POST /posts/polish SHALL 返回 503

### Requirement: Default vision model SHALL be qwen3-vl-plus

The default `vision_model` in YAML seed and DB migration MUST be `qwen3-vl-plus`. The Admin allowlist MUST include Qwen VL variants (e.g. `qwen3-vl-plus`, `qwen3-vl-flash`, `qwen-vl-plus`, `qwen-vl-max`) and MUST NOT include text-only models such as `deepseek-chat`.

默认 vision 模型须为 `qwen3-vl-plus`；allowlist 须含 Qwen VL 变体且不含纯文本模型。

#### Scenario: Seed 默认值
- **WHEN** migration seed 插入 ucg_ai_config id=1
- **THEN** vision_model SHALL 为 `qwen3-vl-plus`

#### Scenario: Admin allowlist
- **WHEN** Admin GET ai-config 返回 allowedModels
- **THEN** 列表 SHALL 包含 `qwen3-vl-plus` 且 SHALL NOT 包含 `deepseek-chat`
