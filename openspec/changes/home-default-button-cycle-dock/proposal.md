## Why

主页当前默认语音输入，且需在贴边 dock 上「点击展开 → 再选模式」，路径偏长；对「点事件记一笔」这类高频操作不友好。应将移动端默认切到事件按钮模式，去掉键盘文字模式，并把模式切换改为一键轮转，降低操作成本。

## What Changes

- 移动端（Android/iOS）默认输入模式改为 **按钮（事件点击添加）**；冷启动无有效持久化或持久化为已废弃的 `text` 时使用该默认。
- **BREAKING（移动端）**：移除主页键盘文字输入模式；Web 端输入策略（`WEB_HOME_INPUT` 文字/语音）**不变**。
- 输入模式持久化采用 **方案 A**：仍恢复 `voice` / `buttons`；`text` 视为无效并回退默认 `buttons`。
- `HomeInputModeDock`：去掉展开式多选菜单；**松开时**轮转至下一可用模式（`buttons` ↔ `voice`）；轮转时播放 pop 缩放动画（参考事件 logo fly 的 pop 段）；动画期间保持 **完整圆形**，结束后回到 **贴边半圆**。
- 静止态 dock 仍为贴边半圆；**按下/触碰**时内移展示完整圆。
- 语音/STT 不可用时的 Toast 与引导文案改为提示用户 **切换到事件按钮模式**，不再引导「改用文字输入」。

## Capabilities

### New Capabilities

（无新增能力目录；行为变更通过既有能力 delta 表达。）

### Modified Capabilities

- `home-button-input-mode`：按钮模式为移动端默认主路径；与文字模式不再并列。
- `home-input-mode-dock`：展开菜单改为 tap 轮转；半圆/全圆交互与 pop 动画；移动端可用模式为 voice + buttons。
- `home-input-mode-history-scroll-adjust`：输入模式集合更新（移动端无 text）。
- `speech-engine-without-vosk`：移动端语音不可用时的 fallback 引导改为 buttons（Web 文字路径保留）。
- `home-shell-visual-style`：dock 与底部 panel 视觉统一要求中，模式枚举描述对齐 voice + buttons（移动端）。

## Impact

- `app/lib/ui/home_screen.dart`：默认 channel、恢复逻辑、移除移动端 text 分支、Toast 文案。
- `app/lib/ui/home_input_mode_dock.dart`：轮转交互、半圆/全圆几何、pop 动画、删除展开菜单。
- `app/lib/data/home_input_dock_geometry.dart`：全圆内移圆心辅助计算（若需）。
- `app/lib/ui/home_input_channel.dart`、`app/lib/config/home_input_channel_store.dart`：注释与可用 channel 语义。
- `app/lib/asr/home_speech_recognizer.dart`：失败文案（移动端）。
- `openspec/specs/` 对应能力基线经本变更 delta 合并后更新。
