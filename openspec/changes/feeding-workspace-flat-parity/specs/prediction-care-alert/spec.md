## ADDED Requirements

### Requirement: Feeding workspace AI智能分析 control SHALL live in the AppBar

When care-alert is effectively unlocked (or VIP-covered) and feeding eligibility is qualified on the feeding workspace, and a daily request is not in flight, the 「AI智能分析」 control MUST be shown in the AppBar actions area (not inside a glass content card). While the daily request is in flight, the workspace MUST continue to show transitional body copy 「正在思考中」 and MUST NOT allow a concurrent second daily request from that control. Visibility and toast / retry semantics of the existing manual-refresh requirement remain in force; this requirement only relocates the control chrome. 喂养工作台在合格已开通且非请求中时，「AI智能分析」**必须** 位于 AppBar；请求中 body「正在思考中」与防并发 / Toast 语义保持既有约定。

#### Scenario: Unlocked qualified shows AppBar CTA

- **WHEN** feeding eligibility is qualified and care-alert is effectively unlocked and daily is not loading
- **THEN** the client MUST show 「AI智能分析」 in the AppBar actions
- **AND** MUST NOT place that primary control inside a glass content card

#### Scenario: Loading keeps thinking in body

- **WHEN** a manual daily refresh is in flight
- **THEN** the workspace body MUST show 「正在思考中」
- **AND** the client MUST NOT start a second concurrent daily request from the analyze control
