## Context

`prediction-demo-skeleton-and-recall-dialog` 已实现冷态骨架与量身定做 Dialog（软关再弹 + finale 永久关）。未登录/未绑定仅有骨架，无粘性 CTA。产品要求补登录与绑定 Dialog，交互同软强制，但**没有**永久不再弹。

## Goals / Non-Goals

**Goals:**

- 未登录 → 登录引导 Dialog；已登录无 deviceNo → 绑定引导 Dialog。
- 软关 / 非头像再弹 / 头像进设置；条件解除即停。
- 与量身定做互斥；底层骨架不变。

**Non-Goals:**

- 不改喂养页全屏绑定 Gallery。
- 不给登录/绑定 Dialog 增加「我知道了」永久 dismissed。
- 不改量身定做 finale 语义。
- 不新建 `**/test/**`。

## Decisions

### D1：优先级与互斥

```
if !loggedIn → login dialog
else if !bound (no deviceNo) → bind dialog
else if empty history → recall dialog (existing)
else → none
```

实现上可用单一 `predictionGateKind`（login | bind | recall | none）或三个 visible flag 保证同时最多一个为 true。

### D2：无永久 dismissed

- 登录/绑定仅用 `dialogVisible`（软关 false，再弹 true）。
- **不得**引入类似 `predictionRecallFinaleDismissedProvider` 的永久标志。
- 条件仍满足时，进入预测页默认 `visible=true`；软关后靠再弹恢复。

### D3：CTA 路由

- 登录：`/login`（与头像未登录门一致）。
- 绑定：`/settings/bind-baby`（对齐 `HomeScreen._onBindBannerTap`）。
- 文案可贴近喂养：「尚未登录 / 去登录」「嗨我是胖宝 / 立即绑定宝宝」。

### D4：复用交互壳

- 复用预测页 Stack：遮罩 + Visibility(maintainState) + 主体 **GestureDetector.onTap** 再弹；头像在 tap 热区外。
- 再弹 MUST 由点击（tap/click）触发；MUST NOT 仅因 `pointerDown`/触碰按下就再弹（避免滑动浏览误开）。
- 登录/绑定内容为简单卡片（标题 + 说明 + 主按钮），无需 PageView。
- 量身定做再弹热区与登录/绑定共用同一 onTap，按当前 gate kind 决定再弹哪一个。

### D5：条件解除

- `ref.listen` session / deviceNo：一旦 loggedIn 或 bound，关闭对应 Dialog 并清除 visible；若刚登录仍未绑定，切换为绑定 Dialog（visible=true）。

## Risks / Trade-offs

- [软关热区过宽] → 与量身定做相同，产品已接受。
- [从登录页返回仍未登录] → 仍应再弹；默认 visible 或返回后点击再弹均可。
- [与 recall 状态机打架] → 严格 D1 优先级；未绑定不得 `recallSession=true`。

## Migration Plan

- 纯客户端。回滚：移除登录/绑定 Dialog，保留骨架。

## Open Questions

- （无）永久关与未登录策略已拍板。
