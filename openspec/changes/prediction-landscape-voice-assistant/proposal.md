## Why

预测页横屏作为沉浸主场景时，事件网格第一行贴顶不美观；同时产品希望把「语音球」能力迁到横屏：前台常驻听唤醒词「你好，胖宝」，走硬件同源的 `/voice/chat/ws` 完成转写与 TTS，并在字幕区展示服务端下发的思考与最终答案。本变更先在 Flutter 落地客户端与 UI；服务端帧扩展与硬件静默忽略按跨仓顺序随后完成。

## What Changes

- 预测横屏瀑布流增加上边距，避免第一行贴物理顶边。
- 预测横屏左下角常驻语音监听入口（图标 + 底部横向文案，超长自动换行；唤醒词文案含「你好，胖宝」）。
- 进入预测横屏即连接 `/voice/chat/ws`（设备号 `start`，PCM 参数沿用现网 ASR/硬件配置）；离横屏/回竖屏停止本地唤醒监听并断开或闲置该连接。
- 本地唤醒选型落地（默认 Sherpa-ONNX 中文 KWS）：**Android 与 iOS 均须**在预测横屏且 App **前台**时支持语音唤醒「你好，胖宝」（**不做**后台/锁屏常听）。命中后本地播放「我在」，并在底部偏上字幕 toast 区展示播放/下行文案。
- **麦克风权限**：首次需要开麦（进横屏启 KWS 或等价时机）时，MUST **先弹应用内用途说明框**（对齐喂养语音球「先告知再进门控」/ UCG 位置「用途说明→系统权限」节奏），用户确认后再调系统权限申请；拒绝则不静默反复弹系统框，并在左下角文案提示。
- **Android 与 iOS 唤醒后均以 PCM 二进制上送** `/voice/chat/ws`，消耗服务端 Baidu STT；本期 **不做** 客户端 `type=text` 上行，**不要求** Go 支持 text 帧；本地 STT 统一方案延期。
- 客户端解析服务端 `asr_*`、`thinking_delta`、`answer`、`audio_chunk`/`audio_end`（thinking/answer 以兄弟仓后续扩展为准；缺失时降级为仅 ASR+TTS）。
- **BREAKING（产品路径）**：横屏语音成为主入口后，喂养页语音球进入**逐步废弃**规划（本变更可先弱化入口或标注后续下线任务，不强制一次删除全部球相关代码）。
- 跨仓顺序（本仓之外，写入 Impact，不在本 change 改代码）：① Flutter 本变更 → ② `go_ai_talk` 扩展 `/voice/chat/ws`（**全局下发** `thinking_delta`/`answer` + 既有 PCM/TTS；**本期不加 text 上行**；无 features 门控）→ ③ `Arduino/ai-voice` 对 `thinking_delta`/`answer` **静默忽略**。

## Capabilities

### New Capabilities

- `prediction-landscape-voice`：预测横屏常驻唤醒、字幕 toast、「我在」本地播、与 `/voice/chat/ws` 会话编排（双端 PCM）。
- `voice-chat-ws`：App 侧 `/voice/chat/ws` 客户端（**仅 PCM 上行**，解析 thinking/answer/TTS 帧）；传输例外对齐 ASR（无 Bearer，deviceNo 在 start）。

### Modified Capabilities

- `smart-prediction-page`：横屏瀑布流上边距；横屏壳层挂载语音监听 UI 与生命周期。
- `ws-transport-governance`：将 `/voice/chat/ws` 列为与 `/voice/asr/ws` 同类的**无鉴权业务例外**（禁止套用 ResilientWebSocketClient+JWT 首帧模板，但须文档化）。

## Impact

- Flutter：`smart_prediction_screen.dart`、新建 `voice_chat_ws_client`（及 provider）、唤醒 KWS 插件/原生桥、字幕 overlay、本地「我在」音频资源；可能新增 pub 依赖（如 `sherpa_onnx`）与 Android 权限说明。
- 依赖兄弟仓 `go_ai_talk`：`/voice/chat/ws` 尚无 thinking/answer；端到端思考字幕须等 Go 扩展。Flutter 可先联调现网 ASR+TTS。**本期 Go 不实现 text 帧。**
- 随后 `D:\work\Arduino\ai-voice`：`cloud_client.cpp` 为 `thinking_delta`/`answer` 静默 return。
- 喂养 `HomeScreen` 语音球：本变更标记废弃路径，完整拆除可另开 change。
- 无 Android R8/AAR 则不强制 release APK；若引入含 so/AAR 的唤醒 SDK，合并前须按 `openspec/project.md` 做 release 构建与 ProGuard 更新。
