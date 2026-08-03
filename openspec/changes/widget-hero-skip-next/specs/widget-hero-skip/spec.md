## ADDED Requirements

### Requirement: Hero skip button SHALL use label 跳过 on small and large

On Android and iOS home widgets that display a prediction hero (small and large), the client MUST show a control labeled exactly「跳过」adjacent to the hero row, separate from the widget launch affordance. Medium widgets without a hero MUST NOT show this control. 在展示预测 hero 的 small/large 桌面小组件上，客户端 **必须** 在 hero 行旁展示文案恰为「跳过」的控件，且与打开 App 的点击分离；无 hero 的 medium **不得** 展示该控件。

#### Scenario: large 展示跳过

- **WHEN** large 小组件处于 ready 且存在 hero
- **THEN** UI MUST 显示文案为「跳过」的控件

#### Scenario: medium 无跳过

- **WHEN** medium 小组件展示 tip/recent
- **THEN** UI MUST NOT 显示「跳过」控件

### Requirement: Skip SHALL suppress event from hero only until new history

When the user activates「跳过」for the current hero `eventId`, the client MUST record a local skip for that id (S1) and MUST rebuild the widget payload so that hero excludes any still-skipped `eventId` (promoting the next non-skipped prediction when available), while `recentLast`（后续留意）MUST still be allowed to include skipped event ids. 用户对当前 hero 激活「跳过」时，客户端 **必须** 按 S1 记录本机 skip，并重建 payload，使 hero **不** 包含仍被 skip 的 `eventId`（有下一未 skip 预测则提升为 hero）；`recentLast`（后续留意）**必须** 仍可包含已 skip 的事件。

#### Scenario: 跳过后下一事件升为 hero

- **WHEN** 预测序列为 A、B、C（按 nextAt）且 hero 为 A
- **AND** 用户点击「跳过」
- **THEN** 新 payload 的 hero MUST 为 B（若 B 未 skip）
- **AND** `recentLast` MUST 仍可包含 A

#### Scenario: 跳过事件仍出现在后续留意

- **WHEN** 某 `eventId` 处于 skip 状态
- **AND** 客户端构建小组件 payload
- **THEN** hero MUST NOT 使用该 id
- **AND** `recentLast` MAY 包含该 id（按预测/lastAt 编排）

### Requirement: Skip lifetime SHALL clear on new history for that event

A skipped `eventId` MUST remain suppressed from hero until a newer history record for that event is observed (relative to the skip baseline) or the user logs out (skip store cleared). 被 skip 的 `eventId` **必须** 对 hero 保持抑制，直到观测到该事件相对 skip 基线更新的历史记录，或用户登出并清除 skip 存储。

#### Scenario: 新记录解除 skip

- **WHEN** 事件 A 已被跳过
- **AND** 本地历史出现 A 的更新记录（lastAt 新于 skip 基线）
- **AND** 随后刷新小组件
- **THEN** A MUST 重新有资格出现在 hero

#### Scenario: 登出清除 skip

- **WHEN** 用户登出
- **THEN** 本机 hero skip 存储 MUST 被清除

### Requirement: Skip interaction MUST NOT require opening the app UI

Activating「跳过」MUST invoke the home_widget interactivity / background path to update skip state and refresh the widget, and MUST NOT rely solely on launching the full foreground home UI as the only update path. 激活「跳过」**必须** 经 home_widget 交互/后台路径更新 skip 并刷新小组件，**不得** 仅依赖拉起前台首页作为唯一更新路径。

#### Scenario: 点击跳过刷新小组件

- **WHEN** 用户在桌面点击「跳过」
- **THEN** 客户端 MUST 更新 skip 状态并刷新小组件展示
- **AND** MUST NOT 将打开前台 App 作为完成跳过的唯一必要步骤

### Requirement: Older iOS without interactive widgets MUST keep launch-only behavior

On iOS versions where interactive widget buttons are unavailable, the widget MUST omit the「跳过」control and MUST retain existing tap-to-open behavior. 在不支持交互按钮的 iOS 版本上，小组件 **必须** 省略「跳过」控件，并 **必须** 保留既有点击打开行为。

#### Scenario: 旧系统无跳过按钮

- **WHEN** 系统不支持小组件交互 Button
- **THEN** small/large MUST NOT 展示「跳过」
- **AND** 整卡打开 App 行为 MUST 保持可用

### Requirement: Android release build MUST pass after native widget changes

Changes under `app/android/**` for the skip control MUST be verified with a successful `flutter build apk --release` before merge, and ProGuard rules MUST be updated if R8 reports missing classes for new receivers/components. 为跳过控件改动 `app/android/**` 时，合并前 **必须** 以成功的 `flutter build apk --release` 验证；若 R8 报 Missing class，**必须** 更新 proguard 规则。

#### Scenario: 合并前 release 构建

- **WHEN** 本变更包含 Android 原生小组件跳过相关改动
- **THEN** 合并前 MUST 完成 release APK 构建通过
