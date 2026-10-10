## 1. 能量条原子

- [x] 1.1 新增共享 `VoiceLevelBars`（accent / cancelled / level）；柱系数与平滑可复用现有常量与 `VoiceLevelSmoother`
- [x] 1.2 本 change 不迁移首页 `HomeVoiceLevelBars`

## 2. 轨迹追问 composer

- [x] 2.1 追问 TextField：自适应增高、maxHeight=120、超高可滚；语音/程序写入跟底
- [x] 2.2 输入壳与按住条：成长功能色浅玻璃
- [x] 2.3 按住时左右接 `VoiceLevelBars` + `onLevel` 平滑；松手仍不自动提交；无最大录音时长

## 3. 验收

- [x] 3.1 对照 `growth-ask-composer-ui` / `voice-level-bars-atom` / `growth-trajectory-voice-input` 增量情景走查
