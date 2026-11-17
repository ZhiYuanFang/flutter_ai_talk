## ADDED Requirements

### Requirement: Home shell SHALL persist last feeding or prediction page

When the user changes the home pager visible page to **feeding** or **prediction**, the client MUST persist that page as the last landing preference (SharedPreferences or equivalent). When the visible page is **UCG**, the client MUST NOT overwrite the stored preference with UCG. 用户切到喂养或预测时 MUST 持久化该页；切到 UCG 时 MUST NOT 用 UCG 覆盖已存记忆。

#### Scenario: Switch to feeding persists

- **WHEN** 用户将主壳 PageView 切到喂养页
- **THEN** 客户端 MUST 将 lastPage 记为喂养

#### Scenario: Switch to prediction persists

- **WHEN** 用户将主壳 PageView 切到预测页
- **THEN** 客户端 MUST 将 lastPage 记为预测

#### Scenario: UCG does not persist as lastPage

- **WHEN** 用户从喂养或预测滑入 UCG 页
- **THEN** 客户端 MUST NOT 将 lastPage 改为 UCG
- **AND** MUST 保留进入 UCG 前已存储的喂养或预测记忆（若有）

### Requirement: Cold start home shell SHALL land on persisted last page

When the home shell (`UcgHomeShell` or equivalent) creates its PageView on cold start (or process restart into `/home`) and there is no higher-priority explicit pager request yet, the client MUST set `initialPage` to the persisted feeding-or-prediction last page when valid. When no preference exists or the stored value is invalid (including any UCG sentinel), the client MUST land on prediction. The client MUST NOT flash prediction and then jump to feeding solely because prefs loaded asynchronously after first paint when a synchronous prefs read is available. 冷启无更高优切页请求时 MUST 以合法 lastPage 为 initialPage；无记忆或非法 MUST 落预测；有同步可读 prefs 时 MUST NOT 先闪预测再跳喂养。

#### Scenario: Cold start restores feeding

- **WHEN** lastPage 已存为喂养
- **AND** 用户冷启进入 `/home` 且无显式 pager 请求覆盖
- **THEN** 主壳 PageView MUST 初始停在喂养页

#### Scenario: Cold start restores prediction

- **WHEN** lastPage 已存为预测（或用户上次停在预测）
- **AND** 用户冷启进入 `/home`
- **THEN** 主壳 PageView MUST 初始停在预测页

#### Scenario: Missing preference defaults to prediction

- **WHEN** 无 lastPage 记忆（首次安装或键缺失）
- **THEN** 冷启 MUST 落预测页（与历史默认一致）

#### Scenario: Explicit request overrides memory

- **WHEN** 冷启后存在深链或 `requestPage` 等显式切页请求
- **THEN** 客户端 MUST 按该请求切页，MUST NOT 仅因 lastPage 拒绝显式请求
