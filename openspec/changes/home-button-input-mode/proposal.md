## Why

主页目前仅支持语音与文字输入，依赖 `chat` 接口解析自然语言才能落库，路径长且对「记一次吃奶/开始睡眠」等高频操作不友好。服务端已提供事件目录（含 `eventType`）与 `POST /device/history/api/event/add`，需要在客户端增加**按钮操作**输入模式：按事件类型一键或二级表单创建历史记录，并与既有历史 WebSocket 推送、计时停止能力衔接。

## What Changes

- 扩展事件目录模型：从 `GET /device/history/api/event/options` 解析并缓存 **`eventType`**（`number` | `time` | `one`）、**`extraNames`**（语音别名，按钮模式不展示）。
- 主页新增第三输入模式 **「按钮」**（与语音、文字并列可切换）；展示**两行横向可滚动**事件网格（上图下文，logo + 名称 + 品牌色）。
- 按 catalog 的 **`eventType`** 分支创建记录（**不得**用历史记录的 `eventNumber` 推断按钮行为）：
  - **time**：一点即 `add`；同 `eventId` 已有进行中计时时本地拒绝并 Toast「{eventName}已在计时中」。
  - **one**：一点即 `add`（`eventNumber=1`，起止同为当前时刻）。
  - **number**：二级页选时间、数量滚轮（5–500，步长 5，禁止手输）、可选 **remark**；确认后 `add`。
- 新增 `FeedRepository.addHistoryEvent` → `POST /device/history/api/event/add`；请求体**不含**已废弃的 **`eventUnit`**。
- 成功：Toast「已记录{eventName}」；列表依赖历史 **WS 必达**，不依赖响应 `id` 手动插行。
- 失败：`code != 0` 时 Toast `message`（与全场一致）。
- **update** 请求体同步**移除 `eventUnit`**（`buildEventUpdateBody`）。

## Capabilities

### New Capabilities

- `event-catalog-event-type`：options 列表解析 `eventType`、`extraNames` 及缓存对比字段扩展。
- `home-button-input-mode`：第三输入模式、事件网格 UI、number 二级页、time 重复校验与 Toast 文案。
- `history-event-add`：`event/add` 契约、三类请求体映射、remark 规则、update 去 `eventUnit`。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；事件目录与历史展示行为在本变更新增规格中完整描述，并与既有 `event-catalog-branding`、`active-timing-stop` 归档变更实现对齐。）

## Impact

- `app/lib/data/event_definition.dart`、`event_catalog_store.dart`：模型与解析。
- `app/lib/data/feed_repository.dart`、`remote_feed_repository.dart`：`addHistoryEvent`。
- `app/lib/data/history_mapper.dart`：add body 构建；update 去掉 `eventUnit`。
- `app/lib/ui/home_screen.dart` 及新组件：输入模式切换、事件网格、number 二级 sheet。
- 复用 `eventCatalogProvider`、`EventLogo`、既有 WS 历史推送与 `isActiveTimingRecord` 判定。

**Out of scope（另开 change）**：历史列表行字号/logo 放大（`home-history-visual-scale`）。
