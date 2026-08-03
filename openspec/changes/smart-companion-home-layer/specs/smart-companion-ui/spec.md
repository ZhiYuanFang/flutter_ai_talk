## ADDED Requirements

### Requirement: Companion screen SHALL use cute real-glass visual language

The smart companion page SHALL render its chrome (app bar / header region, message surfaces, and composer) with cute glassmorphism that uses real `BackdropFilter` (or equivalent true blur) rather than feed-style fake glass. 智能陪伴页的顶栏区域、消息表面与输入区 **必须** 采用可爱真玻璃视觉（真 blur）；**不得** 使用广场 Feed 假玻璃作为陪伴页主表面。

#### Scenario: 陪伴页可见真玻璃

- **WHEN** 用户进入智能陪伴页且已展示对话壳
- **THEN** 主表面 MUST 使用真玻璃（`BackdropFilter` 或项目统一真玻璃 panel）
- **AND** UI MUST 呈现圆角、柔和 tint 的可爱气质（非医疗冷色器械风）

### Requirement: Companion copy SHALL drop clinic branding and keep soft non-medical notice

The companion page MUST NOT present「诊疗」as the primary product title or input placeholder. After a successful assistant answer, the client MUST show a soft non-medical notice such as「非医疗建议」（or equivalent）， and MUST NOT show the strong medical disclaimer「本回答仅供参考，不能替代医生诊断」. 陪伴页主标题/输入提示 **不得** 使用「诊疗」品牌语；成功回答后 **必须** 展示「非医疗建议」类弱提示，**不得** 再展示强医嘱免责句。

#### Scenario: 标题与输入去诊疗化

- **WHEN** 用户查看智能陪伴页顶栏与输入框
- **THEN** 标题 MUST 为智能陪伴（或等价陪伴文案）
- **AND** 输入 hint MUST NOT 包含「诊疗」

#### Scenario: 成功回答弱提示

- **WHEN** 助手轮次成功完成（`answer_done`）
- **THEN** UI MUST 展示「非医疗建议」弱提示
- **AND** MUST NOT 展示「不能替代医生诊断」

### Requirement: Companion consent dialog SHALL use companion wording

Before establishing companion Clinic WebSocket or sending questions, the client MUST obtain consent via a glass dialog whose title/body use companion wording (not「胖宝诊疗」). 建连或发问前 **必须** 以陪伴语境玻璃告知弹窗取得同意；文案 **不得** 以「胖宝诊疗」为主标题。

#### Scenario: 首次使用告知

- **WHEN** 用户尚未持久化陪伴/原诊疗同意且尝试在陪伴页发问或触发自动「我来啦」
- **THEN** 客户端 MUST 展示陪伴语境告知弹窗
- **AND** 在同意前 MUST NOT 发送 question 帧

### Requirement: Companion page SHALL offer clear-history control with glass confirm

The companion page MUST expose a clear-history action at the top-right. Activating it MUST show a glass confirmation dialog; only after confirm MUST the client clear in-memory companion messages and the per-`deviceNo` local companion session store (including truncation dividers). The action MUST NOT invoke `feedRepository.clearCache()` or change settings/account cache-clear behavior. 陪伴页右上角 **必须** 提供清理入口；**必须** 经玻璃二次确认后清空内存与本地陪伴会话；**不得** 调用全局 `clearCache` 或改变设置/账号清缓存策略。

#### Scenario: 取消不清理

- **WHEN** 用户点击右上角清理后在玻璃弹窗选择取消
- **THEN** 对话列表与本地 store MUST 保持不变

#### Scenario: 确认后清空陪伴记录

- **WHEN** 用户在玻璃弹窗确认清理
- **THEN** 客户端 MUST 清空当前 device 的陪伴内存列表与本地会话快照
- **AND** MUST NOT 调用 `feedRepository.clearCache()`

### Requirement: Companion page MUST NOT show AI quota remaining UI

The companion page MUST NOT display monthly clinic/companion quota remaining or degraded-quota copy. 陪伴页 **不得** 展示本月额度剩余或「额度用完/已降速」类文案。

#### Scenario: 无额度条

- **WHEN** 用户打开智能陪伴页
- **THEN** UI MUST NOT 渲染 clinicAi / 陪伴额度剩余提示

### Requirement: Immersive home header MUST remove clinic entry

The feeding immersive header MUST NOT provide a control that opens the legacy clinic route (`/pangbao`) as the primary companion entry. 喂养沉浸式头部 **不得** 再提供进入原诊疗路由的主入口。

#### Scenario: 顶栏无诊疗入口

- **WHEN** 用户查看喂养页沉浸式头部
- **THEN** UI MUST NOT 展示可 `push('/pangbao')` 的诊疗/陪伴图标入口（进入陪伴改由 PageView / 拉条 / 小贴士）
