## 1. 付款前硬件免责确认

- [x] 1.1 在 `xiaozhi_speaker_screen.dart` 的 `_purchasePermanent` 入口调用 `showGlassConfirmDialog`（title/message/confirmLabel 按 design D3）；取消则 return，确认后再置 `_paying` 并走既有 purchase
- [x] 1.2 确认主 CTA 与「体验已用完 → 永久开通」两条路径均经该闸门；取消时无建单、无支付调起

## 2. 验收

- [ ] 2.1 真机：可售态点「永久开通」→ 见确认 → 取消不进支付；确认后仍可走支付宝/IAP
- [ ] 2.2 （可选）体验用尽路径：引导开通后再见同一硬件确认
