## ADDED Requirements

### Requirement: App pause MUST release TTS and resume MUST NOT replay it

When prediction voice reply TTS or a local prompt on the same player is still playing and the UI pauses — including screen-off `inactive`, `hidden`, or `paused` — the client MUST stop and release that playback and discard any buffered PCM so the segment cannot continue. When the app returns to `resumed`, the client MUST NOT play that utterance again and MUST stop or release the player once more so a platform player cannot resume it. If a turn was waiting for playback completion, the client MUST close it as discarded and MUST NOT emit a successful playback-complete `VoiceChatTurnEnded` because the app resumed.

预测语音回复 TTS 或同一播放器上的本地提示在界面暂停时（含熄屏 `inactive`、`hidden`、`paused`），客户端 MUST 停止并释放该段播放、丢弃缓冲。回到 `resumed` MUST NOT 再播该句，并 MUST 再停止或释放一次，避免系统播放器续播。若话轮仍在等播完，MUST 按丢弃收口，MUST NOT 因回到前台补发成功播完的 `VoiceChatTurnEnded`。

#### Scenario: 熄屏或暂停时释放

- **WHEN** 回复 TTS 或本地提示正在播放
- **AND** 界面进入 `inactive`、`hidden` 或 `paused`
- **THEN** 客户端 MUST 停止并释放当前播放器源
- **AND** MUST 丢弃未播完缓冲

#### Scenario: 亮屏不补播

- **WHEN** 上一句已因界面暂停被释放
- **AND** App 回到 `resumed`
- **THEN** 客户端 MUST NOT 播放该句
- **AND** MUST NOT 让播放器从暂停处续上
