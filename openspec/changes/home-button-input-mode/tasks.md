## 1. 事件目录模型

- [x] 1.1 `EventDefinition` 增加 `eventType`、`extraNames`；`fromOptionsMap` / `fromJson` / `toJson` / `copyWith` 对齐
- [x] 1.2 `parseEventOptionsList` 与 `catalogSnapshotsEqual` 纳入 `eventType`、`extraNames` 对比
- [x] 1.3 提供 `eventType` 合法值校验（`number|time|one`）；非法项按钮网格禁用或隐藏

## 2. 历史 add / update 契约

- [x] 2.1 新增 `buildEventAddBody`（无 `eventUnit`）；`eventId` int、`startTime`/`endTime` Unix 秒
- [x] 2.2 `FeedRepository` / `RemoteFeedRepository` 实现 `addHistoryEvent` → `POST /device/history/api/event/add`
- [x] 2.3 add 失败 `code!=0` Toast `message`；成功返回 true（不消费响应 `id` 插 UI）
- [x] 2.4 `buildEventUpdateBody` 移除 `eventUnit` 键

## 3. 按钮模式 UI

- [x] 3.1 `_HomeInputChannel` 扩展 `buttons`；底部三选一切换（语音 / 文字 / 按钮）
- [x] 3.2 按钮模式：两行横向 `ListView` 网格 cell（`EventLogo` + 名称 + 品牌色）；目录对半分行
- [x] 3.3 目录空态；按钮模式隐藏语音球/文字主输入
- [x] 3.4 Web 策略：移动端提供按钮模式；Web 可隐藏或沿用现有 `WEB_HOME_INPUT` 约定（与 design 一致）

## 4. 点击分支与二级页

- [x] 4.1 `time`：本地 `eventId` + `isActiveTimingRecord` 重复检查；拒绝 Toast「{eventName}已在计时中」
- [x] 4.2 `time` / `one`：直接 `add`（remark 固定 `""`）；成功 Toast「已记录{eventName}」
- [x] 4.3 `number`：二级 BottomSheet — 时间选择、Cupertino 滚轮 5–500 步长 5、可选 remark TextField
- [x] 4.4 `number` 确认后 `add`；成功 Toast「已记录{eventName}」
- [x] 4.5 add 前置：已登录 + 有效 `deviceNo`；与 `sendCommand` 对齐 WS 就绪策略

## 5. 验证

- [x] 5.1 按钮模式：三类 eventType 各走通一条 add；历史 WS 推送后列表更新
- [x] 5.2 time 重复点击同事件：仅 Toast，无二次 add
- [x] 5.3 number 二级页：滚轮无手输、remark 可空；update 请求体无 `eventUnit`
- [x] 5.4 options 刷新后 `eventType` 变化能更新本地缓存与网格
