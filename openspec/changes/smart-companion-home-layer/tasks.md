## 1. 主页三页壳层

- [x] 1.1 将 `UcgHomeShell` PageView 改为 3 页：`0=陪伴`、`1=喂养(initialPage)`、`2=UCG`；抽出页面索引常量并全库替换原 `0/1` 硬编码
- [x] 1.2 实现陪伴页懒挂载（`_companionEverMounted`），冷启动喂养页不 build 陪伴
- [x] 1.3 喂养页增加左缘「进入陪伴」拉条（镜像 `UcgEnterSquareTab` 交互）
- [x] 1.4 修正 Android 返回：陪伴/UCG → 喂养；喂养根层保留双击退出
- [x] 1.5 修正广场 Tab 再点、`onBackToFeeding`、拉条显隐等场景至新索引

## 2. 智能陪伴 UI 与入口收敛

- [x] 2.1 将诊疗屏嵌入 page 0（可重命名/抽取 companion widget），真玻璃可爱视觉落地
- [x] 2.2 文案去诊疗化；成功回答改为「非医疗建议」弱提示；更新同意弹窗为陪伴语境
- [x] 2.3 右上角清理按钮 + `showGlassDialog` 二次确认；确认后清空内存与本地 store（不调用 `feedRepository.clearCache`）
- [x] 2.4 移除喂养沉浸式头部诊疗入口；`/pangbao` 深链重定向至 `/home` 并切到陪伴页

## 3. Clinic WS 生命周期

- [x] 3.1 将 `ClinicWsClient` 所有权上移到壳/会话级 provider（遵守 `ResilientWebSocketClient` 与副作用治理）
- [x] 3.2 陪伴曾挂载且具备同意/登录/绑宝条件时保持 `connectionDesired`；滑走喂养/UCG 不断开
- [x] 3.3 进入陪伴页检查 ready，未就绪则建连；冷启动未进陪伴不建连

## 4. 本地会话与 session_sync

- [x] 4.1 扩展本地会话模型：tip 源条目、纯线截断分隔项；去掉 12 小时清理语义与空态文案
- [x] 4.2 实现 `session_sync` merge：仅本地轮次置顶 + 纯线无字分隔 + 服务端权威块 + failed 保留规则
- [x] 4.3 清记录后同步清除分隔项与内存列表，并重置 tip 消费标记（首页 tip 仍展示时可再注入）

## 5. 「我来啦」与 tip 桥接

- [x] 5.1 实现当日首次问候门闩（本地日历日）；有 tip 注入则跳过并标记当日已问候
- [x] 5.2 tip `done` 整卡可点进陪伴；`streaming` 禁用点按；点卡只切页不另发用户句
- [x] 5.3 点卡/右滑/拉条进入时注入未消费 tip 一次并消费；与 session 规则对齐

## 6. 客户端去额度

- [x] 6.1 移除喂养 `voiceAi` 额度 hint 及布局占位
- [x] 6.2 移除陪伴/clinic 额度展示；`handleAiQuotaBusinessCode` 对 40302 不再弹额度框（40301 保留）
- [x] 6.3 移除润笔额度 hint 与 `quotaDegraded` 降速 toast
- [x] 6.4 收敛喂养 AI 路径上的 40302 额度弹框调用点

## 7. 验收

- [ ] 7.1 手工验收：三页导航、懒挂载、拉条、返回键、tip 注入/消费、当天「我来啦」、滑走 WS 保持、截断横线、清记录确认、无额度 UI
- [x] 7.2 本 change 未改 `app/android/**` 则无需 release APK；若实现中触及原生则补 `flutter build apk --release` 与 proguard 项
