## Context

热态卡在有真 `lastAt`、无 affinity prediction 时仍展示「补充大概多久一次」，经 `pickRecallIntervalMinutes` upsert `PredictionRecallSeed`，并由 `recallIntervalsByRoot` 喂入 predictor / widget。`align-go` D5 仅断「种子=展示轨」，仍保留可选 fallback。产品现要求硬删整栈。

无 nextAt 时已有亲和进度（`predict-affinity-progress`）可承接空态。

## Goals / Non-Goals

**Goals:**

- 删除卡面间隔 CTA 与调间隔入口及实现。
- 删除间隔 Sheet 文件与思考动画路径。
- 删除种子 model/store/provider 及所有 `recallIntervalsByRoot` 旁路传参。
- 删除 onboarding 写种子 /「大概多久一次」控件；补齐仅「补充上一次」+ 预约「补充下次」。
- 清理 prefs 遗留 key；编译无悬空引用。

**Non-Goals:**

- 不删「补充上一次」/ 预约「补充下次」。
- 不改亲和算法门槛本身（样本数等）。
- 不改 Go API。
- 不重建量身定做 Dialog 自动弹出（基线已禁止）。

## Decisions

### D1：硬删优于藏 UI

- 隐藏钮但留 store/旁路会使旧种子继续影响 `nextAt`，与「彻底删除」冲突。选硬删。

### D2：predictor 去掉间隔旁路参数

- `predictAllUpcoming` / rows / widget sync 删除 `recallIntervalsByRoot`（或恒传空并删读取分支）。无种子后仅真历史 + 亲和规则。

### D3：onboarding 面板

- 若面板仅服务种子回忆：删除文件与一切入口引用。
- 若仍有死代码无路由：一并删。
- last-time glass picker 若仅 onboarding 用则随删；喂养加事件时间 sheet 不动。

### D4：prefs 迁移

- 启动或 wipe 时 `SharedPreferences.remove('prediction_recall_seeds_v1')`；无迁移读取。

### D5：规格

- 新 capability `retire-interval-recall-seed-stack` 写 MUST NOT。
- 旧 capability 用 REMOVED + Reason/Migration 指向 retire / 亲和进度。
- 预约「补充下次」要求保留，但去掉「非预约仍走间隔补充」表述。

## Risks / Trade-offs

- **[Risk] 用户短期看不到倒计时** → Mitigation：进度条文案已说明再记真实记录；符合产品。
- **[Risk] 漏删引用导致 analyze 失败** → Mitigation：tasks 含全仓搜 `PredictionRecallSeed` / `补充大概多久` / `recallIntervals`。
- **[Risk] 竖列表/瀑布两套卡漏删调间隔** → Mitigation：删 `_onPickIntervalRecall` 唯一入口。

## Migration Plan

- 发版后旧种子 prefs 忽略或删除；无法回滚 UX 除非恢复代码。
- Git 回滚本 change 即可恢复。

## Open Questions

- （无阻塞）onboarding 整文件是否仍有隐藏入口：实现时搜引用，无则删文件。
