## 1. 画像加载与 deviceNo 同步

- [x] 1.1 `settingsBabyProvider` watch 规范化 `deviceNo`（空/非空/A→B），变化时重建并 `loadBaby`
- [x] 1.2 `GatewayBootstrapGate` 成功 `loadBaby` 后 `invalidate(settingsBabyProvider)`（或等价覆写），不只写 `babySexProvider`

## 2. 中间态展示

- [x] 2.1 `babyDisplayProvider`：已登录 + deviceNo 非空 + 画像仍为空 id /「未绑定宝宝ID」时隐藏月龄（不得「宝宝 · 不满1个月啦」）
- [x] 2.2 设置中心：deviceNo 非空且画像 loading/占位时展示同步中（或错误重试），不得走与无 deviceNo 相同的「去绑定」主 CTA

## 3. 校验

- [x] 3.1 `openspec validate baby-profile-deviceno-race --strict`
- [ ] 3.2 手工：已绑定账号冷启动 → 设置见真实宝宝卡、顶栏真实昵称/月龄；真未绑定仍可进绑定页
