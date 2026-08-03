## Context

- 智能陪伴页（`PangbaoAiScreen` + `smart-companion-home-layer`）已嵌入主页 PageView；输入区为玻璃文字框 + 发送。
- 回答行仍有 clinic 赞踩；小贴士 `HomeTipPanel` 亦有 tip 赞踩。
- Thinking：流式后折叠可点开（`pangbao-clinic-thinking-fold`）；产品改为「有 answer 则不画」。
- 喂养语音球 + `home-voice-slide-cancel`（圆内外判定）与 ASR（`HomeSpeechRecognizer`）已存在；产品明确**不搬语音球**，陪伴用仿微信按住条 + 上滑取消。

## Goals / Non-Goals

**Goals:**

- 去掉陪伴回答与小贴士赞踩 UI 及客户端提交。
- 助手非空 `answer` 时不渲染 thinking（含历史）。
- 陪伴输入：文字 / 按住说话切换 + 独立记忆；Web 仅文字。
- 按住：上方浮动实时转写；松手发送 Clinic question 后隐藏转写；上滑取消不发送并隐藏转写。
- 手势语义对齐喂养「松手发送 / 移出取消区取消」，几何改为按住条的**上滑阈值**。

**Non-Goals:**

- 不迁移喂养语音球 UI / 响度柱为主控。
- 不改 Clinic / tip SSE 协议；不强制删后端 feedback API。
- 不改喂养页输入 dock 与 `HomeInputChannelStore`。
- 不新建 `**/test/**`。

## Decisions

### 1. 赞踩删除范围

- **决策**：删除 `_buildClinicFeedbackRow` 展示与 `POST /device/api/clinic/feedback` 调用；删除 tip 面板反馈按钮与 `submitFeedback` 入口调用。可保留 model 字段以免大重构。
- **理由**：产品明确两边都去掉。

### 2. Thinking 可见性

- **决策**：渲染条件：`thinking` 非空 **且** `answer` 为空（error 态无成功 answer 时 MAY 仍显示 error 前的 thinking，与现网 error 场景一致）。有非空 answer 时整块不建 `_ThinkingBlock`。
- **理由**：「有 answer 就不画（含历史）」字面执行。
- **备选**：仅 answer_done 后藏——拒绝，首字 answer 即藏更干净。

### 3. 输入模式存储

- **决策**：新建 `CompanionInputModeStore`（`text` | `voice`），与喂养 `HomeInputChannelStore` 分离。Web：`kIsWeb` 强制 text，不渲染切换与按住条。
- **理由**：渠道语义不同，避免串扰。

### 4. 按住条 UI（非语音球）

- **决策**：语音模式下输入条中央为「按住 说话」热区；左侧图标切回键盘；无大圆球、无强制响度柱（电平 MAY 省略以减复杂）。
- **理由**：产品指定仿微信输入条。

### 5. 浮动转写

- **决策**：按住且（有 partial 或聆听中）在输入条**上方**叠一层浮动条（可复用/仿 `HomeVoiceMessageStrip` 样式）；`sendQuestion` 成功入列后或取消后立即清除并隐藏。
- **理由**：列表已有用户句，字幕不必常留（区别喂养 caption 常留策略）。

### 6. 上滑取消阈值

- **决策**：以按住起点为锚，指针上移超过固定阈值（建议与喂养「出界」同等量级，如 ~64–80 logical px，实现期对齐现网常量若有）进入取消态；松手时若在取消态 → `cancelSession`、不发送；移回阈值内恢复发送态。文案：「松开发送」/「松开取消」。
- **理由**：对齐喂养 slide-cancel 语义，适配条形热区（非圆外）。
- **备选**：整条区域外松手取消——亦可作补充，但产品写的是「上滑」。

### 7. ASR 与同意

- **决策**：复用喂养同源 recognizer 工厂与陪伴/AI 同意门闩；未同意先弹陪伴告知；未绑宝/未登录禁用按住或引导。识别结果走既有 `_send` / `ClinicWsClient.sendQuestion`。
- **理由**：传输与鉴权已统一，只换交互壳。

### 8. 与 smart-companion-home-layer

- **决策**：本 change 独立叠加；实现假设陪伴页已嵌入主页。若 home-layer 未合入，本 change apply 仍改 `PangbaoAiScreen` / tip 面板。

## Risks / Trade-offs

- **[Risk] 上滑与 PageView 横滑手势冲突** → 按住开始后锁定纵向主导；或按住期间暂时 `NeverScrollableScrollPhysics` 外层（仅陪伴页持有时）。
- **[Risk] 与喂养同时占用麦克风** → 进入陪伴语音按住前确保喂养未在 listening；单飞 ASR。
- **[Risk] thinking-fold 基线场景失效** → spec MODIFIED/REMOVED 明确答后不渲染，折叠条款仅适用于「尚无 answer 的流式 thinking」。
- **[Risk] Web 误开语音** → `kIsWeb` 编译期/运行期双门闩。

## Migration Plan

1. 去赞踩 + thinking 可见性（低风险 UI）。
2. 模式 store + 文字/语音条切换（Web 禁语音）。
3. 接入 ASR + 浮动转写 + 上滑取消 + 发送。
4. 手工验收矩阵后合入。

回滚：恢复赞踩与折叠 thinking；移除陪伴语音模式即可。

## Open Questions

- 无（探索已冻结上滑取消）。实现期阈值像素可与喂养常量对齐后写入代码注释。
