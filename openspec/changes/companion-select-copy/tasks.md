## 1. 列表（方案 M）

- [x] 1.1 去掉消息列表外层 `SelectionArea`
- [x] 1.2 确认列表竖滑与滚动到底按钮仍正常

## 2. 用户气泡

- [x] 2.1 用户气泡正文 `SelectableText`（不包 `GestureDetector`）
- [x] 2.2 `_consented` 时用「填入输入框」图标替代单击填入

## 3. 助手答案

- [x] 3.1 树洞 `ClinicAnswerBody` 默认 `selectable: true` + `MarkdownBlock`
- [x] 3.2 流式不强制可选；结束后 Markdown 可选

## 4. 回归

- [ ] 4.1 手工：长按松手后选区仍在；可拖动手柄复制；图标可填输入
- [ ] 4.2 手工：首页 tip 仍不可选、手势不受影响
