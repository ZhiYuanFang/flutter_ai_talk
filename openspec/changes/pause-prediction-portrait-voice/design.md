## Context

竖屏预测语音入口（`PredictionVoiceEdgeDock`）与横屏共用 `landscapeVoiceControllerProvider`。当前 `_LandscapeVoiceLifecycleBinder._sync` 写死 `landscape: true`，使竖屏在预测页可见时也会 `activate` 并可能请求麦克风。对话模型未就绪，需临时关竖屏表面。

对照基线 `openspec/specs/v2.1.0.md` 与既有 `prediction-portrait-voice-edge-dock` 契约；本变更仅加暂停闸门。

## Goals / Non-Goals

**Goals**

- 竖屏：无语音 UI、不 activate、不因竖屏预测要麦。
- 横屏：监听 chip + 会话保持可用。
- 一处编译期 flag，注释写明原因与翻回方式。

**Non-Goals**

- 不删除贴边球实现 / 存储 / `PredictionVoiceEdgeDock` 代码。
- 不改 KWS / chat WS 协议。
- 不关喂养页语音、不关横屏语音。

## Decisions

### D1：编译期 flag

- `kPredictionPortraitVoiceEnabled = false`（命名可微调；与 UCG flags 同文件或邻近预测 flags）。
- `false`：竖屏不挂 binder/dock/字幕；lifecycle 仅当真实横屏且预测可见时 activate。
- `true`：恢复现有竖屏贴边球与字幕行为。

### D2：修正 binder 传参

- `_sync` **必须**使用 `widget.landscape`，删除写死 `true`。
- 竖屏分支在 flag 关闭时 **不挂载** binder（或挂载但 `landscape: false` 且无 UI）；推荐不挂载竖屏语音层，避免无意义 sync。
- 横屏分支继续挂 binder（`landscape: true`）+ chip。

### D3：watch 范围

- 竖屏 flag 关：可不 watch `landscapeVoiceControllerProvider`（仅横屏 watch），减少竖屏重建；或统一 watch 但竖屏不渲染——以最小改为准。

## Risks / Trade-offs

- 用户从竖屏旋转到横屏：依赖横屏 binder `didUpdateWidget` / 横屏树挂载后 sync；保持现有横屏路径即可。
- flag 与「写死 true」若只改其一，会漏关副作用或误关横屏——tasks 须两项都做。

## Migration Plan

- 默认 `false` 即暂停。
- 模型就绪：改 `true` + 热更/发版；无需数据迁移。
