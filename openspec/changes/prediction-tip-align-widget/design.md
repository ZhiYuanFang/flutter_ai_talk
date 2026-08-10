## Context

预测页底栏 tip 经 `widgetTipCardTextProvider` → `peekWidgetTipDisplayText()`。当前 peek **要求** `kWidgetTipDayKey` 等于本地自然日，且文案非空；小组件侧（`resolveWidgetTip` 失败回退、`widget_interactivity` 重建）常在 **仅有 `kWidgetTipTextKey`** 时仍推 tip，导致「桌面有 tip、预测页无底栏」。另：`FutureProvider` 在 tip 写入前若已 peek 到 null，sync 写完后无 invalidate，底栏不刷新。跑马灯 `_pxPerSec = 36`，产品要求降为一半。

## Goals / Non-Goals

**Goals:**

- 预测页展示条件与小组件一致：trim 后 tip 正文非空即展示，不校验 dayKey。
- tip 写入 prefs / sync 推送 tip 后，预测页 tip provider 能重新读取。
- 横向跑马灯线速度约为现网一半。

**Non-Goals:**

- 不改 `fetchWidgetFeedingTip` / 拉取与日熔断策略。
- 不改陪伴注入的「当日 + injected_day」规则（`peekWidgetTipInjectText` 等仍按日）。
- 不恢复顶栏 tip 卡；不改底栏点击进陪伴。
- 不新建测试文件。

## Decisions

### D1：peek 去 day 门槛，仅看正文

`peekWidgetTipDisplayText`：读取 `kWidgetTipTextKey`，trim 非空则返回，**不再**比较 `kWidgetTipDayKey`。

- 与 `widget_interactivity`「有 text 即挂 tip」对齐。
- 空串 / 缺 key → null → 底栏隐藏（沿用现逻辑）。

备选：sync 失败回退时强制写今天的 dayKey——仍无法覆盖 interactivity 无 day 路径，且偏离「有则展示」字面；否决为唯一手段。

### D2：写 tip 后 bump 展示 epoch（等价 invalidate）

`home_widget_sync` 不得直接 import `smart_prediction_provider`（会经 `home_history` 形成循环依赖）。做法：独立 `widgetTipDisplayEpochProvider`；`syncHomeWidgetFromRef` 在 tip 正文非空时 `bumpWidgetTipDisplayEpoch`；`widgetTipCardTextProvider` `watch` 该 epoch 以重 peek。无 Riverpod `ref` 的 interactivity 磁盘重建路径可不强制（前台以 sync / 历史 watch 为主）。

备选：进预测页每次强制 `resolveWidgetTip`——额外副作用 HTTP，本变更不强制；展示对齐 prefs 即可。

### D3：跑马灯速度减半

`_BottomTipMarqueeState._pxPerSec`：`36.0` → `18.0`（时长公式不变，速度降半即周期约加倍）。动画时长 clamp 上下限可保持，除非实测撞到上限导致「感觉没降半」再微调 clamp。

## Risks / Trade-offs

- [跨日仍展示旧 tip] → 产品已接受「与小组件对齐、不判今日」；登出仍 `clearWidgetTipCache`。
- [invalidate 遗漏某写路径] → 以 `resolveWidgetTip` 写 prefs 与主 sync 出口为必改；历史 watch 仍作二次 peek。
- [陪伴注入误用旧 tip] → 注入仍走按日 `peekWidgetTipInjectText`，本变更不放宽。

## Migration Plan

- 纯客户端行为；热重载/重装即可验证。回滚：恢复 day 判断与 `_pxPerSec = 36`。

## Open Questions

- （无）展示去 day、速度减半已冻结。
