## Why

喂养页沉浸头仍用静态标题「喂养记录」，与预测页已落地的宝宝身份顶栏不一致；用户更需要一眼看到当前宝宝是谁。将标题替换为头像+昵称+月龄，并把设置入口收敛到头像，减少右上重复齿轮。

## What Changes

- 喂养页 `HomeImmersiveHeader` 主标题改为横向身份条：宝宝头像 + 合成文案「昵称 · 月龄」，左对齐、纵向居中；超长时整段文案尾部 `TextOverflow.ellipsis`。
- 仅头像可点，导航至 `/settings`（与现网右上设置齿轮同路由；游客可直达设置壳，不另加登录门闸）。
- 昵称与月龄文案不可点。
- **BREAKING（UI）**：删除沉浸头右上「设置」齿轮；右侧仅保留「趋势」入口（`/trends` 不变）。
- 空态/加载：昵称回退「宝宝」，月龄回退 `formatBabyAgeText` 等价文案（无可用生日时「不满1个月啦」）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-immersive-header`：标题由静态文案改为宝宝身份横条；设置入口从右上图标迁至头像点击；右侧仅保留趋势。

## Impact

- 代码：`app/lib/ui/home_immersive_header.dart`、`app/lib/ui/home_screen.dart`；复用 `BabyAvatar`、`settingsBabyProvider`、`formatBabyAgeText`。
- 规格：改写 `home-immersive-header` 中「趋势与设置」相关 Requirement。
- 无原生/Android、无新依赖、无 WebSocket/副作用 HTTP 变更。
