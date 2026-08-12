## Context

身份展示拆成两路：`deviceNoNotifierProvider` 判定「是否绑定」；`settingsBabyProvider` → `loadBaby()` 提供画像。`babyDisplayProvider` 在已登录且 `deviceNo` 非空时走 `BabyDisplay.resolve(profile)`。冷启动允许主页先展示再灌 `deviceNo`（见基线 Splash/bootstrap），因此 `settingsBabyProvider` 可能在 `deviceNo` 仍空时完成首次 Future，缓存 `id:''` /「未绑定宝宝ID」占位。之后 `deviceNo` 到位、历史正常，但 FutureProvider 不重跑；`GatewayBootstrapGate` 再 `loadBaby` 只写 `babySexProvider`，顶栏变成「宝宝 · 不满1个月啦」，设置中心仍因 `baby.id.isEmpty` 显示绑定 CTA。

## Goals / Non-Goals

**Goals:**

- `deviceNo` 可用后，展示用宝宝画像 MUST 与真实绑定一致。
- 设置中心与顶栏在绑定就绪后不再长期呈现「未绑定 / 默认空态月龄」撕裂。
- 已绑定但画像尚未有效时，顶栏不得用占位昵称冒充已绑合成行。

**Non-Goals:**

- 不改绑定/登录 API、不改 `user/get` 契约字段。
- 不重做 L1 `displayBaby*` 字面量规则（除中间态路由决策）。
- 不新增自动化测试文件。
- 不解决服务端返回空 `babyName`/无效生日的数据质量问题（仅避免客户端竞态误显）。

## Decisions

1. **`settingsBabyProvider` 订阅 `deviceNo`**  
   `ref.watch(deviceNoNotifierProvider)`（或等价：对规范化 deviceNo 字符串建依赖）。deviceNo 标识变化时 Future 重建并重新 `loadBaby()`。  
   *备选*：仅在 `GatewayBootstrapGate` invalidate — 覆盖冷启动，但漏掉绑定成功后仅 `setLocal`、切号等路径；订阅更稳。

2. **Bootstrap 成功后同步展示 Provider**  
   `GatewayBootstrapGate._run` 在 `loadBaby` 成功后 `invalidate(settingsBabyProvider)`（或写入与 Provider 同源的缓存入口），保证与 gate 单飞拉取一致。与 Decision 1 叠加：幂等、可接受短暂二次加载。

3. **中间态 chrome（已登录 + deviceNo 非空 + 画像仍为空 id / 占位昵称）**  
   `babyDisplayProvider` MUST NOT 对占位画像调用「已绑定 L1 resolve」冒充真实宝宝。优先：`showAge: false` 且昵称用「加载中」或短暂沿用「未绑定宝宝」直至有效 `id`；实现选短文案「宝宝」（不带虚假月龄）亦可，但 **MUST NOT** 展示「不满1个月啦」。推荐：`authChrome` 风格隐藏月龄，昵称可用「宝宝」或保持上一有效快照（若有）。本设计拍板：**隐藏月龄**；昵称在占位未就绪时用「宝宝」但不拼月龄（`showAge: false`），设置中心仍以 `id.isEmpty` 显示绑定 CTA 仅当 `deviceNo` 也空——当 `deviceNo` 非空且画像空 id 时，设置可短暂 loading / 重拉，避免假「去绑定」。  
   *设置中心*：`deviceNo` 非空且 `settingsBaby` loading 或占位 → 显示加载或只读占位，**不得**在 deviceNo 已有时把用户推进「绑定宝宝」主路径（可改为「正在同步宝宝信息…」）。

4. **空 deviceNo 的 `loadBaby` 占位保留**  
   Repository 在无 deviceNo 时仍可返回占位 Profile（兼容现调用方），但 Provider 层不得在 deviceNo 已有后继续把该占位当终态。

## Risks / Trade-offs

- **[Risk] deviceNo watch 导致 settingsBaby 多次 HTTP `user/get`** → Mitigation：仅在规范化 deviceNo 字符串变化时重建；bootstrap invalidate 与 watch 可能双发，可接受（单飞或短时重复）。
- **[Risk] 中间态文案闪烁** → Mitigation：隐藏月龄；尽快 invalidate 后以真实画像替换。
- **[Risk] 设置「绑定」入口在真未绑定时被误藏** → Mitigation：仅当 `deviceNo.isEmpty` 时展示绑定 CTA；deviceNo 有而画像失败则错误/重试，不伪装成未绑定。

## Migration Plan

1. 合入后冷启动已绑定账号即可自愈，无需清缓存。
2. 回滚：恢复 `settingsBabyProvider` 无 watch 与 gate 不 invalidate 即可。

## Open Questions

（无）竞态修复与中间态隐藏月龄已写死。
