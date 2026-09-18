## 1. 去掉本地日键展示过滤

- [x] 1.1 在 `predictionCareAlertProvider` 删除「`dayKey` ≠ 今日上海日键则返回空列表」逻辑；保留 `ready` / `loading` / `failed` 门闩
- [x] 1.2 确认推演关闭 id 过滤（若有）仍按原样工作；`day`/`dayKey` 仅作元数据不参与可见性
- [x] 1.3 grep 确认无其它路径依赖「跨日变空」行为

## 2. 验收

- [ ] 2.1 手工：喂养页点「AI智能分析」，思考流结束后同一会话立即出现结果列表（无需退出重进）
- [ ] 2.2 手工：退出再进仍可 hydrate 展示 latest（回归）
