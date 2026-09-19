## 1. Go 点击载荷与占位通道

- [x] 1.1 在 `go_ai_talk` 的 APNs 可见推送中保持根级 `bizType`，并确认点击 `userInfo` 能读到 `ucg_alert` / `predict_imminent`
- [x] 1.2 HMS 可见推送的点击 Intent extras 必须带上 `bizType`；若现有 type=3 带不出该字段，改为打开 `MainActivity` 且 extras 含 `bizType` 的 click intent
- [x] 1.3 为 vivo、oppo 增加 dispatcher 占位 Sender：打日志并跳过，不调用厂商 API；register 白名单仍仅为 `apns`、`hms`、`mipush`
- [x] 1.4 小米可见消息的 `payload` 可写入 `bizType`，不作为本变更完成条件

## 2. 客户端暂存与分流

- [x] 2.1 首帧前绑定 Android 通知点击，并把 iOS 点击（含冷启动与前台横幅 `willPresent`）交给 Flutter；冷启动在监听就绪前不得丢点击
- [x] 2.2 点击只暂存最新 `bizType`（覆盖未消费值）；当前不在 `/home` 时先进入 `/home`。日志复用 `AppDebugLog.ucgPush`，不新增 tag
- [x] 2.3 主页在 `/home` 且会话已知后消费：`predict_imminent` 切预测页；未登录、未知类型、`ucg_silent_badge` 不切页且不弹登录

## 3. UCG 消息 Tab

- [x] 3.1 已登录的 `ucg_alert`：切到 UCG 页；`UcgShell` 已挂载后调用与点消息 Tab 相同的处理（会话、互动、未读刷新），不模拟手势、不等待这些接口完成
- [x] 3.2 资格未过时可见表面仍为既有锁层，不打开独立锁页路由；壳已在时直接选消息 Tab

## 4. 验收

- [ ] 4.1 华为与 iOS 手工核对：杀进程、后台、前台横幅下，UCG 进入消息列表、预测进入预测主页、未登录与缺 `bizType` 只打开应用
- [x] 4.2 若改动 `app/android/**` 或新增原生 SDK/AAR：`flutter build apk --release` 通过，并按 `openspec/project.md` 更新 `proguard-rules.pro`
