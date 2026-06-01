## ADDED Requirements

### Requirement: 主页第三输入模式「按钮」

The client SHALL provide a third home input mode **「按钮」** alongside existing voice and text modes on supported platforms, toggled without losing the other modes. 在支持的平台（至少 Android/iOS）上，系统必须提供与语音、文字并列的**按钮**输入模式，用户可切换；切换不得破坏会话与其它模式入口。

#### Scenario: 切换到按钮模式

- **WHEN** 用户选择「按钮」输入
- **THEN** 底部必须展示事件网格面板，且不得展示语音按住区域或文字输入框为主输入

#### Scenario: 切回语音或文字

- **WHEN** 用户从按钮模式切回语音或文字
- **THEN** 必须恢复对应既有主输入 UI

### Requirement: 两行横向事件网格

The system SHALL render the event catalog as **two horizontal scrollable rows** of cells in button mode, each cell showing **logo above name** using event branding (`EventLogo`, `color`). 按钮模式下必须使用**两行**可横向滚动的列表展示目录事件；每个 cell **上图下文**（logo + 名称），颜色来自事件 `color`。

#### Scenario: 目录非空

- **WHEN** `eventCatalogProvider` 含 N 个有效事件
- **THEN** 第一行展示前 ⌈N/2⌉ 项，第二行展示其余项（顺序与目录列表一致）

#### Scenario: 目录为空

- **WHEN** 目录尚未加载或为空
- **THEN** 必须展示空态提示，不得崩溃

### Requirement: 按 eventType 分支点击（非 eventNumber）

The client MUST determine button tap behavior solely from catalog **`eventType`**, not from any `eventNumber` on existing history records. 按钮点击后的流程**必须**仅依据目录项 **`eventType`** 分支，**不得**用历史记录中的 `eventNumber` 推断事件类型。

#### Scenario: number 类型

- **WHEN** 用户点击 `eventType` 为 `number` 的事件
- **THEN** 必须打开二级页（时间、数量、remark），确认后才调用 `add`

#### Scenario: time 类型

- **WHEN** 用户点击 `eventType` 为 `time` 的事件且本地无同 `eventId` 进行中计时
- **THEN** 必须直接调用 `add` 开始计时，不得打开二级页

#### Scenario: one 类型

- **WHEN** 用户点击 `eventType` 为 `one` 的事件
- **THEN** 必须直接调用 `add` 记录一次性事件，不得打开二级页

### Requirement: time 类型重复开始拒绝

The system SHALL reject starting a second active timing session for the same `eventId` in button mode and MUST show a toast including the event name. 当本地已存在同 **`eventId`** 的进行中计时记录（`eventNumber==0` 且结束未设置）时，再次点击该 **time** 事件**不得**调用 `add`，必须 Toast **「{eventName}已在计时中」**。

#### Scenario: 已有进行中计时

- **WHEN** 历史列表中存在 `eventId` 匹配且 `isActiveTimingRecord` 为真的记录
- **THEN** 点击同 catalog `eventId` 的 time 事件必须仅 Toast 提示，不发起网络请求

### Requirement: number 二级页数量与 remark

The client SHALL provide a secondary sheet for `number` events with datetime selection, quantity picker from **5 to 500 inclusive in steps of 5** without free-text numeric entry, and optional remark editing. **`time`** 与 **`one`** 创建时 `remark` 必须为 **空字符串**，且不得提供 remark 编辑 UI。

#### Scenario: 数量选择

- **WHEN** 用户在二级页选择数量
- **THEN** 仅允许滚轮选取 5,10,15,…,500，不得使用手输数字框作为唯一输入

#### Scenario: remark 仅 number

- **WHEN** 用户确认 number 二级页
- **THEN** `add` 请求的 `remark` 必须为二级页内容（可为空）；time/one 的 `add` 必须 `remark: ""`

### Requirement: 创建成功 Toast 文案

The system SHALL show a success toast **「已记录{eventName}」** after a successful `add` in button mode. 按钮模式 `add` 成功（`code==0`）后必须 Toast **「已记录{eventName}」**，其中 `{eventName}` 为目录名称。

#### Scenario: 成功创建

- **WHEN** `POST /device/history/api/event/add` 返回 `code` 为 0
- **THEN** 必须显示「已记录{eventName}」类成功提示，且不得依赖响应 `id` 手动插入列表行
