## MODIFIED Requirements

### Requirement: Home tip MUST present as a centered opaque card with bottom actions

When the home tip has displayable text, the client MUST present it as a centered card over the home feed viewport with an opaque surface, and MUST NOT place「关闭」or「对话」action controls below the card. 当小贴士有可展示文本时，客户端 **必须** 在主页喂养可视区以**居中不透明卡片**展示，**不得** 在卡片下方放置「关闭」或「对话」按钮。

#### Scenario: 居中卡无底栏按钮

- **WHEN** tip 有可展示文本并处于 expanded
- **THEN** 卡片 MUST 相对主页 tip 可视区居中
- **AND** 卡片表面 MUST 不透明
- **AND** MUST NOT 展示「关闭」或「对话」

## REMOVED Requirements

### Requirement: Close control MUST dismiss tip while streaming or done

**Reason**: 产品取消显式关闭；收起改为折叠/贴边最小化，内容保留。  
**Migration**: 见 `home-tip-edge-dock` / gesture 折叠与贴边；无按钮 dismiss。
