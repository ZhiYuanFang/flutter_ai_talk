## 1. 依赖与配置面

- [x] 1.1 在 `pubspec.yaml` 增加微信相关依赖（推荐 `fluwx` 或经评审的替代方案），执行 `flutter pub get` 并记录最低 Flutter 版本要求
- [x] 1.2 在 `AppEnv`（或等价）增加 `WECHAT_APP_ID` 等 `dart-define`，默认值留空；更新 `README` 说明开放平台前置条件与**禁止**提交 AppSecret
- [x] 1.3 Android：按插件文档配置 `AndroidManifest.xml`、WXEntryActivity（或插件要求）、包名与签名与开放平台一致

## 2. 取码抽象与仓库衔接

- [x] 2.1 定义 `WeChatAuthClient`（或等价）接口及 `obtainWxCode()`，支持取消/超时错误类型
- [x] 2.2 实现 Android/iOS 具体类：注册微信 API、发起 scope 授权、在回调中解析 `code`
- [x] 2.3 调整 `RemoteAuthRepository`：`wxCode` 优先来自 `obtainWxCode()`，仅在未配置 SDK 且存在 `WX_LOGIN_CODE` 时回退（联调）
- [x] 2.4 `Riverpod` 注册：按平台选择 `WeChatAuthClient` 实现，并向 `AuthRepository` / 登录流程注入

## 3. Web 网页授权

- [x] 3.1 增加授权回调路由（如 `/auth/wechat/callback`），从 query 读取 `code`/`state`，校验后与登录页或全局状态衔接
- [x] 3.2 实现发起授权 URL 跳转（`window.location` 或 `url_launcher`），`redirect_uri` 与开放平台登记一致
- [x] 3.3 处理错误码（用户拒绝、state 不匹配等）并 Toast

## 4. UI 与体验

- [x] 4.1 更新 `LoginScreen`：点击后走取码 → 网关登录；加载态、成功/失败与取消提示
- [x] 4.2 移除或弱化「仅 WX_LOGIN_CODE」的误导性文案；保留联调说明于 README
- [x] 4.3 在 Android/iOS 真机各完成一次完整登录冒烟；Web 在 HTTPS 测试域完成一次（若环境具备）

## 5. 收尾

- [x] 5.1 `flutter analyze` 无新增 error；必要时补充 `openspec validate` 通过
- [x] 5.2 若适用，在 `openspec/changes/pangbao-app` 的 `auth-wechat-privacy` 中追加引用说明（可选，避免重复需求）
