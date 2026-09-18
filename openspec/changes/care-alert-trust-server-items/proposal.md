## Why

喂养记录分析在 SSE 思考流结束后，思考区正确清空，但列表不刷新；退出再进（hydrate GET latest）才能看到结果。根因是派生列表用本地上海日键与服务端 `day`（现网为带时分的生成时刻字符串，如 `2026-09-17 14:03`）做相等比较，误判为跨日过期而返回空列表。本地 dayKey 过滤是预测页跑马灯时代的遗留；迁到喂养工作台且取消自动 daily 后已无产品必要，应直接信任服务端返回的 items。

## What Changes

- 去掉 `predictionCareAlertProvider`（及等价展示路径）上「`dayKey` ≠ 今日上海日键则列表为空」的本地过滤。
- 喂养工作台在 `ready && !loading && !failed` 时，**必须**展示服务端快照中的 `items`（仍可保留与推演关闭集合无关的既有过滤，若存在）。
- `day` / `dayKey` 不再作为「是否展示列表」的判定条件；流式 result 与 hydrate 路径在展示语义上对齐为「信服务端 items」。
- 不改 Go/Python API 契约；不改日限、资格、思考流协议。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-care-alert`：明确喂养分析列表展示以服务端 daily/stream 返回的 `items` 为准，客户端 **不得** 因本地日键与服务端 `day` 字段不一致而丢弃已成功写入的快照。

## Impact

- 代码：`app/lib/providers/prediction_care_alert_provider.dart`（派生 provider）；喂养页已消费该列表，行为随派生修复。
- 不影响：SSE 思考展示、`AiThinkingPane`、资格/开通门禁、用量文案、GET latest hydrate。
- 残留产品取舍：App 长时间停留在喂养页并跨过 0 点时，可能仍显示本次会话内已加载的快照，直至退出再进或再次分析——与「信服务端 / hydrate」策略一致，可接受。
