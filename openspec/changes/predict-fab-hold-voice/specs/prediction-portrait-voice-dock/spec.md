## ADDED Requirements

### Requirement: Portrait prediction MUST NOT show an EdgeDock voice ball

On the home shell in **portrait**, the client MUST NOT present a prediction-voice `EdgeDockShell` ball (`PredictionVoiceEdgeDock` or equivalent), MUST NOT keep `kPredictionPortraitVoiceEnabled` (or equivalent) as a shipping gate for that ball, and MUST NOT activate wake-word listening solely because the home shell is visible in portrait. Portrait hands-free/record voice entry MUST be the go-record pill long-press PTT described by `prediction-fab-hold-voice` / `prediction-go-record-fab`. **Landscape** prediction voice (fixed listen chip + KWS) MUST remain available independently.

主壳竖屏 MUST NOT 展示预测语音贴边球，MUST NOT 再以 portrait 编译开关作为该球发版门禁，MUST NOT 仅因竖屏壳可见而启唤醒；竖屏语音入口 MUST 为「去记录」长按 PTT。横屏语音 MUST 不受影响。

#### Scenario: No portrait dock

- **WHEN** 用户在主壳竖屏预测相关表面
- **THEN** UI MUST NOT 展示可拖动的预测语音 EdgeDock 球
- **AND** MUST NOT 因竖屏壳可见而启动「胖宝」唤醒监听

#### Scenario: Landscape chip unaffected

- **WHEN** 用户在智能预测页横屏且语音入口可见
- **THEN** UI MUST 仍可展示固定监听 chip（按 `prediction-landscape-voice`）

## REMOVED Requirements

### Requirement: Portrait prediction voice entry MUST use EdgeDockShell

**Reason**: 竖屏入口改为「去记录」长按 PTT，不再维护贴边唤醒球。
**Migration**: 删除 `PredictionVoiceEdgeDock` 挂载与相关 store/engage；引导改走 FAB 心跳与长按。

### Requirement: Peek tap MUST only engage; peek MUST omit long caption

**Reason**: 竖屏球删除后 peek/engaged 交互不再存在。
**Migration**: 无；竖屏听写走 FAB PTT。

### Requirement: Portrait voice dock position MUST persist via HomeInputDockStore semantics

**Reason**: 不再有竖屏语音球位置需要持久化。
**Migration**: 可删除或忽略预测语音球专用 key；勿再读入 UI。

### Requirement: Portrait voice subtitle toast MUST be independent of the dock

**Reason**: 球已删除；字幕改由 FAB PTT 会话挂载。
**Migration**: 竖屏字幕按 `prediction-fab-hold-voice` 复用 `LandscapeVoiceSubtitleToast` 独立布局。

### Requirement: Portrait voice dock pointer MUST block home PageView swipe

**Reason**: 无竖屏球热区。
**Migration**: FAB 长按期间若需锁滑，在 FAB 手势内单独处理（可选，非本 REMOVED 替代硬性要求）。

### Requirement: Portrait voice dock drag MUST reposition from any shell state

**Reason**: 无竖屏球拖动。
**Migration**: 无。

### Requirement: Portrait prediction voice MAY be gated off without landscape impact

**Reason**: 删除 portrait 球 flag；竖屏不再提供 EdgeDock 语音入口。
**Migration**: 移除 `kPredictionPortraitVoiceEnabled`；横屏仍由 `kPredictionLandscapeVoiceEnabled` 门禁。
