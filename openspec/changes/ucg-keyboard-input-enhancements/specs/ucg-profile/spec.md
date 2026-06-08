## MODIFIED Requirements

### Requirement: Profile inline edit fields SHALL use keyboard bridge

Nickname and bio editing on 我的页 MUST use `ManagedKeyboardTextField` in **hidden** mode: tapping edit MUST focus the hidden field and show the keyboard-top confirm bar as the sole editing surface. The profile header MUST remain static read-only text while editing; the page MUST NOT swap to a visible inline `TextField` for nickname or bio. `onConfirm` MUST map to existing commit/save handlers. Blur without confirm MUST discard draft, restore the attach-time snapshot, and MUST NOT invoke `onConfirm`.

我的页昵称与简介编辑必须使用 hidden 模式 `ManagedKeyboardTextField`：点编辑聚焦隐藏字段，键盘+确认条为唯一编辑面；编辑期间资料头部保持静态只读展示，不得 inline 可见 TextField 切换；失焦未确定必须丢弃草稿恢复快照且不调用 `onConfirm`。

#### Scenario: 编辑昵称仅经确认条
- **WHEN** 用户在我的页点击编辑昵称
- **THEN** 资料头部昵称 SHALL 保持静态只读展示
- **AND** 系统 SHALL 聚焦 hidden 昵称字段并展示键盘顶部确认条
- **AND** SHALL NOT 在头部位置显示可见 TextField

#### Scenario: 确定提交昵称
- **WHEN** 用户在昵称编辑场景点击确认条「确定」
- **THEN** App SHALL 回填昵称并执行 `_commitNickname` 或等效保存逻辑

#### Scenario: 昵称失焦丢弃未确认修改
- **WHEN** 用户编辑昵称但未点「确定」即失焦
- **THEN** App SHALL 恢复编辑开始时的昵称展示
- **AND** SHALL NOT 调用 `_commitNickname` 或等效保存

#### Scenario: 编辑简介仅经确认条
- **WHEN** 用户在我的页点击编辑简介
- **THEN** 资料头部简介 SHALL 保持静态只读展示
- **AND** 系统 SHALL 聚焦 hidden 简介字段并展示键盘顶部确认条

#### Scenario: 简介失焦丢弃未确认修改
- **WHEN** 用户编辑简介但未点「确定」即失焦
- **THEN** App SHALL 恢复编辑开始时的简介展示
- **AND** SHALL NOT 调用简介保存 `onConfirm`

## ADDED Requirements

### Requirement: Profile nickname input SHALL NOT allow newline insertion

The profile nickname managed input (`scene: ucg.profile.nickname`) MUST NOT offer newline insertion via long-press draft menu or any other confirm bar affordance.

资料昵称输入不得提供换行插入能力（含长按草稿「换行」菜单）。

#### Scenario: 昵称场景无换行菜单
- **WHEN** 用户在 `ucg.profile.nickname` 场景尝试长按确认条草稿
- **THEN** 系统 SHALL NOT 展示「换行」菜单

### Requirement: Profile bio input SHALL allow newline via confirm bar

The profile bio managed input (`scene: ucg.profile.bio`) MUST allow newline insertion via the confirm bar long-press draft「换行」menu, consistent with other multiline-eligible UCG scenes.

资料简介输入必须允许通过确认条长按草稿「换行」菜单插入换行，与其他允许多行的 UCG 场景一致。

#### Scenario: 简介长按换行
- **WHEN** 用户在 `ucg.profile.bio` 场景长按确认条草稿并选择「换行」
- **THEN** 系统 SHALL 在简介当前选区插入换行符
