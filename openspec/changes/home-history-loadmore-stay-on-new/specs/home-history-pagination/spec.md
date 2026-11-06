## MODIFIED Requirements

### Requirement: 较旧方向加载更多

The client SHALL load additional history pages when the user refreshes or scrolls toward the **older** end of the home history list (top of scroll content when newest is anchored at bottom), and SHALL merge older records into the displayed ascending list. After a successful load-more merge, the viewport SHALL remain toward the older end so the newly prepended records stay visible; the client MUST NOT apply a post-merge scroll compensation that snaps the viewport back to the pre-load-more anchor (e.g. `jumpTo(savedPixels + ΔmaxScrollExtent)`). 当用户在历史区向**更旧**方向交互（列表顶部/下拉刷新触顶）且服务端仍有更早数据时，客户端 MUST 请求 **`page+1`**，并将返回记录按升序 **prepend** 到当前列表（按 `id` 去重）；MUST NOT 丢弃已展示条目。加载更多成功后，视口 MUST 留在更旧端以继续展示刚合并的记录；MUST NOT 在合并后再把滚动位置补偿拽回加载前的锚点（禁止「先露出新页、再跳回原位」的双跳）。

#### Scenario: 仍有更多时加载下一页并留在新页

- **WHEN** 已加载条数少于服务端 `total` 且用户在下拉刷新时列表已处于顶部（或等价触顶条件），且下一页合并成功
- **THEN** 客户端 MUST 请求下一页并合并更旧记录，且视口 MUST 留在更旧端使新合并记录可见，MUST NOT 再执行将视口弹回加载前位置的滚动补偿

#### Scenario: 无更多数据

- **WHEN** `page * pageSize >= total` 或等价 `hasMore == false`
- **THEN** 客户端 MUST NOT 再发起加载更多请求；下拉 MAY 回退为刷新第 1 页

#### Scenario: 加载失败

- **WHEN** 加载更多 HTTP 失败
- **THEN** 已展示列表 MUST 保持不变；MAY 展示轻量错误提示
