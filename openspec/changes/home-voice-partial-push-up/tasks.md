## 1. 转写条组件

- [x] 1.1 新建 `HomeVoicePartialStrip`（多行 Text、`maxHeight` 30% 屏高、超出可滚动）
- [x] 1.2 `AnimatedSize` 包裹高度变化

## 2. 首页布局

- [x] 2.1 `Expanded` 内改为 `Column(Expanded(history), strip?)`
- [x] 2.2 `_showPartialStrip`：语音模式 && `_partial` 非空 && `_chatReply` 为空
- [x] 2.3 `_homeInputCaptionText`：有 strip 时不返回 partial；保留回复与「聆听中…」

## 3. 底栏

- [x] 3.1 底栏 220px 仅在无 strip 占用时显示顶栏字幕（聆听中/回复）
- [x] 3.2 确认语音球区不被 strip 挤压到不可用（220 固定或球区最小高度）

## 4. 验证

- [x] 4.1 按住说话：partial 变长时历史变矮、转写多行可见
- [x] 4.2 回复到达：strip 消失、底栏显示回复、可 BottomSheet
- [x] 4.3 转写条与语音球无重叠；按住/滑出取消正常
- [x] 4.4 超长 partial 可滚动阅读
