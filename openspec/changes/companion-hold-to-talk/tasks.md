## 1. 答案铬层收敛

- [x] 1.1 移除陪伴回答赞/踩 UI 与 clinic feedback 提交调用
- [x] 1.2 移除小贴士面板赞/踩 UI 与 tip feedback 提交调用
- [x] 1.3 有非空 answer 时不渲染 thinking（含 hydrate / session_sync 历史）；仅 thinking 流式且无 answer 时保留展示

## 2. 输入模式骨架

- [x] 2.1 新增 `CompanionInputModeStore`（text/voice）并在陪伴页恢复/保存
- [x] 2.2 输入条左侧切换：文字框+发送 / 按住说话条；真玻璃风格对齐陪伴页
- [x] 2.3 Web（`kIsWeb`）强制文字模式，隐藏切换与按住条

## 3. 按住说话与浮动转写

- [x] 3.1 接入与喂养同源 ASR（同意/绑宝/登录门闩），按住开始、松手结束
- [x] 3.2 按住期间输入条上方浮动实时转写（无 partial 时聆听占位）
- [x] 3.3 非取消态松手：非空转写走 Clinic `sendQuestion`，入列后隐藏浮动条；空转写不发送并隐藏
- [x] 3.4 上滑超过阈值进入取消态（文案区分）；取消态松手不发送并隐藏；移回阈值恢复发送态
- [x] 3.5 按住期间避免与外层 PageView 横滑误触（必要时临时禁横滑）

## 4. 验收

- [ ] 4.1 手工验收：赞踩消失、答后无 thinking、模式记忆、Web 无语音、松手发送、上滑取消、浮动条显隐；语音条文案视觉居中
- [x] 4.2 未改 `app/android/**` 则无需 release APK；若触及原生 ASR/权限相关则补 `flutter build apk --release` 与 proguard

## 5. UI 微调

- [x] 5.1 语音模式 Stack：通栏底色 + 文案居中，左侧切换叠层（不挤压背景）

