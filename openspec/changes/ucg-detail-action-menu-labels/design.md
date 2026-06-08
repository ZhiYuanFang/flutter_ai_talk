## Context

`UcgMomentsActionMenu`（`ucg_feed_moments_widgets.dart`）在详情页时间行右侧作为「··」触发器，点击后在左侧弹出 detached pill，内含点赞、评论、删除（作者可见）三个 `_ActionIcon`。当前每项仅渲染 Material Icon，无文字说明；用户已自行调整图标尺寸，本变更仅补充文案标签。

## Goals / Non-Goals

**Goals:**

- 展开 pill 每项展示「图标 + 中文标签」横向排列：点赞、评论、删除。
- 整项（图标+文字）可点击，行为与现有一致（点击后收起浮层并触发回调）。
- 已赞时心形图标高亮为 primary，标签颜色与图标一致。

**Non-Goals:**

- 不调整「··」触发按钮尺寸（由开发者本地自行维护）。
- 不改变 API、路由、浮层锚点/动画/点外收起逻辑。
- 不在 Feed 卡片或其他页面引入带标签菜单（当前组件仅详情使用）。

## Decisions

### 1. 扩展 `_ActionIcon` 增加 `label` 参数

**选择**：在现有 `_ActionIcon` 上增加必填 `String label`，内部用 `Row(icon, SizedBox, Text)` 布局。

**理由**：三处调用点语义清晰，避免重复三个几乎相同的 widget。

**备选**：三个独立 widget —— 过度拆分，否决。

### 2. 文案固定为「点赞 / 评论 / 删除」

**选择**：无论 `likedByMe` 状态，点赞项文案恒为「点赞」。

**理由**：与用户明确需求一致；已赞态通过实心图标表达，避免「取消赞」文案歧义。

### 3. 样式

- 文案 `fontSize: 13`，`fontWeight: w500`，`color` 与图标同色。
- 图标与文案间距 `4` 逻辑像素；项内 padding 沿用或略增（如 `horizontal: 8, vertical: 6`）以扩大可点区域。
- pill 外层 `horizontal` padding 可由 `4` 增至 `6`，圆角可选 `8` 与评论删除浮层一致。

### 4. 布局方向

pill 仍通过 `CompositedTransformFollower` 锚定在触发器左侧；加文案后 pill 变宽并向左延伸，详情页全宽布局下无额外滚动需求。

## Risks / Trade-offs

- **[Risk] 窄屏 Web 上 pill 过宽** → 详情页时间行右侧锚点向左展开，通常有足够空间；若极端窄屏裁切，可后续减字号或缩短间距（非本变更范围）。
- **[Trade-off] 纯图标更紧凑** → 用户明确要求加文案，可读性优先。

## Migration Plan

纯客户端 UI 变更，随 App 发版即可；无数据迁移与回滚依赖。

## Open Questions

（无）
