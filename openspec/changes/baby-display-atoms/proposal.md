## Why

喂养顶栏与预测顶栏各自手写「昵称/月龄/头像入参」空态回退，易漂移（例如空串昵称未回退）。在 `home-header-baby-identity` 落地后，宜抽出 L1 纯函数原子，统一身份展示空态，且不引入 Provider/自 watch 组件。

## What Changes

- 在 `baby_age`（或同级展示模块）新增可空 `BabyProfile?` 解析原子：昵称、月龄文案、合成身份行、头像用 `id`/`sex` 回退。
- 身份展示空态固定：昵称「宝宝」、月龄「不满1个月啦」（经既有 `formatBabyAgeText` 语义）、`id` 空串、`sex` `unknown`。
- 首批改用原子：喂养沉浸头接线、预测顶栏身份文案/头像入参；喂养空历史「还没有为 {name} 记录」改用昵称原子（修复空串不回退）。
- 保留小组件 `truncateWidgetNickname` / `formatWidgetHeaderLine`；**不**改设置页「待设置」、**不**新增 `babyDisplayProvider` / 自 watch 头像组件。

## Capabilities

### New Capabilities

- `baby-display-atoms`：宝宝身份展示用 L1 纯函数原子及空态约定；约束喂养/预测等身份展示调用方必须经原子解析。

### Modified Capabilities

（无。喂养/预测身份条用户可见文案与路由行为不变，仅实现迁至原子；空历史在空串昵称时与身份空态对齐属一致性修复，由本能力覆盖。）

## Impact

- 代码：`app/lib/data/baby_age.dart`（或拆出的展示辅助）、`home_screen.dart`、`smart_prediction_screen.dart`；可选触及 `HomeImmersiveHeader` 注释。
- 依赖：无新包；无 Android/原生；无 WebSocket/副作用 HTTP。
- 关联：承接 `home-header-baby-identity` 的实现收敛，不回改其规格意图。
