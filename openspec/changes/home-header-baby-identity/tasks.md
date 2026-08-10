## 1. Header API 与布局

- [x] 1.1 调整 `HomeImmersiveHeader`：去掉居中 `String title` 与 `onSettingsTap`；改为左对齐身份区 + 右侧仅趋势按钮的 `Row` 布局
- [x] 1.2 身份区接入 `BabyAvatar`（radius 约 16–18）与合成文案「昵称 · 月龄」（`maxLines: 1`、`TextOverflow.ellipsis`），纵向居中

## 2. 喂养页接线

- [x] 2.1 在 `home_screen` watch `settingsBabyProvider`，组装昵称/月龄回退（「宝宝」/`formatBabyAgeText`），传入 header
- [x] 2.2 头像 `onTap` → `context.push('/settings')`；确认昵称/月龄无独立导航；删除原设置齿轮调用

## 3. 验收

- [x] 3.1 手工验收：身份展示、超长省略、头像进设置、右上无齿轮且趋势仍可用、游客头像直达设置壳
