## 1. 主页 AppBar

- [x] 1.1 在 `AppBar.actions` 中、设置按钮前插入趋势 `IconButton`（`Icons.insights`，tooltip「趋势」，`push('/trends')`）
- [x] 1.2 确认 actions 顺序为：历史 WS → 趋势 → 设置

## 2. 底部输入区

- [x] 2.1 移除底部 `Stack` 内 `Positioned` 的 `FilledButton.tonalIcon`「趋势」
- [x] 2.2 确认语音球、字幕、输入模式切换布局无重叠或异常留白

## 3. 验证

- [x] 3.1 主页顶栏可见趋势图标，点击进入趋势页；底部无趋势按钮
- [x] 3.2 设置、历史 WS 图标行为与改前一致
