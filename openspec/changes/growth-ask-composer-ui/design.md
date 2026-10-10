## Context

`growth-trajectory-voice-input` 已在追问态接入 `HomeSpeechRecognizer` + 全局 ASR。首页已有 `HomeVoiceLevelBars`（绑 `colorScheme.primary`）。本 change 做追问 composer UX，并抽出可传 accent 的共享能量条原子供轨迹使用。

## Goals / Non-Goals

**Goals:**

- 追问 TextField：自适应增高，maxHeight=120，触顶跟滚底，松手后可滚动编辑。
- 输入框 + 按住条：功能色浅玻璃。
- 按住时左右能量条；抽出全局 `VoiceLevelBars` 原子；轨迹先用。

**Non-Goals:**

- 最大语音时长。
- 迁移首页 `HomeVoiceLevelBars`（后迁）。
- 改 ASR / chat/ws / 自动提交。

## Decisions

### D1：输入框高度

- 内容增高，**最大高度 120**（逻辑像素）。
- 文案增长且贴底时 scroll 到 maxScrollExtent；用户上翻后不强制抢滚（实现可选：仅程序写入/语音 partial 时跟底）。
- 语音结束后保持可滚动、可键盘编辑。

### D2：功能色浅玻璃

- accent = `resolveFeatureColor`（成长 catalog）。
- 输入壳与按住条：浅透底 + 功能色描边/tint（对齐工作台功能色浅玻璃习惯，可用 `Color.lerp` / 低 alpha accent 叠在 surface 上）；文案用加深 accent（既有 `_gtDeepenAccent` 或等价）。
- **禁止** 仅靠默认 `OutlineInputBorder` 灰框作为最终主视觉。

### D3：VoiceLevelBars 原子

```
VoiceLevelBars(
  level: 0..1,
  accent: Color,      // 轨迹传功能色；取消态可用 error
  cancelled: bool,
  maxBarHeight: ...,
)
```

- 柱形系数可复用 `kHomeVoiceLevelBarWobble`（或迁入原子旁常量）。
- 平滑：`VoiceLevelSmoother` + `ValueNotifier`。
- 轨迹按住条布局：`[bars][按住条][bars]`；未按住可不显示条或 level=0。
- 首页本 change **不改**。

### D4：无最大录音时长

- 按住直至松手/取消/离开会话；不设客户端最长秒数。

## Risks / Trade-offs

- **[Trade-off] 首页暂双轨** → 原子与 `HomeVoiceLevelBars` 短期并存；后迁删旧。
- **[Risk] 跟滚与用户上翻冲突** → 仅在语音写入/贴底时跟滚。

## Migration Plan

1. 制品确认后 apply。
2. 后续 change 将首页球两侧改为 `VoiceLevelBars`。

## Open Questions

- （无）
