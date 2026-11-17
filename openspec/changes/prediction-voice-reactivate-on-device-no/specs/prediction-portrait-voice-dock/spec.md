## ADDED Requirements

### Requirement: Portrait shell voice MUST share deviceNo re-activate behavior

When portrait prediction voice surface want is true on the home shell, late arrival of a non-empty `deviceNo` MUST trigger the same re-activate behavior required by `prediction-landscape-voice` for the shared `LandscapeVoiceController`. The portrait voice ball MUST NOT remain stuck on the bind-baby caption after `deviceNo` is available while portrait surface want remains true. 主壳竖屏语音 surface want 为真时，非空 `deviceNo` 晚到 MUST 触发与 `prediction-landscape-voice` 相同的共享 controller 补激活；在 dn 已可用且竖屏 surface want 仍为真时，竖屏球 MUST NOT 永久停在绑定宝宝文案。

#### Scenario: 竖屏冷启 dn 晚到

- **WHEN** 主壳竖屏语音表面首帧 activate 时 `deviceNo` 为空，随后变为非空，且竖屏 surface want 仍为真
- **THEN** 客户端 MUST 补激活共享预测语音会话
- **AND** 竖屏球 MUST NOT 继续仅显示「绑定宝宝后可语音…」作为终态
