## ADDED Requirements

### Requirement: Unified glass bottom sheet entry

The client SHALL provide a single shared function (e.g. `showGlassAdaptiveBottomSheet`) as the preferred entry for modal bottom sheets that use glassmorphism chrome. 客户端 MUST 提供统一的玻璃 Bottom Sheet 入口；调用方 MUST 通过该入口获得透明 `showModalBottomSheet` 外层、统一半透明遮罩、最大高度约束，以及默认包裹的 `HistoryEditGlassPanel`（可通过参数关闭包裹）。

#### Scenario: Opening catalog picker

- **WHEN** the user opens the event catalog child picker sheet
- **THEN** the sheet MUST be presented via the glass overlay entry and MUST NOT use a solid theme-blend Material sheet background as the visible panel

#### Scenario: Transparent outer chrome

- **WHEN** any feature calls the glass bottom sheet entry with default options
- **THEN** the modal bottom sheet background MUST be transparent and the visible rounded panel MUST be the inner glass panel

#### Scenario: Max height preserved

- **WHEN** sheet content exceeds the configured max height fraction (default two-thirds of screen height)
- **THEN** the layout MUST cap height and MUST allow internal scrolling without exceeding the cap

### Requirement: Unified glass centered dialog entry

The client SHALL provide a shared centered dialog entry (e.g. `showGlassDialog`) that wraps content in `HistoryEditGlassPanel` with consistent barrier and padding. 居中模态对话框 MUST 通过共享玻璃 Dialog 入口展示；视觉 MUST 与底部玻璃 Sheet 使用同一 `HistoryEditGlassPanel` 规范（磨砂、渐变、描边、固定浅色前景）。

#### Scenario: Settings confirmation

- **WHEN** the user triggers a destructive or settings confirmation that previously used `AlertDialog`
- **THEN** the UI MUST present a centered glass panel via the shared dialog entry instead of a default Material `AlertDialog` surface

#### Scenario: Active timing reminder

- **WHEN** the active timing reminder is shown after adding a record
- **THEN** it MUST use the shared glass dialog entry while preserving centered placement and existing stop/select behavior

### Requirement: Glass overlay readable foreground

The glass overlay entries SHALL render primary text and labels with the same fixed light foreground tokens as history edit sheets. 玻璃弹层内的标题、正文、列表项主文字 MUST 使用 `historyEditGlassTextColor` / `historyEditGlassLabelColor`（或 `HistoryEditGlassPanel` 静态色），MUST NOT 随 shell 浅色主题变为深色而导致对比不足。

#### Scenario: Catalog picker list on glass

- **WHEN** the catalog picker lists folder and leaf rows inside the glass sheet
- **THEN** row titles and breadcrumbs MUST remain readable on the tinted glass background

### Requirement: Optional event accent on glass shell

The glass overlay entries MUST accept an optional event accent color passed to `HistoryEditGlassPanel` for gradient tinting. 调用方 MUST 可将事件品牌色传入玻璃面板以染色底部渐变；未传入时 MUST 使用主题 primary 作为 accent。

#### Scenario: Number event sheet accent

- **WHEN** the number event add sheet is opened for a branded event
- **THEN** the glass panel gradient MUST reflect that event color when accent is supplied
