import ActivityKit
import Foundation

/// 与 Go `PUSH_LA_ATTR_IMMINENT` 默认名 `PredictImminentAttributes` 对齐。
struct PredictImminentAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var phase: String
    var nextAt: Int64

    init(title: String = "", phase: String = "", nextAt: Int64 = 0) {
      self.title = title
      self.phase = phase
      self.nextAt = nextAt
    }

    enum CodingKeys: String, CodingKey {
      case title, phase, nextAt
    }

    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      // end/clear 载荷可能只带 phase，缺省兜底避免解码失败
      title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
      phase = try c.decodeIfPresent(String.self, forKey: .phase) ?? ""
      nextAt = try c.decodeIfPresent(Int64.self, forKey: .nextAt) ?? 0
    }
  }

  var activityId: String
  var deviceNo: String
  var eventId: Int64
  var nextAt: Int64
}

/// 与 Go `PUSH_LA_ATTR_TIMING` 默认名 `PredictTimingAttributes` 对齐。
struct PredictTimingAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var eventName: String
    var startTime: Int64
    var phase: String

    init(eventName: String = "", startTime: Int64 = 0, phase: String = "") {
      self.eventName = eventName
      self.startTime = startTime
      self.phase = phase
    }

    enum CodingKeys: String, CodingKey {
      case eventName, startTime, phase
    }

    init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      eventName = try c.decodeIfPresent(String.self, forKey: .eventName) ?? ""
      startTime = try c.decodeIfPresent(Int64.self, forKey: .startTime) ?? 0
      phase = try c.decodeIfPresent(String.self, forKey: .phase) ?? ""
    }
  }

  var activityId: String
  var deviceNo: String
  var historyId: Int64
  /// 事件目录 id；旧推送可能缺省，解码兜底 0（UI 走无图）。
  var eventId: Int64

  enum CodingKeys: String, CodingKey {
    case activityId, deviceNo, historyId, eventId
  }

  init(activityId: String, deviceNo: String, historyId: Int64, eventId: Int64 = 0) {
    self.activityId = activityId
    self.deviceNo = deviceNo
    self.historyId = historyId
    self.eventId = eventId
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    activityId = try c.decodeIfPresent(String.self, forKey: .activityId) ?? ""
    deviceNo = try c.decodeIfPresent(String.self, forKey: .deviceNo) ?? ""
    historyId = try c.decodeIfPresent(Int64.self, forKey: .historyId) ?? 0
    eventId = try c.decodeIfPresent(Int64.self, forKey: .eventId) ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(activityId, forKey: .activityId)
    try c.encode(deviceNo, forKey: .deviceNo)
    try c.encode(historyId, forKey: .historyId)
    try c.encode(eventId, forKey: .eventId)
  }
}
