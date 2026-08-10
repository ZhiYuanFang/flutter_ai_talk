## ADDED Requirements

### Requirement: 身份展示 MUST 经宝宝展示原子解析空态

For in-app baby identity display (nickname, age-in-months text, and avatar `babyId`/`sex` inputs derived from an optional `BabyProfile`), the client MUST resolve empty or missing profile fields through dedicated pure display helpers (e.g. `displayBabyNickname`, `displayBabyAgeText`, `displayBabyId`, `displayBabySex`, and optionally `displayBabyIdentityLine`), and MUST NOT re-implement the identity empty-state literals inline at each call site. Empty or whitespace-only nickname MUST resolve to「宝宝」. When profile is null, age text MUST resolve to the same fallback as unusable birth date under `formatBabyAgeText`（「不满1个月啦」）. Null profile MUST yield empty `babyId` and `BabySex.unknown` for avatar inputs. Application identity lines MAY compose「{nickname} · {ageText}」without the home-widget six-character nickname truncation.

应用内宝宝身份展示（昵称、月龄文案、以及由可选 `BabyProfile` 派生的头像 `babyId`/`sex` 入参）**必须** 经专用纯函数展示原子解析空态，**不得** 在各调用点内联复制身份空态字面量。空或仅空白昵称 **必须** 解析为「宝宝」。`profile == null` 时月龄 **必须** 与 `formatBabyAgeText` 在生日不可用时的回退一致（「不满1个月啦」）；头像入参 **必须** 为为空 `babyId` 与 `BabySex.unknown`。应用内合成行 MAY 使用「{昵称} · {月龄}」且 **不得** 强制套用小组件六字截断。

#### Scenario: 无资料时的统一回退

- **WHEN** 调用方传入 `null` 宝宝资料并请求昵称、月龄与头像入参
- **THEN** 昵称 MUST 为「宝宝」
- **AND** 月龄文案 MUST 为「不满1个月啦」
- **AND** `babyId` MUST 为空串且 `sex` MUST 为 `unknown`

#### Scenario: 空白昵称回退

- **WHEN** 宝宝资料存在但 `nickname` 为空或仅空白
- **THEN** 展示昵称 MUST 为「宝宝」

#### Scenario: 有可用生日时月龄委托既有格式化

- **WHEN** 宝宝资料非 null 且生日可用于月龄计算
- **THEN** 月龄文案 MUST 与对应该生日调用 `formatBabyAgeText` 的结果一致

### Requirement: 喂养与预测身份展示 MUST 使用展示原子

The feeding immersive header identity wiring and the smart prediction page baby identity header MUST obtain nickname, age text, and avatar id/sex via the baby display atoms (or a single composed identity line atom where applicable). The feeding empty-history copy that interpolates the baby name MUST use `displayBabyNickname` (or equivalent atom) rather than a raw `?? '宝宝'` that misses whitespace-only nicknames.

喂养沉浸头身份接线与智能预测页宝宝身份顶栏 **必须** 经宝宝展示原子取得昵称、月龄与头像 id/sex（适用处可用合成身份行原子）。喂养空历史中插值宝宝名的文案 **必须** 使用 `displayBabyNickname`（或等价原子），**不得** 仅用会漏掉空白昵称的裸 `?? '宝宝'`。

#### Scenario: 喂养顶栏经原子组装

- **WHEN** 喂养页渲染沉浸头身份条
- **THEN** 昵称与月龄（或合成行）及头像入参 MUST 来自展示原子解析结果

#### Scenario: 预测顶栏经原子组装

- **WHEN** 智能预测页渲染宝宝身份顶栏
- **THEN** 昵称、月龄文案与头像入参 MUST 来自展示原子解析结果

#### Scenario: 空历史昵称经原子

- **WHEN** 喂养页在无历史时展示「还没有为 {name} 记录」类文案且资料昵称为空白
- **THEN** `{name}` MUST 为「宝宝」

### Requirement: 小组件截断 API 与设置占位 MUST NOT 被本能力强行合并

Home-widget nickname truncation helpers (`truncateWidgetNickname` / `formatWidgetHeaderLine`) MUST remain valid for widget payloads. Settings form/readonly empty nickname copy such as「待设置」MUST NOT be required to use the identity display nickname atom.

小组件昵称截断辅助 **必须** 仍可用于小组件载荷。设置表单/只读空昵称文案（如「待设置」）**不得** 被要求改用身份展示昵称原子。

#### Scenario: 小组件仍可用截断行

- **WHEN** 客户端同步桌面小组件头部行
- **THEN** 系统 MAY 继续使用 `formatWidgetHeaderLine`（含最多六字截断）

#### Scenario: 设置待设置不受强制

- **WHEN** 已登录用户在设置中心查看宝宝只读卡且昵称为空
- **THEN** UI MAY 继续展示「待设置」而不强制改为「宝宝」
