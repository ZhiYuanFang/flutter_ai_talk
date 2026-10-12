## MODIFIED Requirements

### Requirement: Portrait voice activate MUST follow shell route currency

For portrait prediction voice, the client MUST treat session `want` as true only when the home shell remains the effective page surface (home shell `PageRoute` is not covered by another `PageRoute`), portrait orientation applies, `kPredictionPortraitVoiceEnabled` is true, platform is non-web Android/iOS, and other existing surface gates (e.g. unqualified UCG page) still pass. The client MUST NOT require the prediction PageView page to be visible for portrait activate.

The client MUST NOT deactivate portrait voice solely because a same-navigator **Overlay** modal (`PopupRoute` / `ModalBottomSheetRoute` / glass dialog via `showDialog` or equivalent) makes `ModalRoute.isCurrent` false on the home shell. Opening or dismissing feeding event catalog sheets, event record sheets, or in-shell glass confirms MUST NOT call `LandscapeVoiceController.deactivate` / `_tearDown` (including `wake.stop` that frees `KeywordSpotter` and chat `endSession(reason: teardown)`) and MUST NOT force a full KWS cold start (`KeywordSpotter` reconstruct / native encoder init) on dismiss.

When the user pushes a covering **`PageRoute`** over the home shell (settings, login, or other full page), the client MUST deactivate portrait voice. 竖屏会话 activate **必须** 以主壳 Page 级表面为准，**不得** 再要求预测页可见；**不得** 仅因 Overlay Modal 翻转 `isCurrent` 而 teardown / 全量重载 KWS；推入覆盖性 **PageRoute** 时 MUST deactivate。

#### Scenario: 切到喂养仍保持会话资格

- **WHEN** 竖屏 flag 开启且用户从预测滑到喂养（主壳仍为当前 Page，无其它 PageRoute 覆盖）
- **THEN** 客户端 MUST 保持或重新满足竖屏 `activate` 条件（不得因离开预测页而强制长期 deactivate）

#### Scenario: 推入设置后 deactivate

- **WHEN** 用户从主壳推入设置（或其它覆盖主壳的 **PageRoute**）
- **THEN** 客户端 MUST deactivate 竖屏预测语音会话

#### Scenario: 打开喂养 Overlay sheet 不得 teardown

- **WHEN** 竖屏预测语音已 activate，且用户打开喂养事件选择 / 记录 `showModalBottomSheet`（或等价 Overlay）
- **THEN** 客户端 MUST NOT 仅因此调用 `deactivate` / `_tearDown`
- **AND** MUST NOT 仅因此打印成对的 `endSession reason=teardown` 并释放 KeywordSpotter

#### Scenario: 关闭 Overlay 不得冷启动 KWS

- **WHEN** 用户关闭上述 Overlay（点外部、点 ✕ 或完成选择返回）
- **THEN** 客户端 MUST NOT 因关闭而再次 `activate` 触发的全量 `KeywordSpotter` 重建（native InitEncoder 冷路径）
- **AND** 若会话在打开 Overlay 前已 active，关闭后 MUST 保持会话热态（无需整模重载）

## ADDED Requirements

### Requirement: Portrait voice Overlay dismiss MUST NOT hitch from KWS reload

When portrait prediction voice is enabled and active on the home shell, dismissing an in-shell Overlay used for feeding event add/edit (catalog picker or record sheet) MUST NOT block the UI isolate with sherpa-onnx KeywordSpotter reconstruction. The client SHALL keep KWS warm across such Overlay open/close cycles. 竖屏已激活时，关闭喂养 Overlay **必须不得** 因 KWS 全量重建卡住 UI isolate；开闭 Overlay 周期内 KWS **应当** 保持热态。

#### Scenario: 关 sheet 无 InitEncoder 冷启动

- **WHEN** 竖屏语音已就绪，用户打开再关闭喂养玻璃 sheet
- **THEN** 正常路径 MUST NOT 在关闭瞬间出现因新建 KeywordSpotter 导致的主线程卡顿（logcat 不得出现与本次关闭成对的 InitEncoder 冷启动）
- **AND** sheet 关闭动画 MUST 可在不被 KWS 重载阻塞的情况下进行
