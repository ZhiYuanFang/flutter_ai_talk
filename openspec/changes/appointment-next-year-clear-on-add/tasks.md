## 1. 专用 sheet 年份行 + 四列滚轮

- [x] 1.1 `_AppointmentNextSheetBody`：标题下可点年份（glass 单列选年）+ 月/日/时/分四列；日列随年月收束；去掉五列同行与 `dateAndTime`
- [x] 1.2 保持默认：未来 initial 用约定，否则 `now+7d`；范围约 2000…now+5y；确认仍 PUT 正 nextAt
- [x] 1.3 sheet 高度适配四列 + 年份行

## 2. 新增后清空再引导

- [x] 2.1 预约根且 `EventRecordIntent.add` 成功：先 `clearAppointmentNextAt`；失败 toast 且不弹 sheet
- [x] 2.2 清空成功后再 `showAppointmentNextSheetAndSave`
- [x] 2.3 `supplement` 路径保持 `maybePromptAppointmentNextAfterWrite`（仅空/过期；不清空）

## 3. 预测卡 countdown 改约（竖+横）

- [x] 3.1 竖屏 compact：countdown 块可点 → `_onSupplementAppointment`；手势不冒泡到整卡 add
- [x] 3.2 横屏：预约根有 pred 时渲染同语义 countdown 块（可与图并存），点按同样改约
- [x] 3.3 整卡非 countdown 区域仍可按既有规则加喂养；「补充下次」在无 pred 时保留

## 4. 验收

- [x] 4.1 手工：sheet 可滚到其它年份并保存
- [x] 4.2 手工：新增预约（即使原有未来 nextAt）→ 先清空再弹；清空失败不弹
- [x] 4.3 手工：补充有未来 nextAt 不弹、不清空；空/过期仍弹
- [x] 4.4 手工：竖屏与横屏点 countdown 改约，不误触发新增
