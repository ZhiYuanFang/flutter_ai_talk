## Context

主壳满意度 sheet 已经按 `home-satisfaction-survey` 上线：每个选项一个勾选，提交 `{ campaignId, optionIds, comment }`。兄弟仓按选项 id 回表，把库里的原文写入 `option_snapshot`，评价中文没有字段可放。

本次由客户端把「未使用 / 不好用 / 好用」直接接在选项原文后面，提交字符串数组。服务端契约在 `go_ai_talk` 的 `survey-submit-option-results`。GET、喂养缓存门闩、弹出时机和按钮上方错误都不改交互形态。

## Goals / Non-Goals

**Goals:**

- 每个选项三个互斥评价，未点的行保持未选。
- 有选项时必须每行都评完才 POST；意见可空。没有选项时仍可只写意见。
- POST body 为 `campaignId`、`optionResults`、`comment`。

**Non-Goals:**

- 不改 `GET /device/app/api/survey/current` 的字段。
- 不在客户端判断活动日期或是否已提交。
- 不改 Hub，不新增日志 tag，不改 Android。
- 不把评价单独放进 `comment`。

## Decisions

### D1：三选一，未选不是「未使用」

- **选择**：每行三个互斥项，初值为未选。提交时未选行不生成「原文未使用」。
- **理由**：三个词都是用户的明确评价。
- **备选**：不点等于未使用 → 会把没看的行记成未使用，拒绝。

### D2：有选项则逐行必填

- **选择**：只提交点过的行，顺序跟 `options`。一项都没选且意见为空白才不 POST。只写意见，或只评其中几行且意见为空，都可以提交。
- **理由**：服务端本来就接受选项结果的子集。没点的行不补评价。

### D3：原文与评价直接拼接

- **选择**：`optionResults[i]` = 该行 current 返回的 `text` + `未使用` 或 `不好用` 或 `好用`，中间无空格、标点或括号。顺序与 sheet 上的选项顺序一致，也就是 current 的 `options` 顺序。
- **理由**：与 Go 的「启用选项原文 + 三个后缀之一」校验一致。
- **备选**：用分隔符 → 服务端对不上库里的原文，拒绝。

### D4：不再发送 optionIds

- **选择**：仓库 POST 只带 `optionResults`。
- **理由**：id 列表无法表达评价；Go 不再用它写快照。

### D5：错误仍在按钮上方

- **选择**：未评完、双空、超长、业务错误和网络错误都写 sheet 内的错误行，不 toast。改任一评价或改意见时清掉该行。控制器仍由 sheet State 创建并在 `dispose` 释放。
- **理由**：延续已上线的提交反馈。

## Risks / Trade-offs

- [Go 先上线时，仍传 `optionIds` 的旧包不会写入选项快照] → Flutter 与 Go 一起发布。
- [选项文案在 GET 与 POST 之间被 Hub 改掉] → 客户端拼的是当时看到的原文，服务端对不上新文案会拒绝；用户看到按钮上方的失败文案后可关掉 sheet，下次冷启动再取新文案。
- [两个选项原文加上不同后缀拼出同一字符串] → 客户端仍发送用户看到的那一行；是否接受由服务端按「至少一个启用选项能对上」决定。

## Migration Plan

与 `survey-submit-option-results` 同一轮发布。不写本地迁移。回退时需要 App 与提交字段一起回到 `optionIds`。

## Open Questions

无。评价文案、拼接方式和「每行必选」已在探索中确定。
