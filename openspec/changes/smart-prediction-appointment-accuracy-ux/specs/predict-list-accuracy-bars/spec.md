## ADDED Requirements

### Requirement: Accuracy chart pane SHALL dismiss summary on tap of the whole region

When the in-card chart region is in day-summary mode, a single tap anywhere on that chart region (including the title row, empty placeholder, and sample/detail lines) MUST clear summary mode and restore the accuracy bars, with the same outcome as tapping the leading back control. Bars-mode taps on empty chrome MUST continue to absorb the event so they do not trigger the card add path. 小结态整块图区单击 MUST 回柱图（等同返回箭头）；柱图空白单击 MUST 仍吸收、不触发加事件。

#### Scenario: Tap summary body returns to bars

- **WHEN** 用户处于某日预测小结且单击小结正文或空态占位
- **THEN** 客户端 MUST 退出小结并重新展示准确率柱图

### Requirement: Accuracy chart pane SHALL long-press toggle list and waterfall layout

The accuracy chart pane (bars or summary) MUST register an explicit long-press that invokes the same list↔waterfall (grid) layout toggle as the portrait prediction card long-press / AppBar control. The client MUST NOT rely solely on gesture bubbling through fl_chart for this behavior. 准确率图区 MUST 显式长按切换列表/瀑布布局。

#### Scenario: Long-press bars switches to waterfall

- **WHEN** 竖列表准确率柱图上长按且当前为列表布局
- **THEN** 客户端 MUST 切换到瀑布/紧凑布局（与整卡长按同一偏好）

### Requirement: Vertical list MUST omit appointment root cards

On the smart prediction **vertical list** (`compact=false`), the client MUST NOT render cards for catalog roots where `catalogRootIsAppointment` is true, including roots with no stored nextAt. Appointment CTAs such as「补充下次」MUST remain available on waterfall/compact appointment cards only. 竖列表 MUST NOT 展示预约根卡；「补充下次」MUST 仅保留在瀑布/compact。

#### Scenario: Appointment hidden from list

- **WHEN** 目录存在预约根且用户处于竖列表布局
- **THEN** 该根 MUST NOT 出现在竖列表，且 MUST NOT 展示其准确率或示例柱

#### Scenario: Waterfall still shows appointment

- **WHEN** 同一预约根在瀑布布局下
- **THEN** 卡 MUST 仍可展示（含「补充下次」或 countdown/改约，按既有热态规则）

## MODIFIED Requirements

### Requirement: Tapping an accuracy bar SHALL replace the in-card chart with that day’s prediction summary

When the user taps a day bar that has eligible samples, the client MUST replace the **same card’s chart region** with that day’s prediction summary (预计 vs 实际 per occurrence for that event root). The summary MUST NOT navigate to another route and MUST NOT be a modal/bottom sheet as the primary presentation. Tapping an empty day slot MUST NOT enter summary mode. The chart region MUST provide a leading back control **and** MUST treat a tap on the whole summary region as returning to the 7-day accuracy bars. 点有样本柱 MUST 在同卡图区替换为当日预测小结；MUST NOT 以跳转/弹层为主呈现；空日 MUST NOT 进入小结；MUST 提供返回控件且整区单击 MUST 可回柱图。

#### Scenario: Tap bar opens summary

- **WHEN** 用户点按有合格样本的准确率柱
- **THEN** 同卡图区 MUST 展示该日预测小结

#### Scenario: Back or region tap restores bars

- **WHEN** 用户点返回箭头或单击小结图区任意处
- **THEN** 图区 MUST 恢复近 7 日准确率柱图
