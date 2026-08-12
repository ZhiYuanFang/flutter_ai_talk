## 1. 横屏布局与字幕壳

- [x] 1.1 为预测横屏 `_WaterfallCards`（或等价）增加非零 top padding，与身份栏上内边距视觉对齐
- [x] 1.2 在预测横屏 Stack 增加左下监听图标 + 横向可换行文案（含「你好，胖宝」）；锚定**整屏**左下（非仅事件网格左下）
- [x] 1.3 实现底部偏上字幕 toast 区域（相对整屏），可展示「我在」/ASR/thinking/answer
- [x] 1.4 量身定做弹窗：内容可滚 + 底栏固定按钮；横屏提高 maxHeight、减小留白，避免矮屏溢出
- [x] 1.5 冷态骨架（全部 `useDemoSkeleton`）：事件列表上方居中「虚拟事件举例」+ 小字「请右滑补充喂养记录」；与滑动引导大卡并存；横屏同步
- [x] 1.6 修复量身定做「跳过此事件」点击无反应（底栏移出 PageView；overlay 按可用高度约束）

## 2. `/voice/chat/ws` 客户端（双端 PCM）

- [x] 2.1 新增 `VoiceChatWsClient`（或等价）：无 JWT、`start`+PCM/`commit`/`end`（**不做 text 上行**），解析 `asr_*`、`thinking_delta`、`answer`、`audio_chunk`/`audio_end`、`interrupt_commit`、`error`/`exit`
- [x] 2.2 提供 Riverpod provider；仅由预测横屏生命周期显式 connect/disconnect（provider create 不得自动建连）
- [x] 2.3 PCM 参数与现网 ASR/硬件配置对齐；Android/iOS 共用 PCM 上送路径；实现 TTS 分片播放；未知 type 忽略不断连
- [x] 2.4 在 `app/README.md`（及必要时 project 相关说明）文档化 `/voice/chat/ws` 为与 ASR 同类的无鉴权例外

## 3. 本地唤醒与「我在」

- [x] 3.1 集成 Sherpa-ONNX（或已批准替代）中文 KWS，关键词「你好，胖宝」；**Android 与 iOS 预测横屏前台均须真唤醒**（不做后台常听）；点按仅可作联调 fallback，不得作为 iOS 正式交付
- [x] 3.1a 麦克风：未授权时先 `showGlassConfirmDialog`（或同族）用途说明，用户确认后再系统申请；取消/拒绝则不启 KWS 并更新左下角文案；已授权跳过
- [x] 3.1b KWS 模型首次下载：流式进度经 `onStatus` 显示在左下角（有长度显示 %，否则已下 MB；节流刷新）
- [x] 3.2 进入预测横屏启动监听，离横屏/后台/dispose 停止；命中后播本地「我在」并写字幕
- [x] 3.3 唤醒后进入听写上送：双端 PCM → chat WS；展示服务端 thinking/answer；播放 TTS
- [x] 3.4 引入 native so/AAR（随 3.1）时：更新 `proguard-rules.pro` 并执行 `flutter build apk --release` 通过

## 4. 喂养球废弃与联调

- [x] 4.1 标注/弱化喂养页语音球入口（完整删除可另 change）；确认横屏为主路径
- [ ] 4.2 手工：横屏贴顶已改善；双端唤醒→「我在」→说话→（现网）ASR+TTS；（Go 合入后）思考字幕可见；首次麦克风走用途框再系统权限

## 5. 跨仓后续（本仓 tasks 仅跟踪提醒，代码在兄弟仓）

- [x] 5.1 在 `go_ai_talk` 开 change：`/voice/chat/ws` 接 IntentStream，全局下发 `thinking_delta`/`answer`，保留既有 PCM+TTS；**本期不加 text 上行**；无 features 门控
- [x] 5.2 在 `Arduino/ai-voice`：`cloud_client.cpp` 对 `thinking_delta`/`answer` 静默 return（不 Serial 刷屏）
