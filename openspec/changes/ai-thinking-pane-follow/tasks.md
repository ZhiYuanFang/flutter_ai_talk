## 1. 共享组件与全局约束

- [x] 1.1 新增 `AiThinkingPane`（`app/lib/ui/widgets/ai_thinking_pane.dart`）：跟底、上翻暂停、回底钮、程序滚动门闩、accent ?? primary
- [x] 1.2 在 `openspec/project.md` 增加「AI 思考展示组件（强制）」条款
- [x] 1.3 在 `AGENTS.md` 增加对应摘要并指回 `project.md`

## 2. 业务接入

- [x] 2.1 喂养记录分析：替换 `_FeedingThinkingPane` 为 `AiThinkingPane`
- [x] 2.2 成长轨迹预测：替换 `_ThinkingPane` 为 `AiThinkingPane`
- [x] 2.3 胖宝诊疗：流式与展开态正文改用 `AiThinkingPane`；折叠尾部窗口保持既有实现

## 3. 校验

- [x] 3.1 `flutter analyze`（或 IDE 诊断）覆盖新增组件与改动屏通过
- [ ] 3.2 手工：喂养 / 成长流式跟底、上翻暂停、仅按钮恢复、按钮功能色
- [ ] 3.3 手工：诊疗流式跟底与展开态回底；折叠尾部仍跟最新；答后不画 thinking
- [x] 3.4 本 change 不改 `app/android/**`；若触及原生须补 release 与 proguard
