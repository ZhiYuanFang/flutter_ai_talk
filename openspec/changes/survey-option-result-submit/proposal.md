## Why

满意度每一项现在只能勾选或不勾选，Hub 上看不到用户觉得好用、不好用，还是没用过。评价中文由客户端拼在选项原文后面，提交时把拼好的结果字符串交给服务端保存。

## What Changes

- sheet 里每个选项从单个勾选改为三个互斥选择：未使用、不好用、好用。没点过的行不是「未使用」。
- 当前问卷有选项时，每一行都要选出评价才能提交；意见可以留空。选项列表为空时，仍允许只写意见。
- 提交前把该行 GET 到的选项原文与所选中文直接拼接，中间不加标点或空格，放进 `optionResults`。
- **BREAKING**：提交体改为 `campaignId`、`optionResults`、`comment`，不再发送 `optionIds`。
- 未评完、双空、意见超过 1000 个 Unicode 码位，以及 POST 失败，仍在提交按钮上方展示原因，不 toast，sheet 保持打开。改评价或改意见时清掉这行错误。
- 兄弟仓 `go_ai_talk` 变更 `survey-submit-option-results` 负责接收并校验这些字符串。本仓不改 GET 门闩、主壳弹出时机和日志 tag。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `home-satisfaction-survey`：选项展示从多选勾选改为每项三评；提交字段从 `optionIds` 改为 `optionResults`。

## Impact

- **sheet**：`app/lib/ui/home_satisfaction_survey_sheet.dart`。`TextEditingController` 仍由 sheet State 持有并释放。颜色仍用 `AppColor`。
- **提交**：`app/lib/data/satisfaction_survey_repository.dart` 的 POST body。
- **不变**：`GET /device/app/api/survey/current`、喂养缓存门闩、`UcgHomeShell` 弹出时机、`AppDebugLog.survey`。
- **后端**：须与 `survey-submit-option-results` 一起上线；旧包若仍传 `optionIds`，服务端不再据此写快照。
