## Why

智能预测竖屏把监听麦克风固定在左下角胶囊，挡内容且无法贴边收起；仓库已有统一 `EdgeDockShell`（喂养输入球曾用，现喂养页已不挂）。需要把竖屏麦克风改成可拖动贴边球，并复用闲置的 `HomeInputDockStore` 存位置。

## What Changes

- 竖屏预测：监听入口改为 `EdgeDockShell` 球（peek 半圆 / engaged 全圆 / floating）；默认初位**左下**贴边 peek。
- peek 点按**仅展开**为 engaged，**不得**触发听/权限业务；半圆态**省略**长 `statusCaption`。
- engaged / floating 点按走既有 `onListenChipTap`；短文案显示在球旁或球下。
- 字幕 toast **独立**定位（不随球），不挡球。
- **横屏**继续固定 `_LandscapeVoiceListenChip`，不包 EdgeDockShell。
- **BREAKING（存储语义）**：`HomeInputDockStore`（及 `home_input_dock_v1_*` 或 bump 后的 key）改为**仅服务预测竖屏语音球**；不再表示喂养输入模式球。无有效存档时默认左下；旧喂养右缘存档**不继承**为预测初位（bump key 或忽略旧默认）。
- 喂养页继续不挂 `HomeInputModeDock`（已有 `feeding-buttons-only`）；死代码可收敛/改名，但不得恢复喂养切模式球。

## Capabilities

### New Capabilities

- `prediction-portrait-voice-dock`：竖屏预测语音球贴边拖动、peek/engaged 交互、文案与字幕、位置持久化契约。

### Modified Capabilities

- `home-input-mode-dock`：废止「喂养页输入模式切换球」行为表述，标明位置存储已转交预测竖屏语音球（或 REMOVED 喂养相关 Requirement，避免与基线冲突）。
- `edge-dock-shell`：（无 Requirement 改动；本变更复用既有 peek/engaged/floating 基线，不扩壳。）

## Impact

- UI：`smart_prediction_screen.dart` 竖屏 Stack；新建薄宿主（可改造 `HomeInputModeDock` 或新 `PredictionVoiceDock`）包 `EdgeDockShell`。
- 存储：`home_input_dock_store.dart` / 默认常量（`kHomeInputDockDefaultEdge` → left）；可选 rename。
- 语音逻辑：复用 `landscapeVoiceControllerProvider` / `onListenChipTap`，不改 KWS/chat 管线。
- 对照基线 `openspec/specs/v2.1.0.md`：`edge-dock-shell`、`home-input-mode-dock`；喂养无 dock 见未归档 `feeding-buttons-only`。
- 无后端；不改 `app/android/**`；不新建 `**/test/**`。
