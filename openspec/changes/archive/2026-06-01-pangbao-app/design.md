## 背景

全新 Flutter 应用 **胖宝**：用户以自然语言下发指令，由服务端解析语义并处理母婴相关事件；客户端只上传**文本**（移动端经语音转写，Web 为键盘输入），通过 **SSE** 接收最新历史记录，趋势定义完全**由服务端下发**。M1 仅交付**导航 + UI + Mock**；真实接口与商店资质后续接入。

## 目标与非目标

**目标：**

- 单一代码库（Flutter）覆盖 **Android、iOS、Web**，导航与页面结构一致。
- 三端**真实微信登录**（移动端 SDK；Web 端 OAuth / 网页授权）。
- **主页**：历史区 + 主输入（移动端语音+转写；Web **文本提交**）+ SSE 接入点（可 Mock）。
- **趋势**、**设置**二级路由，数据形态与将来 JSON 对齐的 Mock。
- **版本体验**按平台区分：iOS 跳转 App Store；Android 应用内下载安装；Web 刷新提示。
- **主题**：按宝宝性别默认色，设置中可覆盖背景色。

**非目标（M1）：**

- 生产环境后端联调、在仓库中存放真实微信 AppId、应用商店上架。
- 在业务代码中维护固定喂养事件类型全表（演示用 Mock JSON 中的任意 key 除外）。
- 离线优先同步、推送通知、除简体中文外的完整 i18n（除非框架自带且零成本）。

## 技术决策

| 决策 | 理由 | 曾考虑的替代方案 |
|------|------|------------------|
| 状态管理 | 使用 **Riverpod**（或项目已有默认）管理会话、Mock 仓库、主题；任务中若仓库无先例由实现选定。 | Bloc：M1 偏重；纯 setState：SSE/主题扩展差。 |
| 路由 | **go_router**：声明式路由，登录 → 壳 → 主页 → 趋势/设置；Web URL 友好。 | 手写 Navigator 2.0：样板多。 |
| Mock 层 | 抽象 `AuthRepository`、`FeedRepository`、`TrendsRepository`、`SettingsRepository`、`VersionRepository`，内存实现 + 延迟，模拟契约。 | 仅在 Widget 写死：后续换 HTTP 成本高。 |
| 移动端转写 | 优先 **`speech_to_text`** 或系统识别通道；命令接口只传**转写文本**。 | 始终上传音频：体积大；M1 若服务端转写则与「客户端转写」产品描述需再对齐。 |
| Web 政策页 | 移动端 **`webview_flutter`**；Web 用 **`iframe` / `HtmlElementView`** 或插件在 Web 上的支持策略——需求是「应用内打开 URL」，不绑定单一插件实现。 | 仅外链系统浏览器：与产品不符。 |
| SSE | Web 可用 `dart:html` EventSource；移动端用 **`sse` / `http` + Stream`** 或统一封装包；M1 可用 `Stream.periodic` 模拟。 | WebSocket：本次需求未要求。 |
| 图表 | **`fl_chart`**（或社区版 `syncfusion` 等）实现时间序列；实现阶段择一即可。 | 自绘 Canvas：性价比低。 |
| Android 更新 | **`package_info_plus`** + 版本接口；APK 用 **`dio`/`http`** 下载 + **`open_filex`/Intent** + 策略允许的安装权限；M1 可只做「下载完成」UI 占位。 | 仅用 Play 应用内更新 API：与「自托管 APK」表述不同，可作为二期。 |
| 密钥 | 微信 AppId、Universal Link、Web 回调域名等放在 **`--dart-define`** 或未入库的环境文件，**禁止**提交密钥。 | 硬编码：不可接受。 |

## 风险与取舍

| 风险 | 缓解 |
|------|------|
| Web 微信 OAuth 需备案域名、HTTPS、审核 | 文档写明占位与环境开关；未配置时 Web 登录可降级提示（实现阶段再定）。 |
| Web 不使用麦克风 | 产品已定为文本输入，无麦克风权限路径。 |
| `webview_flutter` 在 Web 上能力有限 | 政策页走 Web 嵌入方案；任务单跟踪。 |
| SSE 鉴权（Cookie / Query Token）未定 | 仓库层接受「请求头工厂」；待后端约定。 |
| Android 8+ 安装未知来源 APK、FileProvider | 真安装阶段在 Android 模块补齐 FileProvider 模板。 |

## 迁移计划

- **M1**：建立工程、路由、Mock 仓库、各平台显示名为 **胖宝**。
- **M2**：替换为 HTTP/SSE 真实实现；接入微信与版本接口；令牌存储安全评审。
- **回滚**：回到 M1 标签提交；保留 Mock 便于演示。

## 待决问题

- 文本指令接口与 **SSE** 的精确路径、鉴权方式（Header / Query）。
- Android 最终采用 **Play 应用内更新** 与 **自托管 APK** 的组合或其一（合规与政策）。
- **注销账户** 是否必须对接独立销号接口（或延至 M2）。
