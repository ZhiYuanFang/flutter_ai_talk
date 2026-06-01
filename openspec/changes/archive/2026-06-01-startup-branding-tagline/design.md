## Context

- **现状**：`StartupBrandingOverlay` 全屏 `#ECEFF1`，居中 `SplashLogoPulse`（1.1s 循环心跳 + 主色光晕）；遮罩最短展示 `kMinStartupBrandingDisplay`（2400ms）后淡出 350ms。
- **主题**：遮罩位于 `MaterialApp.builder` 内，可读 `Theme.of(context).colorScheme.primary`；冷启动初期可能为 `BabySex.unknown` 默认主色，bootstrap 写入缓存性别后会 rebuild（标语颜色可随之更新）。
- **约束**：不延长冷启动 gate；标语动画与 Logo 心跳 **解耦**（心跳 repeat，标语单次 reveal）。

## Goals / Non-Goals

**Goals:**

- Logo 下方展示「最懂你的胖宝」。
- **1.5s 内** 动画到位：字号增大、字重加粗、主色 alpha 从约 45% → 100%。
- 1.5s 后保持终态，直至 overlay `AnimatedOpacity` 淡出。
- 颜色绑定 `colorScheme.primary`。

**Non-Goals:**

- 修改原生 Splash、2.4s 最短展示、bootstrap 路由逻辑。
- 多语言/i18n（首版固定中文文案）。
- 标语与心跳同步缩放。

## Decisions

1. **布局**  
   `Column(mainAxisSize: min)`：`SplashLogoPulse` → 间距 20–24 → 标语 widget。

2. **动画控制器**  
   新建 `StartupTaglineReveal`（StatefulWidget）：
   - `AnimationController(duration: 1500ms)`，`forward()` 一次，不 repeat。
   - 曲线：`Curves.easeOut`（前段变化明显，末段 settling）。

3. **插值**  
   | 属性 | t=0 | t=1（1.5s） |
   |------|-----|-------------|
   | fontSize | 14 | 21 |
   | fontWeight | w400 | w700（`FontWeight.lerp`） |
   | color | `primary @ 0.45` | `primary @ 1.0` |

4. **常量**  
   - `kStartupTagline = '最懂你的胖宝'`  
   - `kStartupTaglineRevealDuration = Duration(milliseconds: 1500)`  
   置于 `startup_branding.dart`。

5. **淡出**  
   父级 `StartupBrandingOverlay` 已有 `AnimatedOpacity`；标语作为子树一并淡出，无需独立控制器。

6. **性别主题跳变**  
   首版接受 bootstrap 写入 `cachedSex` 后 primary 变化导致标语颜色更新；不阻塞 overlay 等待主题（避免延迟展示）。

## Risks / Trade-offs

- **[Risk] 1.5s 时 overlay 已淡出** → 不会；淡出发生在 2.4s 后，标语有 ≥0.9s 停留终态。
- **[Risk] 小屏字号 21 换行** → 文案短，单行；必要时 `maxLines: 1`。
- **[Trade-off] 动画与 2.4s 最短展示不对齐** → 有意为之：1.5s 到位 + 0.9s 静态展示，可读性更好。

## Migration Plan

- 纯客户端 UI；无数据迁移。回滚即移除标语 widget。

## Open Questions

- （已决）动画 **1.5s 内到位**，之后保持终态。
