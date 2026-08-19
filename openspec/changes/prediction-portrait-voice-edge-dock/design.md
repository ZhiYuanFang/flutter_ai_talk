## Context

竖屏预测用固定 `Positioned` + `_LandscapeVoiceListenChip`（胶囊 + 长 caption）。横屏同族 chip 固定左下。仓库已有 `EdgeDockShell`（peek/engaged/floating）与闲置 `HomeInputDockStore`（喂养 `HomeInputModeDock` 已由 `feeding-buttons-only` 下线）。基线 `edge-dock-shell` 规定 peek 点按不得直达业务。

## Goals / Non-Goals

**Goals:**

- 仅竖屏：监听入口包 `EdgeDockShell`；可拖、可贴边半圆收起。
- peek：点按只 engage；无长文案。
- engaged/floating：点按 `onListenChipTap`；短 caption 在球旁或球下。
- 字幕 toast 独立底中（或等价不跟球）。
- 复用并改语义 `HomeInputDockStore`；默认初位左下；旧喂养右缘存档不继承。
- 横屏固定 chip 不变。

**Non-Goals:**

- 不改 KWS / voice-chat-ws / 麦克风权限用途框文案逻辑（仅入口手势与布局）。
- 不恢复喂养输入模式切换球。
- 不扩展 `EdgeDockShell` 支持非圆 child。
- 不新建 `**/test/**`；不改 `app/android/**`。

## Decisions

1. **薄宿主 + EdgeDockShell**  
   新建如 `PredictionVoiceEdgeDock`（或改造死代码 `HomeInputModeDock` 去掉 channel 轮转）：`bounds` 为竖屏可拖区（扣 SafeArea 与底栏约 86px）、`child` 为圆形 mic+连接点、`onInteractiveTap` → `onListenChipTap`、不挂 `onPullBusiness`（拉满仅 engage）。  
   备选（弃）：胶囊当 shell child — 半圆 clip 破坏布局。

2. **文案分层**  
   - peek：不渲染 `statusCaption`。  
   - engaged/floating：壳外 sibling 短文案（左贴→文案在右；右贴→在左；底/浮空→在下）；`maxLines: 1~2` + ellipsis。  
   备选（弃）：半圆仍显示长 caption。

3. **字幕 toast**  
   竖屏继续用 `_LandscapeVoiceSubtitleToast`，定位改为相对屏底居中（或固定 inset），**不得**按球 `Positioned` 避让。横屏字幕布局可不动。

4. **存储复用 + bump**  
   `HomeInputDockStore` 继续作为唯一位置 API；prefs key bump 为 `prediction_voice_dock_v1_*`（或读失败则清旧 `home_input_dock_v1_*`），默认 `DockEdge.left` + `along ≈ 0.85`（左下，bounds 内）。类名可 rename 为 `PredictionVoiceDockStore` 并保留 typedef/导出别名。  
   备选（弃）：直接读旧 v1 右缘位置 — 违背「默认左下」。

5. **横屏**  
   `isLandscape` 分支保持现有 `Positioned` chip；生命周期 binder 不变。

6. **规格**  
   新能力 `prediction-portrait-voice-dock`；对 `home-input-mode-dock` 用 REMOVED/MODIFIED 标明喂养球行为不再适用、存储转交预测球，避免基线双源。

## Risks / Trade-offs

- [peek 需两点才进听] → 产品已接受；对齐 edge-dock-shell。  
- [旧用户丢喂养球位置] → 有意；喂养已无球。  
- [短文案挡卡片] → ellipsis + 仅非 peek 显示；用户可贴边收起。  
- [与 PageView 横滑冲突] → shell 已有 `onPointerOccupied`；宿主若需可锁滑（预测页竖屏主内容多为竖滑列表，风险低）。

## Migration Plan

纯客户端。装新版后：无新 key → 左下 peek；有旧喂养 key → 不读或迁移丢弃。回滚：竖屏恢复固定 chip。

## Open Questions

- （无；prefs bump、默认左下、横屏不动、文案旁/下规则已定。）
