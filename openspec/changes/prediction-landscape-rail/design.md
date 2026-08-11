## Context

预测页竖屏为顶栏（头像+昵称/月龄+布局切换+调色盘）+ 留意/引导/3小时 + `_WaterfallCards` 双列奇偶分列。横屏宽高比反转后顶栏方案浪费横向空间。产品要求横屏仅左栏竖排身份、右栏 3 列瀑布，并藏掉其余 chrome。

## Goals / Non-Goals

**Goals:**

- `Orientation.landscape` 时：`Row(左竖排身份 | Expanded(瀑布))`；列数手机 3 / 平板 5（`shortestSide >= 600`）。
- 左栏仅昵称 +（可选）月龄，竖排文字；无头像/调色/切布局。
- 横屏不渲染留意、滑动引导、接下来3小时。
- 横屏强制 compact 瀑布且 3 列；不提供列表切换入口。
- 竖屏行为零回归。

**Non-Goals:**

- 不改喂养页 / UCG 页横屏。
- 不改门闸 Dialog 逻辑（登录/绑定/量身定做仍可叠在预测页上）。
- 不改本地 layout preference 存储语义（横屏只是渲染覆盖，回竖屏仍尊重偏好）。
- 不引入 masonry 第三方包；延续自写多列 Column。
- 不新建测试文件。

## Decisions

### D1. 触发：`MediaQuery.orientation == Orientation.landscape`

- 不加 shortestSide 阈值；与产品确认一致。
- 旋转时依赖 Flutter 重建即可。

### D2. 左栏竖排文字

- 将昵称（及月龄，若 `showAge` 且非空）按字符拆成纵向 `Column`（或等价竖排），自上而下阅读。
- 昵称与月龄之间可用间隔或「·」竖位分隔。
- 空间不足：整体可滚动或尾部省略（优先 `SingleChildScrollView` 防溢出）。
- 左栏固定窄宽（如 ~40–56 logical px + padding），不占过多网格宽度。

### D3. 右栏瀑布列数

- `_WaterfallCards` 增加 `columnCount`（默认 2）；按 `i % columnCount` 分列。
- 竖屏：`2`。
- 横屏且 `shortestSide < 600`：`3`（手机）。
- 横屏且 `shortestSide >= 600`：`5`（平板档）。
- 横屏 `effectiveLayout = grid`，忽略当前 list 偏好；不展示切换 IconButton。

### D4. Chrome 隐藏清单（仅横屏）

- 不渲染：顶栏整行工具、`careOrGuide`（留意/滑动引导）、接下来3小时、底 tip。
- 登录/绑定/量身定做 Overlay 仍可在 Stack 上展示（用户点骨架卡等）。

### D5. 竖屏路径

- 现有 `Column` 结构保持；`columnCount: 2`。

## Risks / Trade-offs

- [3 列卡片过窄，倒计时/大 logo 拥挤] → 接受横屏更紧凑；必要时后续再缩 logo，本变更不做。
- [竖排长昵称撑破高度] → 左栏可滚动。
- [横屏藏引导大卡，游客不知可横滑壳层] → 产品明确取舍；竖屏仍有引导。
- [横屏无法切列表] → 产品要求；回竖屏可再切。

## Migration Plan

- 纯 UI；无数据迁移。回滚删横屏分支即可。

## Open Questions

- （无；列数 3、竖排、藏 chrome、强制瀑布已确认。）
