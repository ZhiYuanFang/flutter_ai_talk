## Why

智能陪伴页已从诊疗演进为主页左侧聊天层，但输入仍偏「纯文字 + 诊疗式反馈/思考展示」：回答与小贴士仍暴露赞踩，答案出现后思考块仍占位；缺少仿微信的按住说话。产品需要更轻的陪伴对话体验——少干扰、答案优先，并在输入条内用按住说话（松手发送 / 上滑取消）补齐语音入口，且不搬迁喂养页大语音球。

## What Changes

- **移除赞踩 UI**：陪伴对话成功回答上的赞成/不赞成按钮删除；首页小贴士面板赞踩一并删除（不再调用对应 feedback 提交入口）。
- **答案优先隐藏思考**：**BREAKING** 相对 `pangbao-clinic-thinking-fold` 的「答后折叠可点开」——当助手轮次已有非空 `answer` 时 **不得** 渲染 thinking（含本地 hydrate / `session_sync` 历史）；流式仅 thinking、尚无 answer 时仍可展示 thinking。
- **陪伴输入模式**：输入条左侧切换文字 / 按住说话；独立持久化上次模式；**Web 禁止语音模式**（与喂养侧语音常关一致）。
- **仿微信按住说话（非语音球）**：语音模式下主控为按住区域；按住期间上方**浮动实时转写**；松手且未取消则将转写作为 Clinic `question` 发送并**隐藏**浮动条；**上滑取消**对齐喂养 `home-voice-slide-cancel` 语义（不发送、隐藏转写）。
- **不**将喂养页语音球 UI 迁入陪伴页；ASR 引擎/同意门闩可复用现有抽象。

## Capabilities

### New Capabilities

- `companion-hold-to-talk`：陪伴页文字/按住说话切换、模式记忆、浮动转写、松手发送与上滑取消、Web 禁语音。
- `companion-answer-chrome`：陪伴回答与小贴士去赞踩；有 answer 不渲染 thinking（含历史）。

### Modified Capabilities

- `pangbao-clinic-thinking-fold`：答后行为由「折叠展示」演进为「有 answer 则不渲染 thinking」。
- `smart-companion-ui`（若已合并基线则以本 change delta 为准；否则叠在 `smart-companion-home-layer` 之上）：输入区与答案区视觉约束对齐本变更。
- `home-tip-companion-bridge`：小贴士面板不再展示赞踩（点卡进陪伴等行为不变）。

## Impact

- **flutter_ai_talk**：`PangbaoAiScreen` 输入区与 `_buildItem` / tip `HomeTipPanel`；新建陪伴输入模式 store；复用 `HomeSpeechRecognizer`（或等价）与同意门闩；手势阈值对齐喂养 slide-cancel。
- **go_ai_talk**：无协议变更；clinic/tip feedback API 可保留但客户端不再调用。
- **基线对照**：v2.0.3 `pangbao-clinic-thinking-fold`、`home-voice-slide-cancel`；叠层 `smart-companion-home-layer`。
- **测试文件**：不新建 `**/test/**`（除非用户另行要求）。
