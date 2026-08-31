## Context

Go `feeding-eligibility-yesterday-anchor` 已要求 Flutter 用 `effectiveDays` 等字段拼进度。客户端 Widget 仍只渲染 `remainingDays`。

## Goals / Non-Goals

**Goals:** 未合格态两行进度：已累计 X/N + 还需 Y 天；UCG 与值得留意共用。

**Non-Goals:** 不改 eligibility HTTP；不解释「今日不计入」；不恢复已删的模型纯文本方法。

## Decisions

### D1：两行结构

1. `已累计 X / N 天有效喂养` — 强调 `effectiveDays` 与 `requiredDays`
2. 场景第二行 — 强调 `remainingDays`（UCG / careAlert 文案分）

### D2：数字强调

- `X`、`N`、`Y` 均用现有 `numberStyle`（放大 + 主题色），便于扫读。

### D3：边界

- `effectiveDays` / `remainingDays` / `requiredDays` 负值钳为 0；`requiredDays` 为 0 时仍展示字段值（罕见）。
- loading / failed 仍用纯文本兜底，不走本 Widget。

## Risks / Trade-offs

- [两行略高] → 值得留意卡与全屏浮层均可接受。

## Migration Plan

- 纯文案；无数据迁移。

## Open Questions

- 无。
