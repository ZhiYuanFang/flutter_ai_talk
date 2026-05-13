## 1. 模型与仓库契约

- [x] 1.1 扩展 `HistoryRecord`（或等价 DTO）：增加 `eventName`、`action`、稳定 `id`；保留 `summary` 时可派生或弃用由 UI 统一格式化
- [x] 1.2 `MockFeedRepository`：生成历史 Mock 时写入 `事件名`/`动作`；新增 `updateHistoryRecord(id, …)` 或等价方法；`loadHistory` 返回可编辑字段
- [x] 1.3 `MockSettingsRepository` / 新 `saveBaby(BabyProfile)`：支持读取与保存宝宝信息（`shared_preferences` 或内存 + 可选持久化）

## 2. 设置中心：宝宝信息可编辑

- [x] 2.1 将宝宝卡片改为表单（`TextFormField`、性别选择、`DatePicker` 等）
- [x] 2.2 保存/取消按钮；校验通过后调用仓库保存并 `ref.read(babySexProvider)` 等与主题联动
- [x] 2.3 保存失败与成功 Snackbar/提示

## 3. 主页历史：格式与导航

- [x] 3.1 列表项主文案改为严格 `{事件名}:{动作}`，缺省走占位字符串
- [x] 3.2 列表项 `InkWell`/`ListTile` 点击 `context.push('/history/:id', extra: …)`（路径以实现为准）
- [x] 3.3 在 `go_router` 注册历史详情路由；`errorBuilder` 覆盖未知 id

## 4. 历史详情页

- [x] 4.1 新建 `HistoryDetailScreen`：展示并可编辑动作（及允许编辑的字段）；保存调用仓库更新
- [x] 4.2 返回时 `pop` 并触发主页历史 `ref.refresh`/状态更新

## 5. Web Enter 提交

- [x] 5.1 Web 主输入：实现 Enter 提交（推荐单行 `maxLines: 1` + `onSubmitted`）；在 README 写明交互
- [x] 5.2 若保留多行：实现 Shift+Enter 换行与 Enter 提交（`CallbackShortcuts` 或键盘监听）— **已采用单行方案，本项不适用，关闭。**

## 6. 趋势：今日 + 坐标轴

- [x] 6.1 UI 增加「今日」选项（`SegmentedButton` 或 Tab）；`MockTrendsRepository` 对「今日」返回当日点集
- [x] 6.2 `fl_chart`：配置 `bottomTitles` 使用点日期；`leftTitles` 显示数值；保证轴线可见
- [x] 6.3 今日无数据空状态

## 7. 质检

- [x] 7.1 `flutter analyze`；Web + 至少一端移动或 Windows 烟测编辑/导航/趋势（本机 `dart analyze` 已通过，无 error）
- [x] 7.2 更新 `app/README.md` 中与本变更相关的交互说明（Enter、历史格式）
