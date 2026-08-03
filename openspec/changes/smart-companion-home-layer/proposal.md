## Why

产品要将「胖宝诊疗」从独立路由的医疗感问答，演进为主页左侧的「智能陪伴」：陪伴解闷、可爱真玻璃、与喂养小贴士闭环。用户需要在喂养页右滑即可进入陪伴（对称于左滑进广场），并在喂养动作触发小贴士后一键「接着聊」。同时取消 AI 额度对用户的可见限制与展示（客户端先行），避免「诊疗 / 额度」气质与陪伴定位冲突。

## What Changes

- **主页三页 PageView（BREAKING 相对 `ucg-home-entry` 双页约定）**：`[智能陪伴 | 喂养(默认着陆) | UCG]`；陪伴侧懒挂载对齐广场；喂养页左缘「进入陪伴」拉条（镜像「进入广场」）。
- **诊疗界面改造为智能陪伴**：去「诊疗」品牌语汇与医嘱强免责；保留「非医疗建议」弱提示；可爱**真玻璃**视觉；移除顶栏原诊疗入口与 `/pangbao` 作为主入口的依赖（路由可保留兼容或重定向至陪伴层，实现期定）。
- **复用 Clinic WebSocket**：协议不变；连接所有权上移为壳/会话级——滑离陪伴页 **WS 保持**；进入陪伴页检查就绪并建连。
- **「我来啦」主动问候**：进入陪伴页时，若**当天首次**且**无可注入 tip**，自动以「我来啦」作为 question 请求接口；有 tip 则跳过（A3）。
- **小贴士 → 陪伴**：仅 `done` 可点整卡进陪伴并注入 tip 文本为会话内容（消费一次）；`streaming` 禁用点按；点卡只切页不另发用户句；右滑进陪伴时若有未消费 done tip 同样注入。
- **本地会话长存**：取消「12 小时内清理」产品语义；历史始终保留在本地；**右上角清理**按钮 + **玻璃二次确认**后清空陪伴记录；**不改**设置/账号原有清缓存策略。
- **`session_sync` 截断可视化**：服务端窗口覆盖/截断时，保留本地更早轮次，中间插入**纯线无字**长横线分隔；空 `session_sync` 仍不得清空本地。
- **额度（客户端先行）**：`voiceAi` + `clinicAi` + `polish` **全部去掉额度 UI**，客户端**不做额度限制**（含 40302 弹框/降速文案路径）；40301 登录引导保留；后端取消限额另 change。

## Capabilities

### New Capabilities

- `smart-companion-ui`：智能陪伴页产品语义、真玻璃可爱视觉、非医疗弱提示、右上角清记录（玻璃确认）、空态与输入文案去诊疗化。
- `smart-companion-session`：陪伴本地会话长存、tip 轮次注入与消费、`session_sync` 截断横线、当天首次「我来啦」、Clinic WS 壳级保持与进页建连检查。
- `home-tip-companion-bridge`：首页小贴士整卡进陪伴的门闩（仅 done）、注入上下文、与 PageView 切页联动。

### Modified Capabilities

- `ucg-home-entry`：PageView 由 2 页改为 3 页；默认着陆喂养（中间页）；索引重映射；左缘陪伴拉条；返回键/广场再点回喂养等场景随新索引更新。
- `pangbao-clinic-ui`：空态/入口语义演进为智能陪伴（或由 `smart-companion-ui` 承接并标注废弃主入口 `/pangbao` push）。
- `pangbao-clinic-session-cache`：去掉 12h 清理语义；增加截断横线与 tip 源轮次；清记录改由陪伴页按钮触发。
- `pangbao-clinic-ws-error-display`：40302 额度弹框不再作为陪伴/clinic 必达 UX（客户端先行去额度）。
- `pangbao-clinic-ws-status-banner`：适用范围改为智能陪伴页（行为可延续 gaveUp 横幅）。
- `home-ai-quota-hint`：喂养页不再展示 `voiceAi` 额度 hint。
- `ucg-compose-ai-polish`：润笔不再展示额度 hint / `quotaDegraded` 降速 toast（客户端先行）。

## Impact

- **flutter_ai_talk**：`UcgHomeShell` 三页索引与懒挂载；新左缘拉条；`PangbaoAiScreen`（或重命名 companion）嵌入 PageView；`ClinicWsClient` 生命周期上移；`HomeTipPanel` / `tipProvider` 消费与导航；`PangbaoClinicSessionStore` 模型扩展；`AiQuotaRemainingHint` 与 `handleAiQuotaBusinessCode(40302)` 调用点收敛；`home_immersive_header` 去掉诊疗入口。
- **go_ai_talk**：本 change **不要求**后端改 Clinic 协议；额度后端取消为后续；`session_sync` 窗口行为沿用现网，客户端用横线表达截断。
- **基线对照**：v2.0.3 之 `ucg-home-entry`、`pangbao-clinic-*`、`home-ai-quota-hint`、`ucg-compose-ai-polish`、`ai-chat-data-consent`；实现验收以本 change delta + 未改基线条款为准。
- **风险**：三页索引迁移面广；WS 上移需遵守 `ResilientWebSocketClient` 与副作用治理；真玻璃仅单页陪伴，避免 Feed 级 blur。
