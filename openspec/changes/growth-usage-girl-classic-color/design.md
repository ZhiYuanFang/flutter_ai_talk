## Context

`growth-trajectory-predict` 已落地：账号维权益、wxID 日限、SSE 会话。缺口是客户端看不到用量、生成提示词仍要求「按日建议」。另需把女宝经典 `sexPrimary` 从 `#E91E63` 改为 `#2CB771`。

## Goals / Non-Goals

**Goals:**

- CTA 下展示「今日已用 {used}/{limit} 次」；用尽可点，超限 Toast。
- `latest` / `result` 带回 `usedToday`、`dailyLimit`（账号日限）。
- 生成 Markdown：整段 7 天注意点 + 多 emoji，禁止第 N 天日程。
- 女宝经典默认色 `#2CB771`。

**Non-Goals:**

- 不改开通主体（已是 user）；不改日限计数维度（已是 wxID）。
- 不强制迁移用户已存自定义主题色。
- 不本地拦截日限。

## Decisions

### 1. 用量字段挂在 latest 与 result

- **选择**：`usedToday`、`dailyLimit` int；Flutter 进页与预测成功后刷新。
- **理由**：避免单独轮询接口；与账号 Redis 计数同源。

### 2. UI 文案与交互

- 文案固定：`今日已用 $used/$limit 次`。
- 已开通且显示「轨迹预测」或「重新预测」时展示；未开通不展示。
- 用尽不灰按钮。

### 3. 生成结构

```
## 🌟 未来7天可能发生什么
## ⚠️ 这几天需要注意什么
## 🍼 结合近期喂养（可弱化）
## 💛 小结
```

禁止「第1天…第7天」；prompt + fallback 同步。

### 4. 女宝色

- 改 `sexPrimary(BabySex.female)` → `Color(0xFF2CB771)`。
- 仅默认经典路径；自定义 seed 优先逻辑不变。

## Risks / Trade-offs

- [旧客户端忽略新字段] → 向后兼容可选字段。
- [女宝已用经典主题的用户冷启动变绿] → 预期产品变更；有自定义色者不变。

## Migration Plan

1. Go 回传用量字段 → Flutter 展示。
2. Python 发版提示词。
3. Flutter 改 `sexPrimary`。
4. 回滚：隐藏小字 / 还原色值常量即可。

## Open Questions

- （无）用量维度与权益主体已确认跟账号。
