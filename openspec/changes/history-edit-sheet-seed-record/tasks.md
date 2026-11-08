## 1. 编辑 Sheet 种子路径

- [x] 1.1 `showHomeHistoryEditSheet` / body：传入种子 `HistoryRecord`；`_resolveRecord` 近窗优先，未命中用匹配种子起表
- [x] 1.2 无近窗且无匹配种子：保持错误提示；有种子时不得「记录不存在」并 pop

## 2. 保存 / 删除

- [x] 2.1 确认窗外种子保存：update API 成功即关 sheet；`replaceRecord` 无 id 时 noop，不强制 insert 近窗
- [x] 2.2 确认窗外种子删除：delete API 成功即关 sheet；近窗无 id 不视为失败

## 3. 预约联调

- [x] 3.1 预约卡点上次（近窗外记录）：可打开编辑、可保存；不再「记录不存在」
