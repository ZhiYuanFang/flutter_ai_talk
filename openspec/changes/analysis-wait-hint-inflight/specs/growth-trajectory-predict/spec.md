## ADDED Requirements

### Requirement: Growth trajectory SHALL show a long-wait hint only while streaming

While a growth-trajectory turn is in the streaming thinking phase, the workspace SHALL show a static hint that analysis is being prepared for this child, that it takes a while, and that the user may leave and return later to see the result. The hint MUST remain visible for the whole streaming phase and MUST NOT be written into the streaming thinking text. The hint MUST NOT be shown while the workspace is asking the user to answer a question. 成长轨迹仅在流式思考阶段 **必须** 展示静态等待说明，且 **不得** 写入思考流正文；提问作答阶段 **不得** 展示该说明。

#### Scenario: 流式思考中可见等待说明

- **WHEN** 成长轨迹处于流式思考且结果或下一题尚未返回
- **THEN** 页面 MUST 在思考区之外展示等待说明
- **AND** 思考流增量 MUST NOT 清除或替换该说明

#### Scenario: 提问阶段不展示离开提示

- **WHEN** 成长轨迹处于向用户提问并等待作答
- **THEN** 页面 MUST NOT 展示「可以先离开、回来再看结果」的等待说明

#### Scenario: 空闲或已有结果时不展示该说明

- **WHEN** 成长工作台处于未开始、加载历史或已展示结果
- **THEN** 页面 MUST NOT 展示上述等待说明
