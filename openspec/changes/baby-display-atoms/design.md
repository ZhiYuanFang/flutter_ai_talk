## Context

喂养沉浸头与预测顶栏均 `watch(settingsBabyProvider)` 后手写空态：`trim` 昵称 →「宝宝」、`formatBabyAgeText` 或「不满1个月啦」、`BabyAvatar(id ?? '', sex ?? unknown)`。`baby_age.dart` 已有月龄格式化与小组件截断行，缺可空 profile 的身份展示入口。

约束：仅 L1 纯函数；页面继续自己 watch；颜色/日志/原生无涉。

## Goals / Non-Goals

**Goals:**

- 提供 `displayBabyNickname` / `displayBabyAgeText` / `displayBabyIdentityLine` / `displayBabyId` / `displayBabySex`（命名可微调，语义固定）。
- 首批调用方改为原子：喂养顶栏、预测顶栏、喂养空历史昵称插值。
- 与小组件截断 API 分流：应用内合成行不截 6 字（由 UI `ellipsis` 负责）。

**Non-Goals:**

- L2 `babyDisplayProvider`、L3 自 watch `BabyIdentityAvatar` / 共用 strip。
- 设置只读「待设置」、UCG/广场洗名、改小组件截断规则。
- 新建 `**/test/**` 测试文件。

## Decisions

1. **落点：扩展 `app/lib/data/baby_age.dart`**  
   月龄与展示回退同域；避免过早拆文件。若符号变多可后续改名 `baby_display.dart`，本 change 不强制。

2. **可空入口，复用既有 format**  
   - `displayBabyAgeText(baby, now)`：`baby == null` →「不满1个月啦」；否则 `formatBabyAgeText(baby.birthDate, now)`。  
   - `displayBabyNickname(baby)`：null/空白 trim →「宝宝」。  
   - `displayBabyIdentityLine`：`'$nick · $age'`，供喂养横条；预测仍可分两行各调 nickname/age。  
   - `displayBabyId` / `displayBabySex`：null → `''` / `BabySex.unknown`。

3. **`now` 由调用方传入**  
   预测继续传 `predictionClockProvider` 的 now；喂养可用 `DateTime.now()`。原子不读 Riverpod。

4. **设置「待设置」不纳入**  
   编辑语境与身份展示不同；误统一会破坏设置文案。

5. **空历史一并改用昵称原子**  
   成本极低，消除 `?? '宝宝'` 对空串失效的不一致。

## Risks / Trade-offs

- [命名扩散] 新旧 API 并存 → 缓解：注释标明身份展示用 display*；小组件继续 truncate/formatWidget*。
- [范围蔓延] 想顺手抽 Widget → 明确 Non-Goal，拒绝本 change 内做 L3。

## Migration Plan

- 纯重构 + 空串昵称一致性；无数据迁移。回滚即恢复内联三元表达式。

## Open Questions

（无；L1 范围与空历史纳入已在探索中确认倾向并写入 proposal。）
