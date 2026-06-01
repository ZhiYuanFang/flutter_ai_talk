## Context

- **事件目录**（模板）：`GET /device/history/api/event/options` → `EventDefinition`；当前仅 `id/name/logo/color`，需增加 `eventType`、`extraNames`。
- **历史记录**（实例）：list/WS 含 `eventId`、`eventNumber`、`startTime`、`endTime`、`remark` 等；`eventNumber` 描述**该条记录**语义，与 catalog 的 `eventType` 不同。
- **创建**：语音/文字走 `POST …/chat`；按钮模式走 **`POST /device/history/api/event/add`**（新增封装）。
- **更新**：已有 `POST …/event/update`；`eventUnit` 已废弃，add/update 均不再发送。
- **列表刷新**：add 成功后 WS `create` 必达；客户端 Toast 即可，不必 optimistic 插入。

## Goals / Non-Goals

**Goals:**

- 语音、文字、按钮三种输入模式可切换（Web 仍遵循现有 `WEB_HOME_INPUT` 策略，按钮模式在移动端 Android/iOS 提供；Web 可隐藏或随产品后续扩展）。
- 按钮网格数据 100% 来自 `eventCatalogProvider`；两行横向滚动，cell 为 logo + 名称。
- 点击行为 **仅** 由 `event.eventType` 决定；与 `history_line_format` 的 `eventNumber` 展示规则在**写入时**对齐，不在 UI 层反推类型。
- number 二级页：DateTime 选择 + Cupertino 滚轮（5,10,…,500）+ 可选 remark TextField。
- time 重复：提交前扫描本地历史（同 `eventId` + `isActiveTimingRecord`），拒绝并 Toast「{eventName}已在计时中」。

**Non-Goals:**

- 历史行字号/logo 放大（独立 change）。
- 修改 chat/语音解析或 `extraNames` 在 NLP 中的消费（仅缓存字段）。
- 变更 WS 协议或 add 响应字段的消费（除错误处理外）。

## Decisions

1. **输入模式枚举**  
   扩展 `_HomeInputChannel` → `voice | text | buttons`；底部切换 UI 与现有语音/文字 toggle 并列（三选一）。按钮模式下隐藏语音球/文字框，展示事件网格面板。

2. **两行网格分法**  
   按 `eventCatalogProvider` 列表顺序对半拆分：前半 → 第一行 `ListView` horizontal，后半 → 第二行。无后端 `row` 字段时的零配置方案；事件数奇数时第二行少一项。

3. **add 请求体**（无 `eventUnit`）  
   | eventType | eventNumber | startTime | endTime | remark |
   |-----------|-------------|-----------|---------|--------|
   | time | 0 | now | 0 | "" |
   | one | 1 | now | now | "" |
   | number | 滚轮值 | 用户选时刻 | 同 start | 用户可选 |

   `eventId` 用 catalog `id`（int）；`eventName` 用 catalog `name`；`deviceNo` 由 repository 注入。

4. **成功/失败反馈**  
   - 成功：`Toast「已记录{eventName}」`  
   - time 重复：`Toast「{eventName}已在计时中」`，不调 API  
   - `code != 0`：`ApiBusinessException.message` Toast  

5. **time 进行中判定**  
   复用 `isActiveTimingRecord` + 比较 `rawPayload['eventId']` 与 catalog `id`（注意 int/string 归一化）。

6. **update 去 eventUnit**  
   `buildEventUpdateBody` 删除 `eventUnit` 键；与 add 保持一致。

7. **前置条件**  
   与 chat 类似：需已登录、有效 `deviceNo`；WS 未就绪是否禁止 add——与 chat 对齐，若 chat 要求 WS 则 add 同样检查并 Toast；否则仅 add 失败时 Toast（实现阶段读 `sendCommand` 前置条件并对齐）。

## Risks / Trade-offs

- **[Risk] 底部区域高度不足**（220px 输入区 + 两行网格）→ 可略增按钮模式面板高度或压缩 cell 尺寸；与历史放大 change 联调。
- **[Risk] 本地未加载完全部历史时漏判 time 重复** → 服务端应拒绝重复；客户端仍做 best-effort 本地检查。
- **[Trade-off] 两行对半分** vs 后端排序字段 → 首版简单；后续可加 `sortOrder`。

## Migration Plan

- 发布新版本；options 无 `eventType` 的旧缓存项在下次 `event/options` 刷新后补齐；未知 `eventType` 的项在网格中禁用或隐藏。
- 无服务端迁移；`eventUnit` 停止发送需后端已忽略该字段。

## Open Questions

- （已决）remark 仅 number 二级页；one/time 固定 `""`。
- （已决）add 响应含 id，UI 不消费；WS 必达。
