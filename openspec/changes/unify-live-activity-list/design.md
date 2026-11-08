## Context

Go twin `unify-live-activity-list` 已落地：`RefreshBabyLiveActivity` 组装 ContentState `{ items, phase }`，APNs `attributes-type` 为单一 `BabyLiveActivityAttributes`，register 仅 `wxId/deviceKey/tokenKind/token`。本仓仍为双 Widget + 双 Attributes + 双轨 register/诊断，锁屏无法混排预测与进行中。

现有 UI 资产：

- Imminent 锁屏行：logo + `title` + 可选 expect 右槽（`.title−5pt`）；**不**画 nextAt 倒计时。
- Timing 锁屏行：logo + `eventName` + 可选「预计 HH:mm 结束」副行 + 右侧已计时。
- Island：Imminent 无时间右槽；Timing compact/expanded 带已计时。

产品要求：把各态**现有行样式**按 `items[]` 动态纵向拼进一条 LA；顶栏「胖宝」居中且用**主题色**；Island 只放首条。

## Goals / Non-Goals

**Goals:**

- 单一 `BabyLiveActivityAttributes` 解码 Go `items[]`（容忍缺键）。
- 锁屏：居中主题色「胖宝」+ 按 kind 复用现有行组件堆叠。
- Island：仅 `items.first`，按该条 kind 走既有 Island 分支。
- 原生/Dart register 与设置页诊断单轨化，与 Go 同发联调。

**Non-Goals:**

- 为 Imminent 新造 nextAt 倒计时 / 右侧纯 `14:30` 行（沿用现 expect 右槽语义）。
- Android Live Update；改 Go 消息体或 Refresh 触发点。
- 用用户主题切换驱动 Extension 热更新（见决策：主题色常量/App Group 快照）。

## Decisions

1. **Attributes / 类型名**  
   Swift：`BabyLiveActivityAttributes`；与 Go `defaultLiveActivityAttributesType` / `PUSH_LA_ATTR_TYPE` 对齐。固定 Attributes 字段：`activityId`、`deviceNo`（Go start 已发）。ContentState：`items: [Item]`、`phase`。  
   Item：`kind` + 既有字段子集（imminent：`eventId/nextAt/title/expect*`；timing：`historyId/eventId/eventName/startTime/expectEndAt`）。解码全部 `decodeIfPresent` 兜底。  
   *备选：保留双类型名靠推送分发 — 否决（Go 已单类型）。*

2. **锁屏结构**  
   ```
   VStack {
     Text("胖宝") // 居中、主题色
     ForEach(items) { item in
       switch kind { imminent row | timing row } // 复用现有下层样式，无第二品牌行
     }
   }
   ```  
   行间距适度分隔；空 `items` 不应常驻（由 Go end 摘屏）。点击深链统一 `pangbao://live-activity`（或保留旧 path 兼容映射到预测页）。

3. **「胖宝」主题色**  
   Extension 无法直接读 Flutter `ThemeData`。采用 **产品主题主色常量**（Widget 侧固定 brand/primary hex，经 `laAccentColor` 提亮以保证深底可读），**不得**再跟首条/各条事件 accent。  
   若后续 App Group 已有 theme seed 快照可再切换读取；本变更默认常量即可，避免强耦合主题切换管线。  
   *备选：跟首条事件色 — 否决（用户明确要主题色）。*

4. **各态行样式原样复用**  
   Imminent / Timing 行逻辑从现 `LockScreenTwoTier` 下层抽出为可复用 row view；字段语义与字号规则不变（含 Imminent expect −5pt、Timing 副行与已计时）。

5. **Island 仅首条**  
   `guard let first = items.first`；`kind==imminent` → 现 Imminent Island；`kind==timing` → 现 Timing Island；未知 kind → minimal logo/空。  
   *备选：compact 显示条数角标 — 本变更不做。*

6. **Token 管线单轨**  
   只观察 `BabyLiveActivityAttributes` 的 Push-to-Start 与 activityUpdates；register body **省略** `attributesKind`/`activityId`；成功身份键改为 `wxId|deviceKey|tokenKind|token`。Inbox 去重同步去掉 attr/activityId。设置页：「已开通」= 单轨 PTS 事件已见且 register 成功 + activity 可选状态按产品现语义收敛（至少 PTS ok；activity 在有活动后另计）。

7. **删除双 Widget 注册**  
   `PangbaoWidgetBundle` 仅注册统一 Live Activity Widget；删除或掏空旧双 struct，避免系统仍按旧类型解码失败。

## Risks / Trade-offs

- [旧客户端仍双轨 register] → 与 Go 同发；旧字段 Go 已不要求，多传可能被忽略或拒——客户端必须停发。  
- [列表过长撑爆锁屏高度] → 接受系统裁切；不在本变更做折叠。  
- [主题色常量与用户所选 Flutter 预设不一致] → 接受；需要像素级跟主题时再加 App Group 同步任务。  
- [Push-to-Start 后 ContentState 短暂空/旧] → 解码兜底；以后续 update 全量 `items` 为准。  
- [深链旧 path] → 兼容映射，避免旧通知点击失效。

## Migration Plan

1. 实现统一 Attributes/Views + 单 Widget 注册。  
2. 改 Bridge/NativeRegister/Dart register/设置页。  
3. 更新 `LIVE_ACTIVITY.md`。  
4. 与 Go 开 `PUSH_LIVE_ACTIVITY_ENABLED` 联调：pending PUT、CUD、到点三条路径。  
5. 回滚：关服务端开关；客户端旧包无法解码新类型（须同发）。

## Open Questions

- 无（顶栏主题色已定为产品主色常量；Island/样式复用已拍板）。
