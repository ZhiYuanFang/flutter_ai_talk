## 1. 布局修复（`_HomeEmptyStateGallery`）

- [x] 1.1 将 `_HomeEmptyStateGallery` 根布局改为 `Center` + `Column(mainAxisSize: MainAxisSize.min)`，移除导致 iOS 溢出裁切的 `mainAxisSize: max` 默认行为
- [x] 1.2 用 `SizedBox(width: 240, height: 240)`（或等价硬约束）包裹 `Lottie.asset`，并设置 `clipBehavior: Clip.hardEdge`
- [x] 1.3 在 `Lottie.asset` 上设置 `addRepaintBoundary: false`，缓解 iOS 灰框问题

## 2. 动画槽兜底

- [x] 2.1 实现 `errorBuilder` 静态兜底（`Icon` 或 bundled `Image.asset`），尺寸与动画槽一致
- [x] 2.2 若 `{}` stub 在 iOS 不触发 `errorBuilder` 仍占满槽位，视情况增加 `frameBuilder` 或无效 composition 检测，确保灰块不超出 240×240 且文案可见

## 3. 资源（可选）

- [x] 3.1 若设计已提供正式 Lottie JSON，替换 `ani_baby_welcome.json` / `ani_baby_feeding_guide.json`；否则跳过并在 PR 说明中注明仍用 stub + 静态兜底

## 4. 验证

- [x] 4.1 iOS：未绑定且无记录 — 可见「嗨，我是胖宝！」、副标题、「立即绑定宝宝」且按钮可跳转绑定页
- [x] 4.2 iOS：已绑定且无记录 — 可见鼓励文案与副标题，动画槽不遮挡文字
- [x] 4.3 Android：上述两路径无回归（文案与按钮仍正常）
- [x] 4.4 小屏设备（如 iPhone SE 类）空状态内容不被底栏完全遮挡；若不足则加 `SingleChildScrollView`
