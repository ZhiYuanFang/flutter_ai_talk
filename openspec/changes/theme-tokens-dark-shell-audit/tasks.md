## 1. 规范与 helper

- [x] 1.1 在 `openspec/project.md` 增加「主题色约定」摘要（colorScheme + AppVisualTokens、暗壳禁高 alpha 白底、例外须注释）
- [x] 1.2 新增共享 glass/muted helper（浅/暗分支），供 Feed/绑定/引导卡复用

## 2. P0 已知病灶

- [x] 2.1 `baby_bind_screen`：取消/确认按钮前景改主题色（去掉 `black54` / 死白字）
- [x] 2.2 `UcgFeedFakeGlassPanel`（及 border/text helper）：暗壳不偏白；浅壳保持可读玻璃
- [x] 2.3 UCG 广场/Feed 主列表正文与次要字统一走 `onShell` / `onRecordsCard` / 既有 glass 字色 helper

## 3. P1 邻近玻璃与黏土

- [x] 3.1 `baby_bind_screen` 其余玻璃白叠色改 helper（选中态/输入壳等）
- [x] 3.2 `baby_profile_clay_theme`（及编辑页消费处）固定浅色板改为随 shell/tokens；性别芯片可保留并注释例外
- [x] 3.3 预测页 `_PredictionAuthGateCard` 白边/白叠改 glass helper

## 4. 验收

- [ ] 4.1 手工矩阵：经典 / 自定义浅色 / 夜空 × 绑定 / UCG Feed / 预测引导
- [x] 4.2 `openspec validate theme-tokens-dark-shell-audit --strict` 通过
