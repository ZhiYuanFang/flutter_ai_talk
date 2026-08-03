## 1. UI 与手势

- [x] 1.1 删除展开态「关闭」「对话」按钮及 dismiss 接线
- [x] 1.2 正文区：未过 slop 的 tap 在 `done`+可注入时 `requestPage(companion)`；streaming 忽略
- [x] 1.3 顶标 tap 仍折叠；拖动过半贴边不变；无半圆点击专用逻辑

## 2. 验收与收尾

- [ ] 2.1 手工：无底栏按钮；done 点文案进陪伴；streaming 点无效；顶标折叠/贴边仍可用
- [x] 2.2 未改 `app/android/**` 则无需 release APK
