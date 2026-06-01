## ADDED Requirements

### Requirement: Unbound Baby Invitation View
The system SHALL display a prominent invitation view containing a 3D-style animation and a primary action button when the current user has not bound any baby information.
系统必须在用户未绑定宝宝信息时，展示一个包含 3D 风格动画和主要操作按钮的邀请视图。

#### Scenario: User arrives at home with no baby bound
- **WHEN** user is logged in but `deviceNo` is null or empty
- **THEN** the home screen body displays a welcoming 3D animation (e.g., "ani_baby_welcome.json") and a button labeled "立即绑定宝宝信息"
- **THEN** clicking the button navigates to the baby binding screen

### Requirement: No History Encouragement View
The system SHALL display an encouragement view with a 3D-style animation theme when a baby is bound but there are no history records for the current day.
系统必须在已绑定宝宝但当日无记录时，展示一个以 3D 动画为主题的鼓励记录视图。

#### Scenario: User has bound baby but no records today
- **WHEN** consumer watches `homeHistoryProvider` and `items` is empty, AND `deviceNo` is valid, AND initial load is complete
- **THEN** the home screen body displays a baby-themed 3D animation (e.g., "ani_baby_life.json")
- **THEN** the view displays text like "给 [宝宝昵称] 记录下第一笔吧" (The name SHALL be fetched from `settingsBabyProvider`)

### Requirement: Layout Auto-Suppression
The system SHALL hide auxiliary status and summary components when the 3D empty state visuals are active to maintain visual focus.
当展示 3D 空状态视觉效果时，系统必须隐藏辅助状态和汇总组件，以保持视觉焦点。

#### Scenario: Clean layout in empty state
- **WHEN** the Unbound Baby Invitation or No History Encouragement view is visible
- **THEN** the `HomeTodaySummaryPanel` MUST be hidden
- **THEN** the top binding banner (from `showBindBanner` logic) MUST be hidden
- **THEN** the background SHALL remain consistent with the app's shell theme
