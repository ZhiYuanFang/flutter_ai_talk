/// UCG / 产品表面编译期功能开关。
///
/// 宝藏入口：首版临时关闭，下版上线时改回 `true`。
const kUcgTreasureEnabled = false;

/// 主壳 PageView 是否含 UCG 广场页。
/// 商业化重开（commercial-ucg-feature-unlock）：三页主壳喂养 | 预测 | UCG。
const kUcgHomePagerEnabled = true;

/// 历史编辑「同步广场」开关与 UCG 发帖/改帖/删帖副作用。
const kHistorySquareSyncEnabled = false;

/// VIP 购买页与开通 CTA 是否可达。
/// 商业化重开：VIP 与开通中心支付入口可达。
const kVipPurchaseEnabled = true;

/// 预测页竖屏语音对话（贴边球 / 会话 activate）。
/// 默认开启；翻 `false` 可紧急关闭竖屏入口（不影响横屏）。
/// 横屏助手由 [kPredictionLandscapeVoiceEnabled] 单独控制。
const kPredictionPortraitVoiceEnabled = true;

/// 预测页横屏语音助手（KWS 唤醒 / 监听 chip / chat / 字幕）。
/// 默认开启；翻 `false` 可紧急关闭横屏入口（不影响竖屏）。
const kPredictionLandscapeVoiceEnabled = true;
