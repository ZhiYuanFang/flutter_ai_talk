## 1. Phase 0：原子目录与契约

- [x] 1.1 扩展 `AppVisualTokens`：增加 `modalFill` / `modalBorder` / `onModal`（及与 `contentCard`/`onContentCard` 的别名或字段对齐），实现 `copyWith`/`lerp`
- [x] 1.2 在 `VisualBundle.toTokens()`（或唯一派生点）按 design D2 计算各角色；暗壳 modal= surface 系暗浮层 + 浅字；contentCard 可保留偏亮 + 深字
- [x] 1.3 新增业务入口 `AppColor`（或等价）：`pageBg`、`textPrimary`/`textSecondary`/`textMuted`、`surface`/`textOnSurface`、`contentCard`/`textOnContentCard`、`modalFill`/`textOnModal`/`modalBorder`、`sheet*`、`field*`、`primary`/`onPrimary`、`divider`、`barrier`
- [x] 1.4 将既有 `themeGlassFill`/`themeMutedForeground` 等改为按角色转发（禁止业务再靠 alpha 当主题算法）；必要时 `@Deprecated`
- [x] 1.5 更新 `openspec/project.md`「主题色约定」为原子优先 + 组件禁判 `isDarkShell` 拼色

## 2. Phase 1：统一容器与预测浮层

- [x] 2.1 抽出或改写共享 `AppModalGlassPanel`（名称可调整），绑定 `modal*` 原子
- [x] 2.2 `showGlassDialog` / `showGlassConfirmDialog` 等默认挂 modal 原子面板
- [x] 2.3 `_PredictionAuthGateCard` 改用 `modal*`（修夜空浅蓝底+白字）；召回软浮层外壳同源
- [x] 2.4 `HistoryEditGlassPanel`（及 light glass 若在范围内）去掉写死 hex，改 `sheet*`/`modal*`；保留 `eventAccent` 强调

## 3. Phase 2：高频页面迁入

- [x] 3.1 宝宝绑定页：页底/正文/取消/玻璃/输入壳改 `AppColor` / 原子字段
- [x] 3.2 UCG 广场与 Feed 主路径：壳字用 `text*`，卡用 `contentCard*`；假玻璃 helper 转发原子
- [x] 3.3 设置页与宝宝黏土编辑：页底/主次文字/卡片走原子
- [x] 3.4 智能预测页其余 chrome（时间线/ tip / 非事件强调面）迁入原子；事件色例外保留注释

## 4. Phase 3：清扫与验收

- [x] 4.1 在 `app/lib/ui/**`、`app/lib/ucg/**` 清扫为拼色而用的 `isDarkShell` 分支与常规死 hex / `Colors.black54`（合法例外加注释）
- [x] 4.2 `dart analyze` 触达文件无 error
- [ ] 4.3 手工矩阵：经典 / 自定义浅色 / 夜空 × 页面底·正文 · 玻璃确认 Dialog · Feed 卡 · 绑定 · 预测登录/绑定引导
- [x] 4.4 `openspec validate theme-semantic-atoms --strict` 通过
