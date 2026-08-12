## ADDED Requirements

### Requirement: Prediction landscape SHALL force a dark shell while preserving seed tint

当智能预测页处于横屏时，该页展示子树 MUST 使用暗壳视觉（`AppVisualTokens.isDarkShell == true` 或其经 `AppColor` 等价表现），且暗壳 MUST 由当前生效主题的种子色 / 主色 tint 派生（保留品牌色相），MUST NOT 因用户选用浅色 preset 而在横屏呈现高亮度浅壳。竖屏或非预测页横屏 MUST NOT 被本要求强制改色。

#### Scenario: Light preset landscape becomes dark with tint

- **WHEN** 用户生效主题为浅色 preset 或自定义浅色，且进入智能预测页横屏
- **THEN** 预测页壳与页内经主题取色的 chrome MUST 呈现暗壳，且主色 tint MUST 仍可辨认为当前种子色相（不得整页变成无关的固定夜空灰黑）

#### Scenario: Portrait restores original theme immediately

- **WHEN** 用户从预测页横屏回到竖屏（或离开预测页横屏条件）
- **THEN** 界面 MUST 立即恢复进入横屏前的全局生效主题外观，且 MUST NOT 将横屏暗壳写回用户主题 baseline 持久化

#### Scenario: Already-dark theme stays non-glaring

- **WHEN** 用户生效主题已是暗壳（如夜空），且进入预测页横屏
- **THEN** 预测页 MUST 保持暗壳、不刺眼；MUST NOT 被强制切换为浅壳

### Requirement: Landscape TV-safe theme SHALL cover identity bar, voice chip, and subtitle toast together

预测页横屏暗壳覆盖范围 MUST 一体包含：页壳/事件卡等主内容 chrome、身份栏、横屏语音 chip、以及语音弹幕 toast（字幕条）。上述控件 MUST 经 `AppColor` / `AppVisualTokens` 取色并落在同一暗壳 `Theme` 子树（或文档化等价），MUST NOT 出现「内容已暗、弹幕/chip/身份栏仍浅亮」的割裂。

#### Scenario: Overlay chrome matches dark shell

- **WHEN** 预测页横屏且身份栏、语音 chip、弹幕 toast 同时可见
- **THEN** 三者与页壳 MUST 同属暗壳对比关系（字色可读、面板非高亮度浅玻璃），视觉一体

#### Scenario: Business UI still uses AppColor

- **WHEN** 实现或调整预测横屏护眼取色
- **THEN** 业务 UI MUST 继续经 `AppColor.*`（或 tokens 成对字段）取色，MUST NOT 为护眼在业务组件内硬编码马卡龙 `Color(0x…)` 或私自按 `isDarkShell` 拼白叠
