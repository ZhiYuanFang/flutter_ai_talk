## ADDED Requirements

### Requirement: Portrait PTT MUST NOT play ding while uplink recording is active

While portrait go-record PTT has successfully started PCM uplink (`beginListen` / equivalent), the client MUST NOT play the local landscape wake ding asset concurrently with that recording session. The client MAY omit the ding entirely for portrait PTT, or MAY play it only before uplink starts and only after playback fully ends. 竖屏 PTT 在已开 PCM 上行后 MUST NOT 并行播放本地叮；MAY 省略叮，或仅在开麦前且播完后再开听。

#### Scenario: No concurrent ding after listen armed

- **WHEN** 竖屏长按已成功 `beginListen`
- **THEN** 客户端 MUST NOT 在录音进行中调用与横屏唤醒相同的 ding 播放
- **AND** 按住期间 MUST 能产生可上送的 PCM（真机 Debug 下应出现有效音/chunk 诊断，或等价能量）

#### Scenario: Hold commit after speech has uplink

- **WHEN** 用户在「请说话…」期间正常说话并在 keep 区松手
- **THEN** 客户端 MUST 发送业务 `commit`
- **AND** MUST NOT 在仅因「开听后并行 ding 导致空上行」时表现为整轮无 ASR
