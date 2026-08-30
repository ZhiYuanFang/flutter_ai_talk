## Context

喂养/预测顶栏经 `babyDisplayProvider` 展示身份。未绑定占位曾露出「未绑定宝宝ID · 不满1个月啦」。登录/绑定门闸曾默认进页即弹，且空白 tap 会 reopen；现改为意图触发（骨架卡），进页不弹。

## Goals / Non-Goals

**Goals:**

- 未登录顶栏：「未登录」，无月龄。
- 已登录未绑定顶栏：「未绑定宝宝」，无月龄。
- 已绑定：保持现有 L1 真 profile 展示。
- 预测骨架卡点击：打开登录/绑定门闸，不直达登录/绑定路由。
- 登录/绑定门闸进页默认不弹；仅骨架卡意图触发；空白与切布局不弹。
- 喂养合成行 / 预测双行顶栏在无月龄时不露出月龄段。

**Non-Goals:**

- 不改 `loadBaby` 占位字符串的存储/同步语义（设置页、广场同步等可继续识别 `未绑定宝宝ID`）。
- 不改喂养头像未登录直达 `/settings` 的既有约定。
- 不改预测头像未登录走 `/login` 的既有路径（本次只改卡片）。
- 不新增页内常驻「去登录」按钮（门闸 CTA 即明确 CTA）。
- 量身定做（recall）进页/会话弹窗行为不在本变更收窄范围。
- 不新建测试文件；不改小组件 header 载荷格式。

## Decisions

### D1. 会话/绑定感知放在 L2 Provider，不污染 L1 纯函数

- **选择**：`babyDisplayProvider` watch `sessionProvider` + `deviceNoNotifierProvider`（或等价），按态覆盖昵称与月龄可见性；L1 `displayBabyNickname` 等仍只吃 `BabyProfile?`。
- **理由**：登录态是横切输入，不应塞进纯 profile 原子；两页顶栏已统一吃 Provider。
- **备选**：仅 UI 分支 → 易漏空历史等调用点；改 `loadBaby` 返回 null → 撞上「空→宝宝」且混淆 loading。

### D2. 三态文案与月龄约定

| 态 | 昵称 | 月龄 |
|----|------|------|
| 未登录 | `未登录` | 不展示（`ageText` 空串；`showAge == false`） |
| 已登录未绑定 | `未绑定宝宝` | 不展示 |
| 已登录已绑定 | L1(`profile`) | L1 月龄 |

- 绑定判定：`loggedIn && deviceNo.trim().isNotEmpty`（与预测门闸一致）。
- `identityLine`：无月龄时仅为昵称，不得拼接 ` · `。
- 快照可增 `showAge`（或约定空 `ageText` 即隐藏）；喂养 header / 预测顶栏按此渲染。

### D3. 占位 nickname 防御

- 即使误走到 L1，可将 `未绑定宝宝ID` 视为无效昵称回退「宝宝」——作为原子加固，**不**作为未登录文案来源。
- 未登录/未绑定文案 **只** 由 D1 会话分支产出，避免依赖占位字符串漂移。

### D4. 登录/绑定门闸改为意图触发（进页不弹）

- `predictionLoginGateVisibleProvider` / `predictionBindGateVisibleProvider` 默认 **`false`**。
- 登出、登录后仍未绑定、deviceNo 变空：**不得**把 visible 强制为 `true`（保持 false，等骨架卡）。
- 骨架卡 cold tap：打开对应门闸（`visible=true`），**禁止** `push('/login'|'/settings/bind-baby')`。
- 整页空白 `GestureDetector.onTap` 与布局切换按钮：**不得**对 login/bind 调用 reopen；recall 再弹可保留独立路径。
- 跳转仍仅门闸 CTA。
- 已绑定空历史冷态（量身定做）保持现有 toast / recall 行为。

### D5. UI 接线

- `HomeImmersiveHeader`：`ageText` 为空则 identity 仅 nickname。
- 预测顶栏：`showAge`/空月龄时不渲染第二行 `ageText`。

### D6. Auth 冷态滑动引导大卡（方案 A）

- 条件：`!loggedIn || !bound`（不含已绑定空历史量身定做）。
- 隐藏「值得留意」与「接下来3小时」（含演示健康卡）；底 tip 一并隐藏以减噪。
- 展示一张 `panelGlass` 大卡：无跳转按钮、不导航主壳、不打开登录门闸。
- 文案：「左右滑动，看看别处」+「左滑进广场 · 右滑去喂养」。
- 左右箭头：持续水平位移（外扩/回弹）+ 心跳缩放（对齐 `_HeartbeatLogo` 的 0.92–1.08 / ~800ms）。
- **保留**下方预测事件骨架网格（点卡仍 `openGateFromIntent`）。
- 已绑定空历史：仍用演示留意卡 + 接下来3小时。

### D7. 箭头点击弹框教滑动（左右文案分开）

- **目的**：养成左右滑习惯；登录绑定后大卡消失，不能依赖箭头当永久捷径。
- **触发**：仅左右 chevron 可点；中间标题/副文案不可点开弹框。
- **行为**：`showGlassDialog`（或等价玻璃弹框）+「知道了」关闭；**MUST NOT** `animateToPage` / 改主壳 index；**MUST NOT** 打开 login/bind 门闸。
- **左箭头文案**：标题「请向左滑动」；正文「左滑可进入广场，看看真实带娃家庭」。
- **右箭头文案**：标题「请向右滑动」；正文「右滑可进入喂养，记录宝宝作息」。
- **理由**：点左/右误以为直达时，对症说明该方向的滑动动作。

## Risks / Trade-offs

- [loading 闪一下「未登录」vs「宝宝」] → 未登录优先于 loading 空态；已登录 loading 仍可短暂 L1 空态「宝宝」。
- [deviceNo 异步晚到，已登录短暂显示「未绑定宝宝」] → 与现门闸 bound 判定一致，可接受；deviceNo 就绪后自动切真身份。
- [空历史「还没有为 未登录 记录」] → 未登录喂养空态已走「尚未登录」分支，不插值昵称；确认调用点不误用 guest 昵称。
- [游客可能不知道要点卡才登录] → 顶栏已写「未登录」；接受可逛演示的产品取舍。
- [与旧「进入即弹 / 任意点击再弹」规格冲突] → 本变更 MODIFIED/ADDED 覆盖该语义。

## Migration Plan

- 纯客户端展示/交互；无数据迁移。
- 回滚：还原 Provider 默认值、listen 强制可见、空白 reopen 与卡 tap 即可。

## Open Questions

- （无；进页不弹 + 仅骨架卡唤起已确认。）
