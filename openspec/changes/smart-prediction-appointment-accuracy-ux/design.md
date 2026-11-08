## Context

智能预测竖列表准确率图、瀑布预约卡、一次性确认添加、appointment/next 备注、深色壳 `primary`/`onPrimary` 不同步等问题叠在一起。产品要求 **不拆单**。Go `appointment-next-remark` **已落地**；本仓跟读跟写，禁止假备注占位。

## Goals / Non-Goals

**Goals:**

- 准确率小结整区单击回柱图；图区显式长按切 list↔瀑布。
- 竖列表过滤全部预约根；补充下次/改约仅瀑布（+既有横屏 compact）。
- 预约卡文案「预约」、logo 左侧不放大；上次 = 最新 history 时间 · remark。
- 跟 Go 读写下次 `remark`；改约默认上次预约备注；卡上展示下次备注。
- 一次性预测卡 `add` → 统一记录 sheet（废止该路径确认框即时 now）。
- 主题：覆盖 primary 时同步 onPrimary；sheet 主钮用 `AppColor.onPrimary`。

**Non-Goals:**

- 无 Go 时用本地假字段冒充预约备注。
- 改准确率计分、Live Activity、间隔推演公式。

## Decisions

1. **合入顺序**  
   Go 已就绪；本仓 apply。备注实现严格跟 twin，无假字段。

2. **竖列表过滤**  
   `compact==false` 构建 ListView 前 `!catalogRootIsAppointment`；瀑布 rows 不过滤。

3. **图区手势**  
   `_PredictAccuracyChartPane`：summary 态 `onTap` → 清 `_summaryDay`；bars/summary 均 `onLongPress` → 回调布局 toggle（由父卡注入，与整卡同函数）。bars 单击空白仍吸收，不触发加事件；点柱逻辑不变。

4. **上次发生**  
   仍用现有 lastAt 数据源（合并 history 最新）；展示追加非空 `remark`。本变更不新造 latest API。

5. **下次备注（钉死 twin）**  
   GET/PUT 含 `remark`；PUT **始终传** `remark` 字符串（空串合法，不清字段）；客户端 **不 Trim**（与 Go 一致）；长度 **≤512**（按字符/rune）；`nextAt=0` 服务端强制清备注。Repository/cache 从仅 `nextAt` 扩成 `(nextAt, remark)`。Sheet 打开用 GET 回填；卡上 `预约…时刻` 后可跟 ` · {remark}`。

6. **一次性 add**  
   预测页 `time|one` 的 `add` 直点叶子改为打开统一 create sheet；不再「确认添加」后 now 提交。

7. **onPrimary**  
   `buildAppThemeFromBundle` 在 `copyWith(primary:)` 后按 primary 亮度设置 `onPrimary`；`event_record_sheet` 去掉 `Colors.white`。

## Risks / Trade-offs

- [竖列表无「补充下次」] → 接受；瀑布承担。  
- [one 取消确认框] → 误触成本转 sheet 可取消；产品已选。  
- [PUT 省略 remark] → 与同发契约冲突；实现 MUST 始终传。

## Migration Plan

1. 本仓实现手势/过滤/文案/logo/history·remark/sheet/one/主题（跟已合 Go）。  
2. 联调预约备注读写与默认回填。  
3. 回滚：手势/过滤可独立回退；备注字段兼容空串。

## Open Questions

- 无（备注源、竖列表全藏、不拆单、Go 先已确认）。
