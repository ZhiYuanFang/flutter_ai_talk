## Context

预测横屏已由 `prediction-landscape-rail` / `prediction-landscape-immersive` 落地：左身份栏 + 右瀑布流、`immersiveSticky`、SafeArea top/bottom 关闭，瀑布流 top padding 为 0 导致贴顶。喂养页持有按住说话语音球 + `/voice/asr/ws`；硬件对话走 `/voice/chat/ws`（`D:\work\Arduino\ai-voice`，未知 type 仅日志）。Go 侧 chat WS 今日仅 PCM→非流式意图→TTS，无 thinking/answer 帧。产品要求：Flutter 先做；再改 `go_ai_talk`（thinking/answer，**暂无 text**）；再改硬件静默忽略新帧。

曾讨论过 iOS 本地 STT→text、或双端本地 STT 统一 text 以减少 Baidu STT；已拍板：**本期 Android/iOS 均 PCM 上送、消耗服务端 STT**，本地 STT 方案延期；**Go 本期不支持 `type=text`**。

## Goals / Non-Goals

**Goals:**

- 横屏网格上边距美观。
- 横屏前台常驻唤醒「你好，胖宝」→ 本地「我在」→ **双端 PCM** 上送 chat WS → 字幕展示服务端思考/答案 + 播 TTS。
- **Android 与 iOS 均须**支持上述前台横屏唤醒（同一产品能力，非 Android 先做）。
- 麦克风：应用内用途说明 → 用户确认 → 再申请系统权限（对齐语音球告知节奏）。
- 新增 `/voice/chat/ws` Flutter 客户端（PCM 主路径），帧约定与后续 Go 的 thinking/answer 对齐。
- 文档化 WS 传输例外；喂养球标记逐步废弃。

**Non-Goals:**

- 本 change **不修改** `go_ai_talk` / `Arduino/ai-voice` 源码（顺序后续仓完成；tasks 5.x 仅跟踪提醒）。
- **本期不做** `type=text` 上行，**不要求** Go 实现 text 帧。
- **本期不做** Android/iOS 本地 STT 统一方案（含 Sherpa ASR）；仅唤醒可用本地 KWS。
- 不移植 ESP-SR WakeNet 到手机。
- 不一次删除喂养语音球全部代码。
- **不做后台 / 锁屏 / 被杀进程后的常听唤醒**（含 iOS Background Audio 常听）；仅预测横屏且 App 前台。
- 不为旧设备做 features 门控（Go 全局下发 thinking/answer；固件已验证可忽略）。

## Decisions

1. **跨仓顺序**  
   Flutter → Go（IntentStream + `thinking_delta`/`answer`，**无 text 帧**，无门控）→ Arduino 静默忽略这两种 type。

2. **唤醒：Sherpa-ONNX 中文 KWS（Android + iOS 同期）**  
   备选 Porcupine（商业）。Espressif WakeNet 仅 MCU。**v1 = 预测横屏 ∩ App 前台**；竖屏/换页/进后台即停。双端共用同一 `LandscapeWakeWord` 实现路径，禁止「仅 Android 真 KWS、iOS 靠点按」作为正式交付。

3. **「我在」：本地预置音**  
   唤醒后立即播；文案同时进字幕 toast。

4. **对话上行：双端统一 PCM（写死）**  
   Android 与 iOS 唤醒后均上送 PCM s16le 至 `/voice/chat/ws`，由服务端 Baidu STT 转写。客户端 **MUST NOT** 以 `type=text` 完成本期对话话轮。客户端形态对齐 `VoiceAsrWsClient`（Bearer 豁免 + `start.deviceNo`）；**不**用 `ResilientWebSocketClient` JWT 首帧。PCM meta 与现网一致（16k/s16le/mono）。句尾优先依赖服务端静音 `interrupt_commit` / auto-commit；客户端 MAY 发 `commit`。

5. **下行帧约定（Go 后续，无门控）**  
   `thinking_delta*` → `answer` → 既有 `audio_chunk`/`audio_end`。思考 MUST 来自服务端；客户端不得编造。Go **本期不加** text 入站。

6. **字幕 / 悬浮 UI**  
   横屏底部偏上 toast：展示「我在」、ASR、thinking、answer。监听 chip 与字幕均锚定**整屏**坐标（包住身份栏+网格的外层 Stack），非仅瀑布流面板左下。`bottom` 计入 `MediaQuery.padding.bottom`。

7. **横屏 top inset**  
   `_WaterfallCards` 横屏 top 与身份栏对齐（约 12），不重开 SafeArea top。

8. **喂养球**  
   本变更：文档 + 可选弱化；完整拆除另 change。

9. **麦克风权限：先用途弹框，再系统申请**  
   对齐喂养语音球「先告知再进后续门控」与 UCG 位置 `ensureUcgLocationForDistance`（用途 Dialog → `requestPermission`）节奏：在尚未授予麦克风、且即将为横屏 KWS/听写开麦前，MUST 先展示应用内说明（用途含：横屏说「你好，胖宝」唤醒助手、语音对话转写；明确非后台录音）。用户确认后再调用系统权限；用户取消或系统拒绝则 MUST NOT 启动监听，并更新左下角状态文案。已授权则跳过用途框。实现上优先复用 `showGlassConfirmDialog` 视觉族。

## Risks / Trade-offs

- **[Risk] 双端 PCM 持续消耗 Baidu STT** → 接受；本地 STT 统一延期。  
- **[Risk] Go 未合前无 thinking** → 字幕可先 ASR/「我在」；合入后亮思考。  
- **[Risk] 常开麦耗电/误唤醒** → 仅横屏前台；离页/进后台停听。  
- **[Risk] Sherpa KWS 体积** → 双端同依赖；若引入 so/AAR 须 release + ProGuard。  
- **[Risk] 一进横屏就弹权限** → 用途框可取消；取消后本会话不反复硬弹系统框；左下角可引导再次尝试。  
- **[Risk] 硬件 Serial 刷屏** → Arduino 静默忽略消化。

## Migration Plan

1. 合入 Flutter（UI + PCM 客户端 + KWS）；联调现网 chat WS 验 ASR+TTS。  
2. 合入 Go（thinking/answer only）后验思考字幕。  
3. 合入 Arduino 静默忽略。  
4. 再开 change 下线喂养球；本地 STT/text 另议。

回滚：横屏不启动 KWS/chat WS。

## Open Questions

（无）双端 PCM、Go 暂无 text、双端前台横屏唤醒、麦克风先用途框再申请 已写死。
