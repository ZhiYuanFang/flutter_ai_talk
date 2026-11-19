## ADDED Requirements

### Requirement: Landscape idle MUST restore on-device wake listening after a turn

After a landscape prediction voice turn returns to wake-waiting (chip-started or keyword-started), the client MUST restore on-device「胖宝」KWS listening while the landscape surface remains active. Tap-to-listen on the landscape chip MUST remain available whether or not KWS restore succeeded. If restore fails, the client MUST surface a short readable status and MUST log via `AppDebugLog` (`[LandscapeVoice]` / `[LandscapeKws]`). 横屏话轮回到待唤醒后 MUST 恢复「胖宝」KWS；点 chip MUST 仍可用；恢复失败 MUST 有可读状态与日志。

#### Scenario: Wake phrase works after chip turn

- **WHEN** 用户在横屏点 chip 完成一轮对话并回到待唤醒
- **AND** 横屏表面仍激活
- **THEN** 客户端 MUST 尝试恢复 KWS 监听
- **AND** 用户再说「胖宝」MUST 能再次进入开听（在 KWS 恢复成功的前提下）

#### Scenario: Chip still works if KWS restore fails

- **WHEN** `restoreWake` / KWS resume 失败
- **THEN** 用户点横屏监听 chip MUST 仍能开听
- **AND** status / 日志 MUST 表明唤醒恢复失败
