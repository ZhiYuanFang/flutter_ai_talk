## Context

`predict-capability-client` 在 3h 与列表间加了 `PredictCapabilityStatusCard`；`settle-gate` 要求 syncing 显示「正在同步能力中」。产品改为：档位并入 3h 标题后缀 + 全屏三档墙；整卡不再进喂养。

基线：`openspec/specs/v2.2.1.md` 中 `smart-prediction-page`（AI分析/点卡进喂养）、以及未合并的 client/settle-gate 状态卡 delta（本变更 supersede）。

## Goals / Non-Goals

**Goals:**

- 删除独立能力状态卡挂载。
- 3h 标题：`接下来3小时 · {间隔版|基础版|Pro版}`；仅后缀与 AI分析可点。
- 全屏三档墙 + `carousel_slider`；底栏态表（含 VIP / 试用 / 暂未开放）。
- syncing：后缀不展示最终档（「同步中」或隐藏后缀且不可开墙）。

**Non-Goals:**

- 不把 Hub 全能力塞进墙。
- 不上线 Pro 支付/试用。
- 不改双轨 entitle 计算（仅 UI 档位标签与墙）。
- 不为间隔版造 catalog 项或本地插画。

## Decisions

### D1：当前档标签

```
settle syncing → 后缀「同步中」（或等价）不可点开墙
pro 人权益有效 → · Pro版
else basic 有效 OR isVip → · 基础版
else → · 间隔版
```

打开墙时 `initialPage` = 当前档索引（间隔=0，基础=1，Pro=2）。

### D2：墙结构

- 全屏 route / `showGeneralDialog`；右上 `Icons.close`。
- `carousel_slider`：`viewportFraction`≈0.72–0.85；中卡 `enlargeCenterPage`。
- 单卡：上玻璃详情（圆角、能力色 tint）；下独立玻璃圆角底栏。
- 间隔：主题色；**无图**；文案说明固定间隔节奏；底栏见 D3。
- 基础/Pro：`item.logo` 非空才展示图；`resolveFeatureColor`；title/description 来自 catalog（可加客户端短说明）。

### D3：底栏态

| 卡 | 条件 | 文案 | 可点 |
|----|------|------|------|
| 间隔 | VIP | VIP已开通 | 否 |
| 间隔 | 非 VIP | 当前节奏（或「已启用」） | 否 |
| 基础 | basic 人权益有效 | 已开通 | 否 |
| 基础 | isVip 且无 basic 人权益 | VIP已开通 | 否 |
| 基础 | 非 VIP 未开通 | 开通试用 | 是 → `trial/start(basic)` |
| Pro | pro 人权益有效 | 已开通 | 否 |
| Pro | 否则 | 暂未开放 | 否 |

试用成功：刷新 catalog；可关墙或留在基础卡并切「已开通」；复用既有成功提示（天数）。失败：Toast。`trialAvailable==false` 且未开通时：可改为「立即开通」进 Hub，或仍隐藏试用——**默认**：无试用资格则底栏「立即开通」→ `/features/unlock`（弱推付费但仍给出路）。若产品只要试用、无资格则禁用：实现时优先「开通试用」仅当 `trialAvailable`；否则「立即开通」进 Hub。

### D4：3h 手势

- 去掉整卡 `onOpenFeeding`。
- 标题固定文案不可点；后缀 `InkWell`/`GestureDetector` 开墙。
- AI分析不变。

### D5：依赖

- `carousel_slider: ^5.x`（或 pub 最新兼容 SDK 3.5）；无原生 AAR，Release 一般无需新 ProGuard。

### D6：状态卡规格

- REMOVED 独立卡与「点卡进 Hub」。
- settle syncing 迁到 D1 后缀。

## Risks / Trade-offs

- [Risk] 失去点 3h 进喂养 → Mitigation：列表卡/底栏仍可达喂养；产品已确认。
- [Risk] VIP 显示 · 基础版但墙内 Pro「暂未开放」→ 符合「最高可用档=基础」。
- [Risk] logo 空 → 仅文；间隔故意无图。
- [Trade-off] 墙内无支付 Sheet → 无试用资格走 Hub。

## Migration Plan

- 纯客户端 UI + 依赖；无数据迁移。
- 与未归档 `predict-capability-client` 并存时：本变更实现后以本 UI 为准。

## Open Questions

- （已定）非 VIP 基础试用墙内直调 trial；Pro 非 VIP 未购也「暂未开放」。
- 无 `trialAvailable` 时默认「立即开通」进 Hub（见 D3）。
