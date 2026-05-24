## 1. 模式与 AppBar

- [x] 1.1 增加 `_HistoryDetailMode`（view/edit），默认 view；AppBar 按模式切换编辑/取消/删除
- [x] 1.2 预览标题优先使用事件名；编辑模式标题为「编辑」或事件名

## 2. 预览 body

- [x] 2.1 实现 `_buildPreviewBody`：按 `eventNumber` 只读展示时间、用量、用时、备注（`formatHistoryApiDateTime` 等）
- [x] 2.2 移除预览与编辑中的「创建时间」/`createdAt` 展示行

## 3. 编辑 body

- [x] 3.1 仅在 edit 模式渲染 `Form`、`_editFields`、底部「保存」
- [x] 3.2 `_enterEdit` / `_cancelEdit`：取消时从 `_record` 重置 controllers 与 `_startEdit`/`_endEdit`

## 4. 导航与脏检查

- [x] 4.1 编辑态未保存改动时返回/取消需确认对话框（`PopScope` 或等价）
- [x] 4.2 保存/删除成功仍 `pop(true)`；预览态返回 `pop(false)`

## 5. 验证

- [x] 5.1 从主页进入：先见只读详情，点编辑后出现表单与底部保存，取消回到只读
- [x] 5.2 全程无「创建时间」文案；各 `eventNumber` 类型预览字段完整
