## ADDED Requirements

### Requirement: Profile post timeline text SHALL collapse to two lines

On the owner profile「我的动态」timeline (`UcgMyPostTimelineItem`), post body text MUST display at most **two lines** with tail ellipsis (`TextOverflow.ellipsis`). Full text remains available on post detail navigation.

个人主页动态时间轴正文最多展示两行，超出省略；完整正文在详情页查看。

#### Scenario: 长文动态列表省略
- **WHEN** 某条动态正文超过两行
- **THEN** 时间轴行 SHALL 仅展示两行并以 `…` 截断
- **AND** 点击该行 SHALL 仍可进入详情查看全文

#### Scenario: 短文不受影响
- **WHEN** 动态正文不足两行
- **THEN** UI SHALL 展示完整正文且无多余省略号

### Requirement: Profile header SHALL use compact top spacing

The unified profile shell (`UcgProfileShell`) MUST reduce excessive top whitespace in expanded header layout by tightening flexible top padding and/or expanded header height constants so profile content sits higher on screen while preserving pinned collapse behavior and avatar morph animation.

个人主页资料头须收紧顶部留白，使内容整体上移，且保留折叠顶栏与头像 morph 行为。

#### Scenario: 展开态顶部留白减少
- **WHEN** 用户打开「我的」或他人资料页且 header 处于展开态
- **THEN** 资料卡相对屏幕顶部的空白 SHALL 明显小于变更前
- **AND** 返回按钮/leading 与资料卡 SHALL 仍不重叠

#### Scenario: 折叠滚动仍正常
- **WHEN** 用户向上滚动动态列表
- **THEN** 资料头 SHALL 仍折叠为 pinned 顶栏
- **AND** 头像 morph 动画 SHALL 保持流畅

#### Scenario: 有 bio 与无 bio
- **WHEN** 用户资料含简介或为空
- **THEN** 两种情况下 header 高度 MAY 不同
- **AND** 均须满足紧凑顶部间距要求
