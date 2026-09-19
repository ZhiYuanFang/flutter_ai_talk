## 1. 喂养分析进行中状态

- [x] 1.1 `hydrateLatestOnly`：`_inFlight != null` 时直接返回，不覆盖 `loading` / `thinking` / `items`
- [x] 1.2 `refreshDailyManual`：`_inFlight != null` 时立刻返回「上一次分析还在进行，请稍后再试」，不 await 旧 Future，不进入生成实现
- [x] 1.3 喂养工作台：`loading` 时「AI智能分析」仍可点，并把上述返回文案走现有 Toast

## 2. 等待说明

- [x] 2.1 喂养页：`loading` 时在 `AiThinkingPane` 外展示「正在为宝宝做针对性分析，思考会比较久。你可以先去做别的，过一会儿回来看结果。」；不写入思考流文本
- [x] 2.2 成长页：仅流式思考阶段展示同一句；`asking`、空闲、加载历史、已有结果时不展示

## 3. 验收

- [ ] 3.1 手工：喂养点分析后退出再进，仍为思考中加等待说明，再点 Toast 且不发第二次生成；无进行中时进页仍显示历史
- [ ] 3.2 手工：成长流式思考可见同一说明；出题后说明消失
- [x] 3.3 确认未新建 `**/test/**`；不改 `app/android/**`、Go、Python
