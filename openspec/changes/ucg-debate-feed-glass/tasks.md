## 1. 假玻璃基础组件 [app]

- [x] 1.1 [app] 新增 `UcgFeedFakeGlassPanel`（渐变+白边+可选轻阴影，无 `BackdropFilter`）及共享 token 常量
- [x] 1.2 [app] 提供 `ucgFeedFakeGlass*` 文字/边框色 helper（对齐 `AppVisualTokens`）

## 2. 广场 Feed 卡片 [app]

- [x] 2.1 [app] `UcgDebateFeedCard` 由 `UcgSurfaceCard` 迁移至 `UcgFeedFakeGlassPanel`
- [x] 2.2 [app] 检查 `ucg_square_tab.dart` 辩论列表路径，确保推荐/关注均使用新卡片容器
- [x] 2.3 [app] `UcgDebateArgumentsBlock` 论点行轻 tint pill + 展开链样式与假玻璃卡协调

## 3. UcgDebateVsBar 可爱态 [app]

- [x] 3.1 [app] 移除 VS 条 `BackdropFilter`；应用马卡龙渐变、大圆角、增高软糖条
- [x] 3.2 [app] 中心徽章改为 emoji（默认 `✨`）+ `IgnorePointer`；选中侧加强白边/轻阴影
- [x] 3.3 [app] 百分比 sticker 样式（窄侧自适应布局保留）；确认色带热区仍为 per-side `GestureDetector`
- [x] 3.4 [app] 确认详情页、个人时间线、分享布局自动继承同一 `UcgDebateVsBar` 视觉

## 4. 分享离屏布局 [app]

- [x] 4.1 [app] `UcgDebateShareLayout` 改用 `UcgFeedFakeGlassPanel` 包裹，去掉孤立白底
- [ ] 4.2 [app] 分享 PNG 与广场卡片视觉对照验收（emoji、马卡龙、假玻璃边框）

## 5. 联调与验收

- [ ] 5.1 [app] Chrome/Web：推荐/关注滚动 20+ 条、投票、展开论点，确认无 blur 性能问题
- [ ] 5.2 [app] 手工：详情 VS 条与 Feed 同貌；分享成功/失败降级路径
- [x] 5.3 [app] 本变更未触及 `app/android/**`；无需 release 构建（若后续加 asset 再评估）
