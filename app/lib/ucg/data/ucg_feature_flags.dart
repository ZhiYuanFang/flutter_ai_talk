/// UCG / 产品表面编译期功能开关。
///
/// 宝藏入口：首版临时关闭，下版上线时改回 `true`。
const kUcgTreasureEnabled = false;

/// 主壳 PageView 是否含 UCG 广场页。
/// 商业化重开（commercial-ucg-feature-unlock）：三页主壳喂养 | 预测 | UCG。
const kUcgHomePagerEnabled = true;

/// 历史编辑「同步广场」开关与 UCG 发帖/改帖/删帖副作用。
/// 商业化重开：与 UCG 表面一并恢复。
const kHistorySquareSyncEnabled = true;

/// VIP 购买页与开通 CTA 是否可达。
/// 商业化重开：月卡与开通中心支付入口可达。
const kVipPurchaseEnabled = true;

/// 预测页竖屏语音对话（贴边球 / 会话 activate）。
/// 对话模型未训练完成：默认关闭；翻 `true` 恢复竖屏入口。横屏语音不受本开关影响。
const kPredictionPortraitVoiceEnabled = false;
