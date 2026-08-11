## 1. L1 / L2 身份展示

- [x] 1.1 加固 L1：`displayBabyNickname` 将「未绑定宝宝ID」视为无效回退「宝宝」；合成行在月龄为空时仅返回昵称
- [x] 1.2 扩展 `BabyDisplay`（或等价）：支持空月龄 / `showAge`；`resolve` 与会话覆盖路径一致产出 `identityLine`
- [x] 1.3 更新 `babyDisplayProvider`：watch session + deviceNo；未登录→「未登录」无月龄；已登录未绑定→「未绑定宝宝」无月龄；已绑定仍 L1(profile)

## 2. 顶栏 UI

- [x] 2.1 `HomeImmersiveHeader`：月龄为空时仅渲染昵称（无「 · 」段）
- [x] 2.2 预测页身份顶栏：月龄为空 / `showAge == false` 时不渲染月龄行

## 3. 预测门闸卡片路径

- [x] 3.1 冷态骨架 `onCardTap`：未登录/未绑定改为打开适用门闸（visible=true），移除直接 `push('/login'|'/settings/bind-baby')`
- [x] 3.2 确认门闸 CTA 仍分别导航 `/login` 与 `/settings/bind-baby`

## 4. 登录/绑定进页不弹与触发收窄

- [x] 4.1 login/bind `StateProvider` 默认改为 `false`
- [x] 4.2 session/deviceNo listen：登出、登录后未绑定、deviceNo 变空时不得强制 `visible=true`
- [x] 4.3 空白 `GestureDetector` 与布局切换：login/bind 不再 reopen（recall 可保留）
- [x] 4.4 骨架卡仍可打开适用门闸

## 5. Auth 冷态滑动引导大卡

- [x] 5.1 未登录/未绑定：隐藏值得留意与接下来3小时（及底 tip），插入无按钮滑动引导大卡
- [x] 5.2 大卡左右箭头：持续水平位移 + 心跳缩放；文案含左滑广场 / 右滑喂养
- [x] 5.3 保留骨架网格；已绑定空历史仍走演示留意 + 接下来3小时

## 6. 校验与冒烟

- [x] 6.1 `openspec validate identity-header-auth-states --strict`
- [ ] 6.2 手工冒烟：三态顶栏；进页不弹门闸；点骨架卡才弹；auth 冷态大卡+箭头动效无按钮；已绑定空历史仍见留意/3小时
