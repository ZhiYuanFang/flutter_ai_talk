## Context

竖屏语音球（`PredictionVoiceEdgeDock`）与 binder 现挂在 `SmartPredictionScreen`；`syncLandscapeVoiceLifecycle` 的 `want` 硬依赖 `predictionVisible`。主壳为 `UcgHomeShell` → `PageView`（喂养 / 预测 / UCG）。喂养页已锁死按钮模式，壳内无常驻按住 ASR。推入伴侣/成长/设置时主壳仍挂载但被上层路由盖住。

## Goals / Non-Goals

**Goals:**

- 主壳三页竖屏常驻同一贴边球与字幕；切页不断会话。
- 推入子路由或离开主壳路由时 deactivate，避免与子页麦冲突。
- UCG 未合格时不把球叠在资格锁上。
- 预测页去掉竖屏球，杜绝双实例。

**Non-Goals:**

- 不升横屏 chip；不改 chat/KWS 协议；不做全 App Overlay；不做喂养 ASR 细粒度仲裁。

## Decisions

### D1：宿主 = `UcgHomeShell` Stack

```
PopScope
  Stack
    ├ PageView（三页）
    └ 竖屏语音层（OrientationBuilder / MediaQuery）
         binder + EdgeDock + 字幕
```

比 `MaterialApp.builder` 更贴「主壳即可」；推入路由自然盖住球。

### D2：`sync` 表面语义拆分

- 横屏：仍传 `surfaceVisible: predictionVisible`（参数可改名，兼容旧名）。
- 竖屏：`surfaceVisible: ModalRoute.of(context)?.isCurrent == true`（主壳为当前路由）。
- 竖屏 UI 是否展示另受「UCG 未合格」约束；未展示球时 binder 仍可按 surfaceVisible activate——**或** 未合格时 surfaceVisible 视为 false。

**定案**：UCG 未合格时竖屏 `surfaceVisible=false`（藏球 + deactivate），避免锁页后台听麦。

### D3：横屏本 change 不动

横屏 chip/binder 留在预测页；`predictionVisible` 门禁保留。

### D4：组件搬迁

优先：把 `_LandscapeVoiceLifecycleBinder` / 竖屏字幕 toast 抽到可被壳 import 的公开/库内文件（或壳内复制最小 binder），预测页只保留横屏私有 chip。避免壳依赖 `smart_prediction_screen.dart` 的 private 类。

### D5：Orientation

壳层用 `MediaQuery.orientation`：竖屏才挂球层；横屏主壳不挂竖屏球（横屏 chip 仍在预测页）。

## Risks / Trade-offs

- [双 binder 竞态] → 主壳仅在 `isPortrait` 时挂竖屏 binder；横屏完全交给预测页，避免 deactivate 冲掉字幕/会话。
- [isCurrent 漏检] → binder 在 `didChangeDependencies` / route 回调里重 sync。
- [球挡喂养底栏] → 沿用既有默认左下 + 用户可拖；不做本 change 专属避让。

## Migration Plan

- 纯客户端；回滚即恢复预测页挂载与 `predictionVisible` want。

## Open Questions

- （无）explore 已拍板。
