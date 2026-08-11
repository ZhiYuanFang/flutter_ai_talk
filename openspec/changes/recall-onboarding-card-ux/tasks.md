## 1. 流程与种子

- [x] 1.1 打字机播完（含跳过动画补全文）后约 400ms 自动 `_advanceToNextRoot`；调整思考底栏按钮语义
- [x] 1.2 确认写种子时 `leafEventId = root.id`；思考文案去掉「具体是叶」；可移除选叶状态

## 2. 子事件与视觉

- [x] 2.1 「该事件包含」只读区：仅 `childrenOf` 非空时展示；无 ChoiceChip 选择
- [x] 2.2 标题行 `EventLogo` + 事件名；`_FloatingCard` 传入 `resolveEventColor` 作为 `eventAccent`（业务卡与思考盖层）

## 3. 校验

- [x] 3.1 `dart analyze` 触及文件无新增 error
- [ ] 3.2 手工：确认→思考完自动下一卡；有/无子事件展示；logo 与事件色可见
