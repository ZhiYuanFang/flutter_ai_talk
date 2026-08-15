## MODIFIED Requirements

### Requirement: Prediction landscape SHALL force a dark shell while preserving seed tint

当智能预测页处于横屏且当前生效主题为浅壳时，该页展示子树 MUST 使用 **TV 压暗** 视觉：在当前浅色主题的壳 / 表面气质上降低亮度以减轻投屏刺眼，MUST 保留种子色相与不同浅色之间的可辨差异，MUST NOT 再经 `deriveDarkBundle`（或等价「明度夹死到同一暗区」）把不同浅色压成近乎相同的灰黑壳。压暗结果的字色 / 面板对比 MUST 经 `AppVisualTokens` / `AppColor` 保持可读。竖屏或非预测页横屏 MUST NOT 被本要求强制改色。当生效主题已是暗壳时，横屏 MUST 保持暗壳、不刺眼，MUST NOT 被强制切换为浅壳。

#### Scenario: Distinct light themes stay distinguishable when dimmed

- **WHEN** 用户分别选用两种明显不同的浅色主题（例如偏粉与偏蓝，或色盘上两种不同浅色），并进入智能预测页横屏
- **THEN** 两横屏页壳色 MUST 仍可被人眼区分（色相和/或相对深浅），MUST NOT 呈现为同一灰黑壳

#### Scenario: Light landscape is dimmed not full night-crush

- **WHEN** 用户生效主题为浅色，且进入智能预测页横屏
- **THEN** 页壳 MUST 明显暗于同主题竖屏（投屏不刺眼），且整体气质 MUST 仍可辨认为该浅色主题的压暗版，MUST NOT 整页变成与 seed 无关的固定夜空灰黑

#### Scenario: Portrait restores original theme immediately

- **WHEN** 用户从预测页横屏回到竖屏（或离开预测页横屏条件）
- **THEN** 界面 MUST 立即恢复进入横屏前的全局生效主题外观，且 MUST NOT 将横屏压暗写回用户主题 baseline 持久化

#### Scenario: Already-dark theme stays non-glaring

- **WHEN** 用户生效主题已是暗壳（如夜空），且进入预测页横屏
- **THEN** 预测页 MUST 保持暗壳、不刺眼；MUST NOT 被强制切换为浅壳

## ADDED Requirements

### Requirement: Landscape TV dim SHALL NOT use deriveDarkBundle for light shells

浅壳主题的预测横屏护眼派生 MUST NOT 调用 `deriveDarkBundle` 作为壳色配方；MUST 使用横屏专用压暗（对当前浅色 bundle 的 shell/surface 降亮并保留 seed tint）或文档化等价实现。

#### Scenario: Implementation path avoids night crush

- **WHEN** 浅壳用户进入预测横屏触发护眼 Theme 派生
- **THEN** 派生路径 MUST NOT 以 `deriveDarkBundle(lightSeed)` 作为壳色来源
