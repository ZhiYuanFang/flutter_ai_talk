## ADDED Requirements

### Requirement: Companion composer chrome SHALL support mode switch without voice orb

The smart companion page composer MUST support text mode and (on non-Web) hold-to-talk mode via a left-side switch control, using cute glass styling consistent with the companion page. The composer MUST NOT use the feeding-home large voice orb as the primary input. 陪伴输入区 **必须** 支持文字与（非 Web）按住说话切换及真玻璃风格，**不得** 以喂养大语音球为主输入。

#### Scenario: 输入条左侧可切换

- **WHEN** 用户在非 Web 陪伴页查看输入区
- **THEN** 左侧 MUST 存在模式切换入口
- **AND** 语音模式下主控 MUST 为按住条而非大语音球

### Requirement: Companion successful answer chrome excludes thumbs and post-answer thinking

Successful companion answers MUST show the soft「非医疗建议」notice when applicable, MUST NOT show thumbs feedback, and MUST NOT show thinking once answer text is present. 成功回答 **必须** 保持非医疗弱提示（若适用），**不得** 展示赞踩，**不得** 在有 answer 时展示 thinking。

#### Scenario: 答后铬层

- **WHEN** 助手 answer 非空且非 error
- **THEN** UI MUST NOT 含赞踩
- **AND** UI MUST NOT 含 thinking 块
