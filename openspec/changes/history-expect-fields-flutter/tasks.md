## 1. 映射与缓存（对齐 Go）

- [x] 1.1 `buildEventAddBody` 支持可选 `expectStartTime` / `expectEndTime`（int 秒）与 `expectAmount`（**double**）；缺维省略键；`buildEventUpdateBody` 与 stop **不传**三键
- [x] 1.2 list/WS → rawPayload 透传；磁盘 equality 纳入三 expect 键；amount 按 num/double 保留

## 2. Add 打戳

- [x] 2.1 add 前按 eventId 读预报：有 `nextAt` → `expectStartTime`（含过期）；有 `expectDurationSec` → `expectEndTime`；有 `expectAmount` → 浮点上传
- [x] 2.2 无预报省略；计时开始 add 可打戳；`stopActiveTimingRecord` / 编辑 update MUST NOT 带 expect*

## 3. 联调与验收（Go 已就绪）

- [x] 3.1 对照已完成 twin：`*int64` / `*float64` omitempty、update 不写列；说明准确度不重放、柱图 UI 不在本 change
- [ ] 3.2 手工：带三字段 add 后 list/WS 可见（含小数 amount）；stop/update 后 expect* 不变；无 pred 时 add 成功且无 expect* 键
