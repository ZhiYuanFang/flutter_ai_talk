## Context

`predict-capability-wall-copy` 已将基础版说明做成 Markdown 列表（emoji + 文案）。用户希望每条能力有场景样例，但不提供图——中档方案：用 Flutter 小 Widget / `CustomPaint` 画可辨认示意。

## Goals / Non-Goals

**Goals:**

- 基础版墙：8 条能力，每条标题+说明+下方中档 demo。
- Demo 可一眼对应真实能力；假数据；不可点；高度约 72–120。
- 风格跟墙玻璃/档位色协调。

**Non-Goals:**

- 不贴图、不引 Lottie 资源包（除非已有且极轻）。
- 不复刻完整真实组件树 / 不读 history·catalog 真数据。
- 不做 Pro 档 demo。
- 不做「仅首屏 4 条折叠」（首版全量滚动即可）。

## Decisions

1. **布局**  
   文案在上、demo 在下（竖向一条）；卡内继续 `SingleChildScrollView`。

2. **数据模型**  
   `PredictBasicFeatureDemoItem { emoji, title, subtitle, kind }`；`kind` 枚举映射到具体 demo builder。废弃墙内整段 Free MD 渲染路径（常量可删或仅作注释备份）。

3. **Demo 清单（中档）**

   | kind | 示意 |
   |------|------|
   | nextEstimate | 迷你卡「母乳 · 还有 1:23:05」 |
   | pushRemind | 假通知条「即将发生 · 母乳」 |
   | homeWidget | 圆角方块两行预测 |
   | familyShare | 2–3 叠头像圆 |
   | landscapeCast | 横条屏幕框 + 内嵌小卡 |
   | voiceBall | 圆球 + 1–2 波纹 |
   | trendChart | 简易折线 CustomPaint |
   | xiaozhiSpeaker | 音箱剪影块 +「可付费开通」小标 |

4. **文件**  
   优先 `app/lib/ui/widgets/predict_basic_tier_demos.dart` 集中 demo；墙只拼列表。

5. **无障碍**  
   demo `IgnorePointer`；语义上可 `ExcludeSemantics` 或合并到条目说明，避免读屏重复噪声。

## Risks / Trade-offs

- [卡变长] → 接受滚动；若过挤再议折叠。  
- [与真 UI 漂移] → demo 只示意，注释标明 fake。  
- [与 wall-copy 并行] → apply 时以当前墙代码为底，勿回退基础版/脚样式既有决定。

## Migration Plan

- 纯客户端 UI；回滚恢复 Markdown 列表即可。

## Open Questions

- （无）explore 已选中档、demo 在文案下。
