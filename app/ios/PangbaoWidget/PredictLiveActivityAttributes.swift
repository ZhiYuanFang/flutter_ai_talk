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
}
