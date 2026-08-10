## REMOVED Requirements

### Requirement: Per-event forecast toggle SHALL persist locally and default ON

**Reason**: 产品去掉每事件推演开关，全部事件始终参与推演。  
**Migration**: 预测页、首页 tip、排序与图表均不再读取推演关闭集合；本地关闭态忽略。

## ADDED Requirements

### Requirement: Smart prediction page SHALL toggle list and grid card layouts from the title bar

The smart prediction page SHALL expose a single tappable icon in the title row (top-trailing) that toggles event chart cards between a vertical list layout and a two-column grid layout. The selected layout MUST persist locally across app restarts. The default layout MUST be **grid**.

智能预测页标题行右上角 **必须** 提供可点图标以在纵向列表与双列网格间切换；所选布局 **必须** 本地持久化；默认 **必须** 为网格。

#### Scenario: 默认网格

- **WHEN** 用户首次安装或无已存布局偏好时打开智能预测页
- **THEN** 事件卡片区 MUST 以双列网格展示

#### Scenario: 切换并持久化

- **WHEN** 用户在网格态点击标题右上角图标切到纵向，再杀死并重启 App 后打开预测页
- **THEN** 事件卡片区 MUST 仍为纵向列表

### Requirement: List layout SHALL omit the「下次 ·」prefix but keep relative time

In vertical list layout, when a relative-time line is shown for a predicted event, the client MUST NOT prefix it with「下次 ·」(or equivalent). The relative-time text itself MUST still be shown (e.g. existing upcoming/overdue phrasing without that prefix).

纵向布局展示相对时间时 **不得** 加「下次 ·」前缀，但 **必须** 仍展示相对时间正文。

#### Scenario: 纵向无下次前缀

- **WHEN** 纵向布局下事件 A 可预测且展示相对时间
- **THEN** 文案 MUST NOT 以「下次」作为前缀
- **AND** MUST 仍包含相对时间含义（如「约 x 分钟后」或「已超时 …」类）

### Requirement: Grid layout SHALL use three calendar days without Y-axis and short relative copy

In grid layout, each event chart SHALL use the three local calendar days **day-before-yesterday / yesterday / today** as the X axis, MUST NOT display the Y-axis (no Y tick labels / Y axis line as a visible scale), and MUST show a short relative-time affordance of the form similar to「超时 x 分钟」or「x 小时后」(without「下次」). Chart point selection rules within those three days MUST remain consistent with the page’s TOD-near / today-nextAt rules applied to that shortened window.

网格布局下折线 X **必须** 为前天/昨天/今天三自然日；**必须** 不显示 Y 轴刻度/轴线；**必须** 使用「超时 x 分钟 / x 小时后」类短文案；三点窗口内取点规则 **必须** 与既有 TOD-near / 今日 nextAt 规则在缩窗上一致。

#### Scenario: 网格三日无 Y

- **WHEN** 布局为网格且事件 A 展示折线
- **THEN** X 轴日标签 MUST 覆盖前天、昨天、今天（有点之日按既有省略规则可仍只标有数据日，但窗口 MUST 为这三日）
- **AND** MUST NOT 展示 Y 轴时刻刻度

#### Scenario: 网格短文案

- **WHEN** 网格布局下事件 A 的 nextAt 已超时约 12 分钟
- **THEN** 卡片提示 MUST 呈现类似「超时 12 分钟」的短文案
- **AND** MUST NOT 使用「下次 ·」前缀

### Requirement: All listed events SHALL participate in forecast without a per-event toggle

The smart prediction page MUST NOT offer a per-event forecast toggle. Every listed event that can compute a prediction MUST be treated as forecast-enabled for charting and relative-time display on this page, and the home prediction tip MUST NOT exclude events based on a local per-event forecast-off set.

预测页 **不得** 提供每事件推演开关；可预测事件 **必须** 视为开启推演；首页 tip **不得** 再按本地推演关闭集合排除事件。

#### Scenario: 无开关且可预测即展示图

- **WHEN** 事件 A 可计算 nextAt
- **THEN** 卡片 MUST 展示其折线与相对时间（随当前布局样式）
- **AND** MUST NOT 展示推演 Switch
