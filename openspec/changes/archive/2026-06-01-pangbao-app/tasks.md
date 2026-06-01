## 1. 工程初始化

- [x] 1.1 在仓库根目录（或 `app/`）创建 Flutter 工程，启用 Android、iOS、Web；各平台清单/Web 标题中设置应用显示名为 **胖宝**
- [x] 1.2 添加核心依赖：`go_router`、状态管理（按 `design.md`，如 `flutter_riverpod`）、`webview_flutter`（含 Web 降级方案）、图表库（如 `fl_chart`）、`package_info_plus`、`http` 或 `dio`
- [x] 1.3 配置 `analysis_options.yaml`、`.gitignore`；在 README 中说明 `--dart-define`（微信、隐私政策 URL、API 基址等），**不得**将密钥提交入库

## 2. 应用壳与导航

- [x] 2.1 使用 `go_router` 定义路由：启动/鉴权门 → 登录 → 主页壳；`TrendsCenter`、`SettingsCenter` 路由；处理未知路径
- [x] 2.2 实现根级 `MaterialApp` / 主题扩展，接入主题控制器（性别默认 + 自定义背景）
- [x] 2.3 启动时调用 Mock 的「版本检查」；当远端版本与当前 `package_info` 一致时不打扰用户

## 3. Mock 仓库与模型

- [x] 3.1 定义 DTO：宝宝、历史行、SSE 载荷、趋势目录项、趋势序列点、版本信息（字段对齐未来 JSON；代码中**不写死**事件类型枚举）
- [x] 3.2 实现 `MockAuthRepository`、`MockFeedRepository`（历史 + 指令 + SSE 流）、`MockTrendsRepository`、`MockSettingsRepository`、`MockVersionRepository`，带合理网络延迟模拟
- [x] 3.3 通过 Riverpod（或选定 DI）注册仓库供页面注入

## 4. 认证与隐私（微信先占位，接口可替换）

- [x] 4.1 登录页 UI：微信登录按钮、**请阅读并同意隐私政策** 文案行，点击后在应用内加载可配置的隐私政策 URL
- [x] 4.2 在统一接口后 Stub `signInWithWeChat()`（移动端 / Web）；文档中注明后续对接 SDK 与 Web OAuth 的挂载点
- [x] 4.3 登录成功进入主页；将 Mock 会话令牌持久化（`shared_preferences` 或安全存储占位）

## 5. 主页体验

- [x] 5.1 构建 AppBar：右上角设置入口；主体布局：历史区 + 主输入区
- [x] 5.2 移动端：圆形按住说话控件；集成 `speech_to_text`（或选定 STT）；松手后将文本通过 `MockFeedRepository.sendCommand` 发出
- [x] 5.3 Web：以醒目文本框 + 提交替代语音，调用同一 `sendCommand`
- [x] 5.4 历史列表：加载 Mock；最新在底部；自下而上渐隐且字号递减（遵守最小可读字号）
- [x] 5.5 订阅 Mock SSE；收到事件时按规范插入/更新底部最新一条
- [x] 5.6 在主输入区**右上方附近**增加趋势入口（如 FAB/IconButton），导航至趋势路由

## 6. 趋势中心

- [x] 6.1 进入页时从仓库拉取 Mock 的事件 key/标签目录
- [x] 6.2 为每个事件渲染图表卡片；Mock 时间范围选择器（或 Tab）切换展示数据点
- [x] 6.3 当前范围无数据时的空状态 UI

## 7. 设置中心

- [x] 7.1 展示 `MockSettingsRepository` 返回的**单个**宝宝摘要
- [x] 7.2 隐私政策行 → 与登录页相同的应用内 URL 打开方式
- [x] 7.3 切换账号：清除会话，确认对话框后回到登录
- [x] 7.4 注销账户：两步确认；Mock 调用接口；完成后回登录
- [x] 7.5 主题区：展示性别默认预览；颜色选择器自定义背景；持久化并全局应用

## 8. 版本更新体验（分端）

- [x] 8.1 当 Mock `MockVersionRepository` 判定远端版本高于当前 `package_info` 时展示更新提示 UI
- [x] 8.2 iOS：「前往 App Store」打开商店链接（配置中占位应用 ID）
- [x] 8.3 Android：模拟下载 + 安装流程 UI（进度 → Snackbar）；真安装待 CDN + FileProvider 就绪后补全
- [x] 8.4 Web：非阻断横幅「新版本可用，请刷新页面」并提供重新加载操作

## 9. M1 质检与收尾

- [ ] 9.1 运行 `flutter analyze` 并修复问题；在 Chrome + 至少一个 Android 或 iOS 模拟器上验证 `flutter run`（本机未检测到 `flutter`/`dart` 在 PATH，需在本地安装 Flutter 后执行）
- [ ] 9.2 冒烟测试全部导航与 Mock 流程；截图可选（依赖 9.1 真机/模拟器运行）
- [x] 9.3 README 增补：如何运行、所需 dart-define、已知 WebView/SSE 限制说明
