## 1. Feature flags

- [x] 1.1 新增暂停闸门常量（如 `kUcgHomePagerEnabled` / `kHistorySquareSyncEnabled` / `kVipPurchaseEnabled`，默认 false），位置对齐 `kUcgTreasureEnabled` 风格并在 design 约定处注释「下版可翻回」
- [x] 1.2 确认不删 `app/lib/ucg/**` 与 VIP 支付实现主体，仅闸门切断入口与副作用

## 2. 主壳关闭 UCG

- [x] 2.1 `HomePagerPage` / `UcgHomeShell`：暂停期 `itemCount=2`，禁止挂载 `UcgShell`；`requestPage(ucg)` no-op 或落到 prediction
- [x] 2.2 Android 返回路径去掉对 UCG 页的依赖（喂养 ↔ 预测）
- [x] 2.3 预测页 Auth 滑动引导大卡改文案：去掉「左滑进广场」等广场指引，保留大卡

## 3. 同步广场掐死

- [x] 3.1 `home_history_edit_sheet`：闸门关闭时不展示「同步广场」开关（含有媒体）
- [x] 3.2 保存路径强制 sync=OFF；走本地媒体缓存；MUST NOT create/update/delete UCG post（含曾有 postId 不因强制 OFF 删帖）

## 4. 预测页 chrome

- [x] 4.1 删除底部 tip 跑马灯挂载与 `_BottomTipMarquee`（不改小组件 tip 推送）
- [x] 4.2 `_CareAlertPanel`：仅 ready 且 items 非空时展示；loading / 空 / 失败 / 开通会员文案全部 shrink
- [x] 4.3 冷态不挂载 `_CareAlertDemoHealthyPanel`；Auth 大卡路径不变（仅文案）
- [x] 4.4 留意详情保持无开通 VIP CTA（`showVipCta=false` 或闸门）

## 5. VIP 购买不可达

- [x] 5.1 `/vip/purchase` 路由在闸门下 redirect 离开（如 `/home`），不展示可支付 UI
- [x] 5.2 扫除预测页等残留 `push('/vip/purchase')` / 开通文案入口

## 6. 验收

- [x] 6.1 手工：主壳仅两页；加图编辑无同步开关且保存不发帖；无底 tip；无空/失败/冷态留意卡；有条目仍可进详情；购买深链不可达；大卡无广场文案
- [x] 6.2 本变更不改 `app/android/**` 原生依赖则无需 release APK；若误动原生再按 project.md 补构建
