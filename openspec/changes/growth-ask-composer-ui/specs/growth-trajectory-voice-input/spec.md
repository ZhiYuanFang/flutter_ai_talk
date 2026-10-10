## ADDED Requirements

### Requirement: Growth ask voice fill UI MUST follow growth-ask-composer-ui chrome

When growth-trajectory asking text input is shown with hold-to-talk fill (per existing ASR reuse rules), the visible composer chrome (auto-growing field, feature-accent light glass, and listening side VoiceLevelBars) MUST conform to `growth-ask-composer-ui`. ASR transport, singleton reuse, and no-auto-submit-on-release rules SHALL remain as previously specified. 成长追问语音填框在展示时 **必须** 符合 `growth-ask-composer-ui` 的输入壳与能量条布局；ASR 共用与松手不自动提交等既有规则 **保持不变**。

#### Scenario: Free-text ask uses composer chrome

- **WHEN** free_text 追问展示按住说话
- **THEN** UI MUST 使用最大高度 120 的自适应输入与功能色浅玻璃按住条，且按住时左右为共享 VoiceLevelBars
