## 1. 登录入口与交互调整

- [x] 1.1 更新 `LoginScreen`，移除胖宝号输入框、设备号登录按钮及相关文案，仅保留微信登录入口与隐私政策入口
- [x] 1.2 调整登录页状态处理：点击唯一微信入口时调用 `AuthRepository.signInWithWeChat()`，覆盖加载态、成功跳转与失败提示
- [x] 1.3 移除 Web 登录页中清空微信 OAuth 残留并提示“请使用胖宝号登录”的逻辑，确保回调结果可继续用于微信登录

## 2. 鉴权接口与兼容策略收口

- [x] 2.1 从 `AuthRepository` 及其实现中移除对外暴露的 `signInWithDeviceNo()` 登录能力，并清理仓库内对应调用点
- [x] 2.2 保持 `signInWithWeChat()` 登录成功后的 token 持久化、`deviceNo` 刷新与主页跳转链路不变
- [x] 2.3 保留 `SignInChannel.device` 的历史读取兼容，但确保新版本不再写入新的设备号登录渠道值

## 3. 微信回调与错误文案统一

- [x] 3.1 校正 `WeChatOAuthCallbackScreen` 与登录页之间的衔接，确保 Web 回调返回后能继续完成微信登录流程
- [x] 3.2 统一登录相关错误与说明文案，删除“请输入胖宝号”“默认使用胖宝号登录”“请使用胖宝号登录”等设备号导向提示
- [x] 3.3 保留 `WX_LOGIN_CODE` 仅作为开发联调兜底，不再作为用户可见主流程说明

## 4. 文档与验证

- [x] 4.1 更新 `app/README.md` 中的登录说明，明确当前仅支持微信登录，并标注设备号登录流程已移除
- [x] 4.2 检查与登录方式相关的 OpenSpec / 文档引用，确保不再把胖宝号登录描述为当前可用入口
- [x] 4.3 运行 `openspec status --change "wechat-only-login"` / 必要校验命令，确认该变更达到 apply-ready
