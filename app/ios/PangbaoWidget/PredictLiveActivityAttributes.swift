import ActivityKit
import Foundation

/// 与 Go `PUSH_LA_ATTR_TYPE` 默认名 `BabyLiveActivityAttributes` 对齐（统一单条列表态）。
struct BabyLiveActivityAttributes: ActivityAttributes {
  /// ContentState：phase + 有序 items（预测升序 + 进行中倒序，由 Go 排好）。
  /// 未知键（如历史 ack）由 Codable 忽略；UI 仅依赖 phase/items。
  public struct ContentState: Codable, Hashable {
    var phase: String
    var items: [BabyLiveActivityItem]

    init(phase: String = "", items: [BabyLiveActivityItem] = []) {
      self.phase = phase
      self.items = items
    }

    enum CodingKeys: String, CodingKey {
      case phase, items
    }

    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      // end/clear 可能只带 phase
      phase = try c.decodeIfPresent(String.self, forKey: .phase) ?? ""
      items = try c.decodeIfPresent([BabyLiveActivityItem].self, forKey: .items) ?? []
    }
  }

  /// 固定 Attributes；Push-to-Start / start 由 Go 下发。
  var activityId: String
  var deviceNo: String

  enum CodingKeys: String, CodingKey {
    case activityId, deviceNo
  }

  init(activityId: String = "", deviceNo: String = "") {
    self.activityId = activityId
    self.deviceNo = deviceNo
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    activityId = try c.decodeIfPresent(String.self, forKey: .activityId) ?? ""
    deviceNo = try c.decodeIfPresent(String.self, forKey: .deviceNo) ?? ""
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(activityId, forKey: .activityId)
    try c.encode(deviceNo, forKey: .deviceNo)
  }
}

/// 列表项：`kind=imminent|timing` + 各态展示字段；缺键兜底。
struct BabyLiveActivityItem: Codable, Hashable, Identifiable {
  var kind: String
  var eventId: Int64
  var title: String
  var nextAt: Int64
  var expectKind: String
  var expectDurationSec: Int64
  var expectAmount: Double
  var expectUnit: String
  var historyId: Int64
  var eventName: String
  var startTime: Int64
  var expectEndAt: Int64

  /// ForEach 稳定键：kind + 业务 id。
  var id: String {
    let k = kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if k == "timing" {
      return "timing:\(historyId):\(eventId):\(startTime)"
    }
    return "imminent:\(eventId):\(nextAt)"
  }

  var isImminent: Bool {
    kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "imminent"
  }

  var isTiming: Bool {
    kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "timing"
  }

  init(
    kind: String = "",
    eventId: Int64 = 0,
    title: String = "",
    nextAt: Int64 = 0,
    expectKind: String = "",
    expectDurationSec: Int64 = 0,
    expectAmount: Double = 0,
    expectUnit: String = "",
    historyId: Int64 = 0,
    eventName: String = "",
    startTime: Int64 = 0,
    expectEndAt: Int64 = 0
  ) {
    self.kind = kind
    self.eventId = eventId
    self.title = title
    self.nextAt = nextAt
    self.expectKind = expectKind
    self.expectDurationSec = expectDurationSec
    self.expectAmount = expectAmount
    self.expectUnit = expectUnit
    self.historyId = historyId
    self.eventName = eventName
    self.startTime = startTime
    self.expectEndAt = expectEndAt
  }

  enum CodingKeys: String, CodingKey {
    case kind, eventId, title, nextAt
    case expectKind, expectDurationSec, expectAmount, expectUnit
    case historyId, eventName, startTime, expectEndAt
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? ""
    eventId = try c.decodeIfPresent(Int64.self, forKey: .eventId) ?? 0
    title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    nextAt = try c.decodeIfPresent(Int64.self, forKey: .nextAt) ?? 0
    expectKind = try c.decodeIfPresent(String.self, forKey: .expectKind) ?? ""
    expectDurationSec = try c.decodeIfPresent(Int64.self, forKey: .expectDurationSec) ?? 0
    if let d = try c.decodeIfPresent(Double.self, forKey: .expectAmount) {
      expectAmount = d
    } else if let i = try c.decodeIfPresent(Int64.self, forKey: .expectAmount) {
      expectAmount = Double(i)
    } else {
      expectAmount = 0
    }
    expectUnit = try c.decodeIfPresent(String.self, forKey: .expectUnit) ?? ""
    historyId = try c.decodeIfPresent(Int64.self, forKey: .historyId) ?? 0
    eventName = try c.decodeIfPresent(String.self, forKey: .eventName) ?? ""
    startTime = try c.decodeIfPresent(Int64.self, forKey: .startTime) ?? 0
    expectEndAt = try c.decodeIfPresent(Int64.self, forKey: .expectEndAt) ?? 0
  }
}
