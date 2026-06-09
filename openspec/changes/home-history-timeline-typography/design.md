# Design: 主页历史时间轴排版与 eventUnit

## 数据模型

- `event.unit`：`VARCHAR(32) NULL`，仅对 `event_type=number` 有意义（如 `ml`、`次`）；管理端可编辑。
- `history.event_unit`：`VARCHAR(32) NULL`，写入 history 时从请求体 `eventUnit`（若有）或事件主档 `unit` 复制；客户端 add/update **不**传 `eventUnit`，由服务端反规范化。

## 服务端写入

- `AddDeviceHistory` / voice 全路径 `AddHistory` 在 insert 前调用 `enrichHistoryEventUnit`。
- `EventAdd` HTTP：若 body 含非空 `eventUnit` 则优先使用，否则查 event 主档。
- DeepSeek 新建 `number` 事件：JSON 增加 `event_unit`，落库至 `event.unit`；统一意图结构同步支持。

## API 契约

- `GET /device/history/api/list`、历史 WS payload、`GET .../event/options` 均含 `eventUnit`（camelCase）。
- 事件 options 列表项增加 `unit` 字段（与 entity 一致）。

## Flutter 排版

- `HistoryHomeRowDisplay` 扩展：`trailingCount`、`trailingUnit`、`trailingPrefix`、`trailingDuration`；计数尾注不再使用 `→` 前缀字符串。
- `HomeHistoryTimelineTile`：中心列与尾注列改用 `RichText`；数字 span 使用 `fontSize * 2`、`FontWeight.bold`、事件 accent 色。
- `rowHeight`：`37` → `40`；`slotHeightFor` 同步。

## 迁移

- SQL 脚本：`docs/migrations/event_unit_history_event_unit.sql`（两列 `ALTER TABLE`，可空，无回填强制要求）。
- 部署后需 `gf gen dao` 或手工同步 entity/dao（本变更手工维护 generated 文件以可编译）。
