## ADDED Requirements

### Requirement: 主输入区字幕预留

The system SHALL lay out the home primary input stack so a fixed-height caption slot above the voice orb or text field is always reserved within the bottom input panel, preventing transcript preview from being displaced by server reply layout growth. 系统必须在主页底部主输入面板内为**固定高度字幕槽**预留布局空间（位于语音球或文字输入之上），确保服务端回复不会因纵向叠层而挤占或裁切实时转写预览的可视区域。

#### Scenario: 固定高度不随回复增长

- **WHEN** 服务端返回较长对话回复
- **THEN** 底部输入区总高度必须保持与变更前一致（约 220px 量级），回复文案不得在字幕槽外向下扩展占用转写位置
