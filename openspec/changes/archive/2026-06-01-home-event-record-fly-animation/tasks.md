## 1. 触发与状态

- [x] 1.1 在 `watchLatest` 监听中 upsert 前判断新增 record，scheduleFly
- [x] 1.2 引入 fly 状态：`flyTargetRecordId`、取消进行中动画、disableAnimations 分支
- [x] 1.3 从 catalog 解析 `EventDefinition` 供 Overlay 使用

## 2. 跟底与条件滚底（策略 B+）

- [x] 2.1 `HomeHistoryScroll` 暴露/复用跟底检测（距底阈值）；向 parent 回调 `onFollowLatestChanged`
- [x] 2.2 新 record 时：**仅** `_followLatest==true` 调用 `scrollToBottom`；非跟底不滚
- [x] 2.3 recordId logo 锚点 GlobalKey；飞行期间 logo 隐藏

## 3. 飞行 Overlay

- [x] 3.1 新建 `home_event_record_fly_overlay.dart`：中心放大 → 飞向终点
- [x] 3.2 跟底：终点=锚点中心；非跟底且锚点在视口外：终点=历史区底缘中心
- [x] 3.3 postFrame 测点 + 重试；`HomeScreen` Stack 顶层挂载

## 4. 回到底部按钮

- [x] 4.1 历史区 `Stack` 底缘正中：非跟底且非空时显示 **正圆** 悬浮按钮（直径 ~40–44px），圆内居中 `Icons.keyboard_arrow_down`（向下三角）
- [x] 4.2 点击 `animateTo` 最底并置 `_followLatest=true`
- [x] 4.3 视觉：`colorScheme.primary.withValues(alpha: 0.3)` 填充；描边为更深 primary（HSL 明度下调或 alphaBlend + `AppVisualTokens.pillBorder`）；读 `visualTokensOf(context)`，不硬编码色值；不遮挡输入区

## 5. 集成与验证

- [x] 5.1 连续新增取消上一动画；update/delete 不触发
- [x] 5.2 手工：跟底 add、非跟底 add（不滚但仍飞）、回底按钮、disableAnimations
- [x] 5.3 `flutter analyze` + `openspec validate home-event-record-fly-animation`
