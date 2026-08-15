## 1. TV 压暗配方

- [x] 1.1 新增 `deriveLandscapeTvDimBundle`（对浅色 shell/surface 黑叠降亮，保留 seed；按壳 luminance 定 `isDarkShell`）
- [x] 1.2 `landscapeTvSafeThemeOf` 浅壳分支改走 TV 压暗；MUST NOT 再调用 `deriveDarkBundle`；已暗仍透传

## 2. 验收

- [ ] 2.1 手工：偏粉 vs 偏蓝（或两自定义浅色）横屏壳色可辨，且明显暗于竖屏、不刺眼
- [ ] 2.2 手工：回竖屏恢复原主题；夜空横屏仍暗；baseline 未变
