## 1. 移除拉条

- [x] 1.1 `ucg_home_shell.dart`：去掉喂养页 `UcgEnterCompanionTab` / `UcgEnterSquareTab` 挂载
- [x] 1.2 全库确认无引用后删除 `ucg_enter_companion_tab.dart`、`ucg_enter_square_tab.dart`
- [x] 1.3 确认未改 PageView physics：喂养页静止时可横滑进陪伴与 UCG（dock/tip 拖动禁滑保留）

## 2. 验收

- [ ] 2.1 手工：喂养页无左右拉条；横滑可进陪伴与 UCG；返回喂养正常
- [ ] 2.2 手工：tip「对话」仍可进陪伴；UCG 内未读 Tab 仍可用
- [x] 2.3 未改 `app/android/**` 则无需 release APK
