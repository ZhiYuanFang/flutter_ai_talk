## ADDED Requirements

### Requirement: Baby avatar SHALL be editable from baby profile experience

The system SHALL allow the user to change the local baby avatar from the baby profile edit experience and SHALL persist the local avatar reference so that the prediction header and editor show the updated image after save or successful pick (per store design). Changing avatar MUST NOT require a server round-trip for the image file itself.

用户 **必须** 能在宝宝资料编辑体验中更换本地头像，并 **必须** 持久化本地引用供预测顶栏与编辑页展示；头像文件本身 **不得** 强制走服务端上传。

#### Scenario: 更换头像后各处一致

- **WHEN** 用户在编辑页更换宝宝头像并完成保存/落盘流程后返回预测页
- **THEN** 预测顶栏头像 MUST 展示新本地头像
- **AND** 再次进入编辑页 MUST 仍展示同一头像
