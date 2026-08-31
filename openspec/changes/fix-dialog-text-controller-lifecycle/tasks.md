## 1. 修复邀请码弹窗

- [x] 1.1 将 `_openInviteDialog` 输入区改为 StatefulWidget（或等价），controller 在 `State.dispose` 释放；`pop` 带回码或确认结果
- [x] 1.2 确认兑换 / 取消 / 遮罩关闭路径语义不变，且 await 返回后外层不再 `dispose` 已移交的 controller

## 2. 审计与规范

- [x] 2.1 `app/lib/**` grep：dialog/sheet 外创建 `TextEditingController` + await 后 dispose；命中则同模式修复
- [x] 2.2 在 `openspec/project.md` 增加「弹框 TextEditingController / FocusNode」约定（MUST / MUST NOT + 指向 `_GlassTextConfirmDialogBody`）

## 3. 验收

- [ ] 3.1 手测：输入邀请码点兑换 / 取消，无 disposed-controller 断言；有效码可兑或失败 Toast 正常
- [x] 3.2 `openspec validate fix-dialog-text-controller-lifecycle --strict`
