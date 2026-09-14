# Growth Trajectory Predict — Cross-end Contract

冻结于 change `growth-trajectory-predict`。Flutter 只调 Go；Go 调 Python。

## Constants

| Key | Value |
|-----|--------|
| `featureId` | `growth_trajectory_predict` |
| `productCode` (seed) | `feat_growth_traj_30d` |
| `priceFen` | `1900` |
| `paymentDurationDays` | `30` |
| `inviteDurationDays` | `7` |
| `horizonDays` | `7` |
| `dailyLimitDefault` | `5` |
| `maxStructuredRounds` | `6` |
| `errorCodeDailyLimit` | `GROWTH_TRAJECTORY_DAILY_LIMIT` |

## Round rules

- `confirm_prior`: **not** counted in 6
- `ask` / `reconfirm`: **counted** in `structured_round` (max 6)
- After 6 still insufficient: one `final_free_text`, then `generate`
- Daily limit increments only after successful `result` persist

## Go ← Flutter

### `GET /device/api/growth-trajectory/latest?deviceNo=`

Response `data`:

```json
{
  "resultMarkdown": "string|null",
  "updatedAt": 0,
  "sessionId": "",
  "usedToday": 0,
  "dailyLimit": 5
}
```

`usedToday` / `dailyLimit`：账号（wxId）上海日用量与上限（默认 5）。

### `POST /device/api/growth-trajectory/turn` (SSE)

Request:

```json
{
  "deviceNo": "...",
  "action": "start|answer|restart",
  "sessionId": "optional on start; required on answer",
  "answer": {
    "questionId": "...",
    "value": "..."
  }
}
```

SSE events (`event:` + `data:` JSON; end with `data: [DONE]`):

| event | data |
|-------|------|
| `thinking` | `{"content":"..."}`  (may include orchestration `\r`) |
| `question` | `{"id","prompt","format":"choice\|free_text","choices":["a","b"],"sessionId"}` — choice MUST have exactly 2 choices |
| `result` | `{"markdown":"...","sessionId","usedToday","dailyLimit"}` |
| `error` | `{"code":"...","message":"..."}` |
| `done` | `{}` |

Pre-stream business errors (auth / access / daily limit) use normal JSON envelope so Flutter can Toast `message`.

## Go → Python

### `POST /v1/growth-trajectory/turn` (SSE)

Request:

```json
{
  "device_no": "...",
  "session_id": "...",
  "action": "start|answer|restart",
  "answer": {"question_id":"...","value":"..."},
  "prior_feedback": [],
  "horizon_days": 7,
  "model": {}
}
```

Same SSE event types as above (`thinking` / `question` / `result` / `error` / `done`).
