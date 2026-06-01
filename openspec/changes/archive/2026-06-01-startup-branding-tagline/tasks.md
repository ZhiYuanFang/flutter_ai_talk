## 1. 常量与组件

- [x] 1.1 在 `startup_branding.dart` 增加 `kStartupTagline`、`kStartupTaglineRevealDuration`（1500ms）
- [x] 1.2 新建 `StartupTaglineReveal`：单次 AnimationController，easeOut 插值字号 14→21、字重 w400→w700、primary alpha 0.45→1.0

## 2. 集成遮罩

- [x] 2.1 `StartupBrandingOverlay` 改为 `Column`：Logo + 间距 + `StartupTaglineReveal`
- [x] 2.2 确认 overlay 淡出时标语与 Logo 一并透明（沿用现有 `AnimatedOpacity`）

## 3. 验证

- [x] 3.1 冷启动：1.5s 内标语明显变大变粗；2.4s 前保持终态；淡出时同步消失
- [x] 3.2 主色随性别主题（男/女/未知）可读；Release 包目测无布局溢出
