## ADDED Requirements

### Requirement: Prediction bottom tip visibility SHALL match widget tip text presence

The smart prediction page bottom tip bar SHALL become visible when the locally cached widget tip body text (trimmed) is non-empty, and MUST NOT hide that bar solely because the tip day key is missing or is not the current local calendar day. When the trimmed tip body is empty or absent, the page MUST hide the entire bottom tip bar. 智能预测页底栏 tip **必须**在本地缓存的小组件 tip 正文（trim 后）非空时展示，**不得**仅因 tip 的 dayKey 缺失或非当日而隐藏；正文空或缺省时 **必须**隐藏整条底栏。

#### Scenario: 有 tip 正文即显示底栏（不要求当日）

- **WHEN** SharedPreferences（或等价）中小组件 tip 正文 trim 后非空，且 dayKey 缺失或不是今天
- **AND** 用户停留在智能预测页
- **THEN** 页面 MUST 渲染底部 tip 条（横向跑马灯形态沿用既有底栏要求）
- **AND** MUST NOT 因 dayKey 非当日而隐藏该条

#### Scenario: 无 tip 正文则隐藏

- **WHEN** tip 正文缺失或 trim 后为空
- **THEN** 页面 MUST NOT 渲染底部 tip 条占位

### Requirement: Tip cache updates SHALL refresh prediction tip display

After the client successfully writes a non-empty widget tip body into the tip cache used by the prediction page (including home-widget sync paths that persist tip text for display), the smart prediction tip provider (or equivalent) MUST re-read that cache so a previously empty bottom tip bar can appear without requiring an unrelated navigation away from the prediction page. 客户端将非空 tip 正文写入预测页所用 tip 缓存后（含会持久化 tip 文案的小组件 sync 路径），预测 tip provider（或等价）**必须**重新读取缓存，使先前为空的底栏可在不离开预测页的情况下出现。

#### Scenario: sync 写入 tip 后底栏出现

- **WHEN** 用户已在智能预测页且当时 tip 缓存为空故底栏隐藏
- **AND** 随后小组件 tip 同步将非空正文写入 tip 缓存
- **THEN** 预测页 MUST 在合理时间内展示底部 tip 条（经 invalidate / 重 peek 或等价），MUST NOT 一直停留在「已有文案仍不显示」状态直至用户强制杀进程

### Requirement: Bottom tip horizontal marquee SHALL scroll at half prior speed

When the bottom tip bar scrolls horizontally due to overflow, the marquee linear speed MUST be approximately half of the previous client default (previously about 36 logical pixels per second, now about 18). Short text that does not overflow MUST remain static. 当底栏 tip 因溢出而横向滚动时，跑马灯线速度 **必须**约为先前默认的一半（先前约 36 逻辑像素/秒，现约 18）；未溢出短文 **必须**保持静止。

#### Scenario: 溢出文案更慢滚动

- **WHEN** 底栏 tip 正文宽度超过可视宽度因而启用横向跑马灯
- **THEN** 滚动线速度 MUST 约为变更前一半（约 18 logical px/s）

#### Scenario: 短文仍静止

- **WHEN** 底栏 tip 正文宽度未超过可视宽度
- **THEN** 文案 MUST NOT 横向滚动动画
