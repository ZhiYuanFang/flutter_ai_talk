## Context

喂养页 `HomeImmersiveHeader` 当前以居中 `String title`（「喂养记录」）+ 右上「趋势」「设置」两个 `IconButton` 实现；预测页已用 `BabyAvatar` + 昵称/月龄身份条。本次仅改喂养沉浸头，对齐身份展示并收敛设置入口。

约束：沿用 `settingsBabyProvider` / `formatBabyAgeText` / `BabyAvatar`；颜色经 `AppVisualTokens.onShell`（或既有 header 前景语义）；不新建 debug tag；不改 Android 原生。

## Goals / Non-Goals

**Goals:**

- 身份横条：头像 + 合成「昵称 · 月龄」左对齐、纵向居中；尾部 ellipsis。
- 仅头像 → `/settings`；删除右上设置齿轮；保留趋势 → `/trends`。
- 空态与预测页一致（「宝宝」/「不满1个月啦」）。

**Non-Goals:**

- 不改预测页身份条布局（仍可为两行）。
- 不抽共用 `BabyIdentityHeaderStrip`（可后续再抽）。
- 不改设置页本身、不改宝宝编辑路由默认落地。
- 不为头像点击增加独立登录门闸（与现网齿轮直达设置壳一致）。

## Decisions

1. **布局：`Row` 替代居中 `Stack`**  
   左：`BabyAvatar` + `Expanded(Text)`；右：单个趋势 `IconButton`。左对齐后无需再为「居中标题」预留对称 `actionsWidth=104`。  
   备选：保留 Stack 硬居中 → 窄屏与右侧按钮抢宽，否决。

2. **省略：合成一段文案**  
   `Text('${nickname} · ${ageText}', maxLines: 1, overflow: TextOverflow.ellipsis)`，分隔符对齐小组件 `formatWidgetHeaderLine`。长昵称时月龄先被省略。  
   备选：昵称 Flexible + 月龄保活 → 与「合成尾部省略」决策不符，否决。

3. **设置入口迁至头像**  
   `BabyAvatar(onTap: () => context.push('/settings'))`；移除 `onSettingsTap` / 设置图标。昵称与月龄不包手势。  
   游客：直达 `/settings`（路由已允许未登录访问设置壳），与旧齿轮一致。

4. **数据在 `home_screen` 组装或 Header 内 watch**  
   优先：`HomeImmersiveHeader` 增加身份展示 API（如 `titleWidget` 或显式 baby 字段），由已是 `ConsumerStatefulWidget` 的 `HomeScreen` watch `settingsBabyProvider` 后传入，保持 Header 可测/可复用且不强制 Consumer。  
   备选：Header 改为 `ConsumerWidget` 自 watch → 也可，但耦合更重。

5. **头像尺寸**  
   栏高维持约 44；头像 `radius` 约 16–18，保证纵向居中不溢出。

## Risks / Trade-offs

- [发现成本] 用户习惯右上齿轮 → 缓解：头像为左侧主视觉；设置壳仍可从其他入口进入；趋势仍在右上。
- [合成省略] 极长昵称时月龄不可见 → 接受（产品已选合成尾部省略）；编辑资料后昵称通常可控。
- [规格破坏] 基线要求右侧同时保留趋势与设置 → 本 change 以 MODIFIED Requirement 显式改写，归档后并入基线。

## Migration Plan

- 纯客户端 UI；无数据迁移。回滚即恢复 `title: '喂养记录'` + 双 IconButton。

## Open Questions

（无；未登录直达 `/settings`、仅头像可点、合成省略、左对齐均已在探索中确认。）
