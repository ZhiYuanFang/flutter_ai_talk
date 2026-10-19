## 1. 契约与门闩

- [x] 1.1 增加 survey current / submit 的 API 客户端，对齐 `GET /device/app/api/survey/current` 与 `POST /device/app/api/survey/submit`（登录 Bearer，不在客户端比较有效期）
- [x] 1.2 门闩：已登录、deviceNo 非空，且内存历史或 `HomeHistoryStore` 快照有记录才允许请求；Web 无磁盘时只看内存

## 2. 主壳编排

- [x] 2.1 在 `runHomeShellDialogBootstrap` 完成 notify→version 之后执行问卷检查，由 `UcgHomeShell` 同一次挂载 single-flight 包住
- [x] 2.2 resume 与主壳已挂载期间的登录成功不得再次自动请求或弹 sheet；失败走 `AppDebugLog`，不弹错误、不循环重试；若新增 tag 则同步 `app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md`

## 3. Sheet

- [x] 3.1 `show=true` 时底部 sheet：说明、多选、更多意见；`TextEditingController` 由 sheet State 持有并在 dispose 释放；颜色经 `AppColor`
- [x] 3.2 零选项且意见非空才 POST；双空不请求；意见 trim 后超过 1000 个 Unicode 码位不请求，并在提交按钮上方展示原因，sheet 不关；输入框限制继续输入
- [x] 3.3 POST 成功才关闭 sheet，且本次挂载不再弹；POST 失败在提交按钮上方展示错误且不 toast，sheet 保持打开；改选项或改意见清掉该行；关闭 sheet 或失败不写本地已答标记
- [x] 3.4 只根据 `show=true` 弹 sheet；`show=false` 即使有 `campaignId` 也不弹；选项为空仍可只提交意见
- [x] 3.5 代码补中文业务注释；不新增 `*_test.dart`
