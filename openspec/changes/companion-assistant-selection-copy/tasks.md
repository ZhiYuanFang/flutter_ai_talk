## 1. 方案 A：助手选区外提

- [x] 1.1 助手完成态气泡：`SelectionArea` 包在 `UcgComposeLightGlassPanel` 外
- [x] 1.2 `ClinicAnswerBody` 树洞路径传 `selectable: false`（MarkdownBlock 不再内套 SelectionArea）
- [x] 1.3 若松手仍无手柄：局部放开助手路径裁剪（`Clip.none` 或等价），避免改全局玻璃默认

## 2. 方案 C′a：选区上方「复制」

- [x] 2.1 为助手气泡 `SelectionArea` 配置 `contextMenuBuilder`，含「复制」按钮
- [x] 2.2 「复制」将**当前选中片段**写入 `Clipboard`；可选 `showAppToast('已复制')`

## 3. 回归

- [ ] 3.1 手工：助手长按松手后选区保持、有手柄；点「复制」剪贴板正确
- [ ] 3.2 手工：用户气泡选区仍可用；首页 tip 仍不可选
