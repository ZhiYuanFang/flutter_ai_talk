## 1. 用量记忆

- [x] 1.1 新增 `EventNumberMemoryStore`（SharedPreferences，按 eventId）
- [x] 1.2 添加 number 事件 Sheet：无 `initialUsage` 时读取记忆并定位滚轮
- [x] 1.3 确认添加时写入记忆；编辑历史仍用 `_applyRecordToForm` 原用量（不经过添加 Sheet）
