## ADDED Requirements

### Requirement: Prediction page build MUST NOT ensure feature catalog

While `SmartPredictionScreen` (or equivalent prediction page) is building, the client MUST NOT invoke `featureCatalogStateProvider.notifier.ensureLoaded` (or equivalent) in a way that synchronously updates that notifier’s state during build. Catalog ensure for prediction unlock chrome MUST remain on the home pager shell enter-prediction path (or post-frame / non-build side-effect), not inside the prediction page `build` method.

`SmartPredictionScreen`（或等价预测页）在 `build` 期间 **不得** 调用会同步更新 catalog notifier state 的 `ensureLoaded`。预测开通态所需的 catalog ensure **必须** 留在主壳进预测路径（或 post-frame / 非 build 副作用），**不得** 写在预测页 `build` 内。

#### Scenario: 进预测不依赖 build 内 catalog ensure

- **WHEN** 用户进入智能预测页且需要 catalog 开通态
- **THEN** catalog ensure MUST 由壳层进预测（或其它非 build）路径触发
- **AND** 预测页 `build` MUST NOT 再同步 kick `featureCatalog.ensureLoaded`

#### Scenario: 无 build 期 Riverpod 修改断言

- **WHEN** 已登录用户打开预测页渲染值得留意分支
- **THEN** 客户端 MUST NOT 因预测页 `build` 内 catalog ensure 触发「Tried to modify a provider while the widget tree was building」
