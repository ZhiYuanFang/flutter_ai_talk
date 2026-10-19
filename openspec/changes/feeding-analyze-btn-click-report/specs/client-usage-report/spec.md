## ADDED Requirements

### Requirement: Feeding analyze button click MUST report on tap

When a logged-in user taps the feeding-analysis workspace button labeled「AI智能分析」, the client MUST immediately report `feeding_analyze_btn_click` with description「点击AI智能分析」. The client MUST emit this report on every such tap, including a tap while analysis is already running that the existing flow rejects without starting a second generation. The report MUST be fire-and-forget: the client MUST NOT wait for `refreshDailyManual` (or equivalent) to succeed, MUST NOT block analysis, and MUST NOT show a toast if the report fails. The client MUST NOT use `growth_predict_btn_click` or `growth_predict_restart_click` for this button. The locked body copy「喂养记录已达标，点击开通智能分析」MUST NOT emit this event.

已登录用户点击喂养记录分析「AI智能分析」时，客户端 MUST 立即上报 `feeding_analyze_btn_click`，description 为「点击AI智能分析」。分析进行中再点、且现有流程不发第二次生成时，该次点击也 MUST 上报。上报 MUST 不等分析成功、不得挡住分析、失败不得 toast。该按钮 MUST NOT 使用 `growth_predict_btn_click` 或 `growth_predict_restart_click`。正文「喂养记录已达标，点击开通智能分析」MUST NOT 上报本事件。

#### Scenario: Analyze button click

- **WHEN** 已登录用户在喂养记录分析点击「AI智能分析」且该次点击会发起分析
- **THEN** 客户端 MUST 上报 `featureId=feeding_analyze_btn_click`，description 为「点击AI智能分析」
- **AND** MUST NOT 等待分析接口成功后才上报

#### Scenario: Tap while analysis is running

- **WHEN** 已登录用户在分析进行中再次点击「AI智能分析」，且该次点击不发起第二次生成
- **THEN** 客户端 MUST 仍上报 `feeding_analyze_btn_click`

#### Scenario: Locked copy is not this button

- **WHEN** 用户点击正文「喂养记录已达标，点击开通智能分析」
- **THEN** 客户端 MUST NOT 上报 `feeding_analyze_btn_click`
