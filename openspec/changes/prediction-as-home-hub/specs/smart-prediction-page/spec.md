## MODIFIED Requirements

### Requirement: Home pager page 0 SHALL host the smart prediction page

The Flutter `/home` PageView index **1** SHALL render the smart prediction page (not Clinic/companion chat) and SHALL be the default landing page. Deep link `/pangbao` (or equivalent legacy companion entry) MUST request navigation to the prediction page (index 1). Because prediction is the default landing, cold start at `/home` MUST mount the prediction page without requiring a prior swipe.

App `/home` PageView index 1 **必须** 为智能预测页（默认着陆）而非 Clinic/陪伴聊天；冷启动进入 `/home` **必须** 挂载预测页；`/pangbao` 等旧入口 **必须** 切到预测页（index 1）。

#### Scenario: 冷启动挂载预测页

- **WHEN** 用户冷启动进入 `/home`
- **THEN** App SHALL 挂载智能预测页于 page 1
- **AND** MUST NOT 挂载陪伴聊天 UI 作为 pager 页职责

#### Scenario: /pangbao 进入预测页

- **WHEN** 用户打开 `/pangbao` 深链（或等价）
- **THEN** 客户端 MUST 导航至 `/home` 并请求 PageView 显示预测页（index 1）

## ADDED Requirements

### Requirement: Prediction header SHALL show baby avatar nickname and age

The smart prediction page top bar MUST NOT show the static title「智能预测」as the primary heading. It SHALL show the current baby’s avatar, nickname, and age-in-months text derived from `birthDate` (via `formatBabyAgeText` or equivalent). Layout toggle and other existing trailing actions MAY remain.

智能预测顶栏 **不得** 以「智能预测」作为主标题；**必须** 展示宝宝头像、昵称与由生日计算的月龄文案；布局切换等既有尾部动作 MAY 保留。

#### Scenario: 有宝宝资料时展示身份条

- **WHEN** 用户打开智能预测页且本地宝宝资料可用
- **THEN** 顶栏 MUST 展示头像、昵称与月龄文案
- **AND** MUST NOT 展示主标题「智能预测」

#### Scenario: 月龄随生日计算

- **WHEN** 宝宝生日对应完整月龄为 N（N≥1）
- **THEN** 顶栏月龄文案 MUST 与 `formatBabyAgeText` 规则一致（如「N个月啦」或岁/月组合）

### Requirement: Tapping prediction header avatar SHALL open baby profile editor

Only the baby avatar hit target on the prediction header SHALL navigate to the baby profile edit route (`/settings/baby` or equivalent). Tapping nickname or age text MUST NOT open the editor. Unauthenticated users MUST follow the same login gate as other settings baby-edit entries.

仅头像热区 **必须** 进入编辑宝宝信息页；点击昵称/月龄 **不得** 进入编辑；未登录 **必须** 与设置侧编辑入口同一登录门。

#### Scenario: 点击头像进编辑

- **WHEN** 已登录用户在预测顶栏点击宝宝头像
- **THEN** 客户端 MUST 打开 `/settings/baby`（或等价编辑页）

#### Scenario: 点击昵称不进编辑

- **WHEN** 用户点击预测顶栏昵称或月龄文案（非头像）
- **THEN** 客户端 MUST NOT 仅因此打开宝宝编辑页
