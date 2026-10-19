## Context

主壳 `UcgHomeShell` 在进入 `/home` 后用 `runHomeShellDialogBootstrap` 先弹 notify，再弹 version。喂养页是 `HomeScreen`，历史缓存在 `HomeHistoryStore`（按 deviceNo 的磁盘快照；Web 不写盘）和 `homeHistory` 内存列表。基线 `openspec/specs/v2.1.3.md` 要求 notify 先于 version，且 resume、挂载期间的登录成功不再自动弹 notify。

兄弟仓 `go_ai_talk` 变更 `device-satisfaction-survey` 提供：

- `GET /device/app/api/survey/current` → 是否展示、活动 id、说明、选项 `{id,text}`
- `POST /device/app/api/survey/submit` → `campaignId`、`optionIds`、`comment`

服务端已判断开关、上海时区有效期和是否已提交。客户端只加「有喂养缓存才请求」以及 sheet。

## Goals / Non-Goals

**Goals:**

- 冷启动主壳、notify 与 version 都结束后，对已登录且有喂养缓存的用户拉一次问卷。
- sheet 多选 + 更多意见；允许零选项提交；成功后本轮不再弹。
- 遵守弹层输入生命周期、主题色、副作用 HTTP 的 single-flight。

**Non-Goals:**

- 改 notify / version 的顺序、文案或「resume 不重弹」语义。
- 在喂养页 `HomeScreen` 单独拉问卷。
- 客户端自行比较有效期。
- 未登录游客问卷。
- 新增测试文件。
- 服务端实现。

## Decisions

### D1：接在主壳启动弹窗编排之后

- **选择**：扩展 `runHomeShellDialogBootstrap`（或由 `UcgHomeShell` 在其返回后立刻调用的同级函数），在 version 步骤结束且 `context.mounted` 后进入问卷。仍由主壳同一次挂载的 single-flight 包住，不挂到 resume，也不挂到主壳已在时的登录成功。
- **理由**：用户说的「主页顶壳」对应基线里的主壳 `UcgHomeShell`，启动弹窗已经集中在这里；放在 `HomeScreen` 会在预测页着陆时漏掉，也会和「不得依赖喂养页 mount」的启动编排分叉。
- **备选**：`HomeScreen.initState` → 默认页不是喂养页，拒绝。

### D2：喂养缓存门闩

- **选择**：已登录且当前 `deviceNo` 非空，并且满足其一才发 GET：`homeHistory` 当前列表非空，或 `HomeHistoryStore.loadSnapshot` 的 items 非空。两者都空则不请求。Web 无磁盘文件时只看内存列表。请求失败只打 `AppDebugLog`（若尚无合适 tag，按 project 三联新增，例如 `[Survey]`），不弹错误，不重试环。
- **理由**：与「有历史喂养数据缓存的用户」一致；空缓存用户不打扰。
- **备选**：无缓存也请求、靠服务端判断 → 服务端不查 history，且会打到没用过喂养的人，拒绝。

### D3：sheet 与提交

- **选择**：`show=false` 不弹（即使响应里带了 `campaignId`）。`show=true` 用底部 sheet：说明、多选选项、底部「更多意见」。选项列表为空仍展示，允许只写意见。`TextEditingController` 由 sheet State 创建并在 `dispose` 释放。颜色只用 `AppColor`。提交 body 为 `{ campaignId, optionIds, comment }`，id 为整数。意见输入 `maxLength` 为 1000；提交前 trim，再按 Unicode 码位计数，超过 1000 则在提交按钮上方展示文案且不发 POST，sheet 不关。零选项且意见非空允许提交。两者都空时不发 POST，同样在按钮上方提示需要选择或填写。POST 成功后才关闭 sheet，且本次挂载不再弹。POST 失败把服务端或网络错误写在按钮上方，不 toast，sheet 保持打开，不得在本地把活动记成已提交。改选项或改意见时清掉这行错误。用户主动关掉 sheet 不写本地「已答」标记，下次冷启动再走 GET。
- **理由**：是否已答的权威在服务端；本地标记会在清缓存或换端后和服务器不一致。关 sheet 再问是探索时定下的。
- **备选**：本地 prefs 记已关闭 → 会把「稍后」变成「永不再弹」，拒绝。

### D4：副作用 HTTP

- **选择**：同一次主壳挂载只发一次 GET（in-flight Future 合并）。失败不自动重试。不在 `ref.listen` 里循环触发。Provider `create` 不发这个请求。
- **理由**：对齐 `side-effect-http-governance` 与 notify 的「一次启动」语义。

## Risks / Trade-offs

- [冷启动时历史尚未 hydrate，门闩误判为空] → 先读磁盘快照再决定；内存已有记录则直接用。若两者皆空，本次不弹，下次冷启动再试。
- [用户停在 sheet 时活动被关掉] → POST 被拒时按钮上方展示错误且 sheet 仍开，不本地销卷；下次启动 GET 会得到不展示。
- [与 notify/version 叠在一起] → 严格排在两者之后，前一个未关闭不开始问卷。

## Migration Plan

- 可独立于后端先合并。GET 未部署时失败静默；用户已打开 sheet 后 POST 失败则在按钮上方展示错误且不关 sheet。后端开关默认关时用户无感。
- 回滚：去掉主壳编排调用即可。

## Open Questions

- （无）
