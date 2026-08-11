## ADDED Requirements

### Requirement: 喂养沉浸头身份条 MUST 反映登录与绑定态且可隐藏月龄

When the feeding immersive header renders the identity strip from the baby display snapshot, unauthenticated users MUST see nickname「未登录」with no age segment. Logged-in unbound users MUST see「未绑定宝宝」with no age segment. When age text is empty / `showAge` is false, the header MUST render only the nickname (MUST NOT show「 · {age}」). When logged in and bound with usable age text, the header MUST keep the「{nickname} · {ageText}」single-line form with trailing ellipsis.

喂养沉浸头身份条经展示快照渲染时：未登录 **必须** 显示「未登录」且无月龄段；已登录未绑定 **必须** 显示「未绑定宝宝」且无月龄段；月龄为空 / 不展示时 **必须** 仅显示昵称（**不得** 出现「 · {月龄}」）；已登录已绑定且有月龄时 **必须** 保持「{昵称} · {月龄}」单行省略形式。

#### Scenario: 未登录顶栏

- **WHEN** 用户未登录进入喂养页
- **THEN** 沉浸头身份文案 MUST 为「未登录」
- **AND** MUST NOT 展示月龄或「 · 」分隔段

#### Scenario: 已登录未绑定顶栏

- **WHEN** 用户已登录、无可用 deviceNo，进入喂养页
- **THEN** 沉浸头身份文案 MUST 为「未绑定宝宝」
- **AND** MUST NOT 展示月龄或「 · 」分隔段

#### Scenario: 已绑定仍为昵称点月龄

- **WHEN** 用户已登录已绑定且快照含非空月龄
- **THEN** 沉浸头身份文案 MUST 为「{昵称} · {月龄文案}」单行形式
