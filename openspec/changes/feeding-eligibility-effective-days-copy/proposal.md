## Why

值得留意卡片与 UCG 入场浮层未合格态目前只强调「还需 Y 天」，用户看不到已完成多少有效喂养日。对齐 Go `feeding-eligibility-yesterday-anchor`：用 `effectiveDays` / `requiredDays` / `remainingDays` 客户端自拼进度。

## What Changes

- `FeedingEligibilityProgressText` 改为两行：
  - 第一行：已累计 **X** / **N** 天有效喂养（`effectiveDays` / `requiredDays`，数字强调）
  - 第二行：还需 … **Y** 天 …（`remainingDays` + 场景文案，数字强调）
- 值得留意与 UCG 入场共用该 Widget（`kind` 仅换第二行目标句）。
- 不以服务端 `message` 为进度数字权威；不向用户声明「今日不计入」。
- 不新建测试。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feeding-eligibility-progress-copy`：未合格进度文案 MUST 同时展示已累计与剩余。

## Impact

- `app/lib/ui/widgets/feeding_eligibility_progress_text.dart`（及已挂载的 UCG / 值得留意调用点，通常无需改签名）。
- 对照 Go cash eligibility 字段契约。
