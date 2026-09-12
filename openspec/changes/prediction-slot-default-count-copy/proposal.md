## Why

预测槽位满额弹框只说「已开启 N 个」，用户不知道这 N 个是否为系统默认赠送。服务端功能定义里已有 `default_allowed_count`（合成 `allowedCount = default + permanentDelta`），但 App catalog **未下发**默认条数，客户端无法区分「仍在默认额度」与「加购后顶满」。需要在 catalog 暴露 `defaultCount`，并仅在可判定为默认额度时使用「默认已开启」文案。

## What Changes

- **Go（先）**：`GET /cash/app/api/feature/catalog` 预测项（及适用项）响应增加 `defaultCount`（来自功能定义 `default_allowed_count` / `DefaultAllowedCount`）；闸门合成逻辑不变。
- **Flutter（后）**：解析 `FeatureCatalogItem.defaultCount`；满额弹框当 `defaultCount != null && enabledCount == defaultCount && defaultCount > 0` 时文案为「默认已开启…」；**无/缺 `defaultCount` 时永远不说「默认」**（沿用「已开启…」或零槽位文案）。
- 槽位闸门、对齐裁剪、Hub 徽章仍只认 `allowedCount`；`defaultCount` **仅**服务文案判定。
- 实现顺序硬约束：**先合 Go 再合 Flutter**。

## Capabilities

### New Capabilities

- `prediction-catalog-default-count`：catalog 下发 `defaultCount`；客户端缺字段不得写「默认」；相等时满额弹框「默认已开启」。

### Modified Capabilities

- `prediction-toggle-slot-gate`：满额弹框 message 按 `defaultCount` 分支（闸门条件本身不变）。

## Impact

- Go：`go_ai_talk` — `api/v1/cash_feature_http.go`、`feature_catalog.go`、`cash_feature_controller.go` Catalog 映射。
- Flutter：`feature_unlock_models.dart`、`feature_unlock_provider`（可选暴露）、`smart_prediction_screen.dart` 弹框文案。
- 兄弟仓联调：旧 Go 无字段时 Flutter fallback 不说「默认」。
- 不新建测试；不改 Android/R8。
