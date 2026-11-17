## REMOVED Requirements

### Requirement: Recall seeds SHALL exist only for prediction and never as feeding history

**Reason**: 回忆种子栈整体删除，不再存在专用种子存储。  
**Migration**: 删除 `PredictionRecallSeed` store/provider；忽略或 remove prefs `prediction_recall_seeds_v1`。

### Requirement: Seed synthesis SHALL satisfy predictor sample gate from last time and interval

**Reason**: 不再合成种子发生点。  
**Migration**: 仅真喂养历史进入预测样本；不足时展示亲和进度。

### Requirement: Prediction pipeline SHALL merge seeds with real history in memory

**Reason**: 禁止种子旁路 merge。  
**Migration**: 预测输入仅统一历史池真记录。

### Requirement: Real history catching up SHALL discard that root seed immediately

**Reason**: 无种子可丢；清种子逻辑随 store 删除。  
**Migration**: 无。

## ADDED Requirements

### Requirement: Client MUST NOT keep a recall-seed store for prediction

The client MUST NOT maintain a dedicated prediction recall-seed persistence layer, MUST NOT synthesize pseudo occurrence points from user-supplied intervals for prediction, and MUST NOT merge such synthetics into prediction inputs. 客户端 MUST NOT 再维护回忆种子持久化层，MUST NOT 按用户间隔合成伪发生点用于预测，MUST NOT 将此类合成点合并进预测输入。

#### Scenario: 无种子 prefs 消费

- **WHEN** 设备上仍残留旧 `prediction_recall_seeds_v1` 数据
- **THEN** 预测管线 MUST NOT 读取该数据生成 nextAt
- **AND** 客户端 MUST 删除或永久忽略该 key（wipe/启动清理 MUST 可移除）
