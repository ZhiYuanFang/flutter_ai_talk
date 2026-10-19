## 1. 提交体

- [x] 1.1 `SatisfactionSurveyRepository` 的 submit 改为发送 `campaignId`、`optionResults`、`comment`，不再发送 `optionIds`

## 2. Sheet

- [x] 2.1 每个选项一行三个互斥选择：未使用、不好用、好用；未选保持空白，不默认成未使用。颜色仍用 `AppColor`，意见框控制器仍由 sheet State 持有并在 dispose 释放
- [x] 2.2 只提交点过的行，意见可空；一项都没选且意见为空白不 POST。每条结果为选项原文直接连接所选中文，顺序与 current 的 options 一致
- [x] 2.3 未评完、双空、超长和 POST 失败仍在提交按钮上方展示，不 toast；改某一行评价或改意见时清掉该行错误

## 3. 收尾

- [x] 3.1 新增或修改的代码补中文业务注释；不新增 `**/test/**` 测试文件；不改 GET、主壳门闩和日志 tag
