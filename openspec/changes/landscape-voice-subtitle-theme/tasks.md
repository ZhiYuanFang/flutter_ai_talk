## 1. 弹幕主题化

- [x] 1.1 `_LandscapeVoiceSubtitleToast`：底改为 `AppColor.panelGlassGradient` 或 `panelGlassTop`（可读透明度）；字/边用 `textOnPanelGlass*`；删除 `Colors.black` 硬编码
- [x] 1.2 圆角调至与 chip 同族（建议 16–20）；保持 maxWidth/换行/居中与 IgnorePointer

## 2. 监听 chip 成套

- [x] 2.1 chip 文案改 `textOnPanelGlass`（或等价）；表面继续/统一 panelGlass
- [x] 2.2 连接点：未连 `colorScheme.error`，已连 `primary` 或 `tertiary`（按对比择一并注释）；移除 `0xFF2EAD4B` / `0xFFE04545`

## 3. 轻动效与验收

- [x] 3.1 弹幕出现短淡入（约 150–250ms）；快速换字不造成明显闪烁
- [ ] 3.2 真机切换 ≥2 套主题：弹幕/chip 可读；无近白底配浅字
- [x] 3.3 确认未引入裸 `debugPrint`/`print`；未改 voice WS 逻辑；未新建 `**/test/**`
