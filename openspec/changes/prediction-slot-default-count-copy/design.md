## Context

Go 功能定义已有 `default_allowed_count`，catalog 合成 `allowedCount = DefaultAllowedCount + PermanentDelta`，但 App `CashFeatureCatalogItem` / 控制器映射未带出默认条数。Flutter 满额弹框只能读 `allowedCount`，无法判断用户是否仍在「白送额度」。

本变更跨 `go_ai_talk` 与 `flutter_ai_talk`；制品落在 Flutter 仓 OpenSpec，Go 任务指向兄弟仓路径。

## Goals / Non-Goals

**Goals:**

- Catalog 预测项下发 `defaultCount`（非负整数；来自定义默认免费条数）。
- Flutter：`enabledCount == defaultCount`（且 defaultCount>0）时满额文案「默认已开启」；**缺字段时永远不出现「默认」二字**。
- 实现顺序：Go 先发/先合，再改 Flutter。

**Non-Goals:**

- 不改 `allowedCount` 合成公式、履约、VIP、槽位裁剪算法。
- 不改 Hub「已激活 X 个」徽章。
- 不把 `defaultCount` 当闸门上限。
- 不在本 Flutter 仓直接提交 Go 二进制；Go 改动在 `go_ai_talk` 完成。

## Decisions

### D1：JSON 字段名 `defaultCount`

**选择**：App catalog 项使用 `defaultCount`（用户约定），值 = 定义表 `DefaultAllowedCount`。  
**不选** `defaultAllowedCount`：与 Admin API 字段区分，App 契约更短；Admin 保持原名。

### D2：仅预测项必填语义

**选择**：`prediction_unlock` 必须带 `defaultCount`（可为 0）。其它功能项可省略或 0。Flutter 只对预测满额弹框读取。

### D3：文案分支（缺字段不说「默认」）

```
allowedCount <= 0
  → 当前还没有可开启的预测槽位。

defaultCount != null && defaultCount > 0 && enabledCount == defaultCount
  → 默认已开启 $defaultCount 个预测槽位。输入邀请码可开启更多。

否则（含无 defaultCount）
  → 已开启 $enabledCount 个预测槽位。输入邀请码开启更多槽位。
```

**禁止**：用 `allowedCount` 冒充默认；禁止在 `defaultCount == null` 时写「默认」。

### D4：发布顺序

1. Go 暴露字段并部署/联调环境可用  
2. Flutter 解析 + 文案  
旧客户端忽略新字段无害；新客户端对旧服 fallback 不说「默认」。

### D5：Go 改动面（最小）

- `FeatureCatalogItem` 增加 `DefaultCount *int` 或 `int` + json `defaultCount`
- `GetFeatureCatalog` 对预测项赋值 `d.DefaultAllowedCount`
- `v1.CashFeatureCatalogItem` + controller 映射

## Risks / Trade-offs

- [Flutter 先于 Go 发版] → 永远走非默认文案；可接受。任务顺序强制 Go→Flutter。
- [用户关部分默认槽再开满到 defaultCount] → 仍显示「默认已开启」；产品接受（比对数相等即可）。
- [加购后 allowedCount>default 但用户只开到 defaultCount] → 不满额闸（enabled < allowed），不弹框；无问题。

## Migration Plan

- Go：向前兼容加字段；回滚去掉字段即可。
- Flutter：缺字段 fallback；回滚恢复单一「已开启」文案。

## Open Questions

- 无（缺字段不说「默认」、先 Go 后 Flutter 已确认）。
