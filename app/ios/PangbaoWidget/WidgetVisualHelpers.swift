import Foundation
import SwiftUI
import UIKit

/// 桌面小组件与 Live Activity 共用的 App Group / 色 / logo 工具。
enum WidgetVisualHelpers {
  static let appGroupId = "group.com.fzy.pangbao.widget"
  static let laEventVisualsKey = "laEventVisuals"
  static let defaultColorHex = "#5BA3E8"

  /// 解析 `#RRGGBB` / `#AARRGGBB` 为 Color。
  static func parseColor(_ raw: String?) -> Color {
    var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? defaultColorHex
    if s.hasPrefix("#") { s.removeFirst() }
    if s.count == 8 { s = String(s.suffix(6)) }
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    return Color(
      red: Double((rgb >> 16) & 0xFF) / 255,
      green: Double((rgb >> 8) & 0xFF) / 255,
      blue: Double(rgb & 0xFF) / 255
    )
  }

  /// LA 深色底：过深则向白提亮，保证可读。
  static func laAccentColor(_ raw: String?) -> Color {
    let base = parseColor(raw)
    let (r, g, b) = rgbTuple(raw)
    // 相对亮度（sRGB 近似）
    let luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if luma >= 0.45 { return base }
    let t = (0.55 - luma) / 0.55
    let mix = min(1, max(0.35, t * 0.75 + 0.25))
    return Color(
      red: r + (1 - r) * mix,
      green: g + (1 - g) * mix,
      blue: b + (1 - b) * mix
    )
  }

  /// 从 App Group 索引取某 eventId 的色、logo 相对路径与可选本地事件名。
  static func visual(forEventId eventId: Int64) -> (color: String?, logoFile: String?, name: String?) {
    guard eventId != 0 else { return (nil, nil, nil) }
    let key = String(eventId)
    guard let defaults = UserDefaults(suiteName: appGroupId),
          let json = defaults.string(forKey: laEventVisualsKey),
          let data = json.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let entry = root[key] as? [String: Any]
    else {
      return (nil, nil, nil)
    }
    let color = entry["color"] as? String
    let logo = entry["logoFile"] as? String
    // 缺 name 键视为空，兼容旧 JSON
    let rawName = entry["name"] as? String
    let name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedName = (name?.isEmpty == false) ? name : nil
    return (color, logo, trimmedName)
  }

  static func loadLogoImage(path: String?) -> UIImage? {
    guard let path, !path.isEmpty else { return nil }
    let fileURL: URL
    if path.hasPrefix("/") {
      fileURL = URL(fileURLWithPath: path)
    } else if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId
    ) {
      fileURL = container.appendingPathComponent(path)
    } else {
      return nil
    }
    guard FileManager.default.fileExists(atPath: fileURL.path),
          let data = try? Data(contentsOf: fileURL),
          let image = UIImage(data: data) else { return nil }
    return image
  }

  @ViewBuilder
  static func eventLogo(path: String?, color: String?, size: CGFloat) -> some View {
    if let uiImage = loadLogoImage(path: path) {
      Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    } else if path == nil && color == nil {
      // LA 无索引时用品牌标
      Image("BrandLogo")
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    } else {
      eventOrb(color: color, size: size)
    }
  }

  static func eventOrb(color: String?, size: CGFloat) -> some View {
    let tint = parseColor(color ?? defaultColorHex)
    return Circle()
      .fill(tint.opacity(0.25))
      .frame(width: size, height: size)
      .overlay(
        Circle()
          .fill(tint)
          .frame(width: size * 0.55, height: size * 0.55)
      )
  }

  // MARK: - private

  private static func rgbTuple(_ raw: String?) -> (Double, Double, Double) {
    var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? defaultColorHex
    if s.hasPrefix("#") { s.removeFirst() }
    if s.count == 8 { s = String(s.suffix(6)) }
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    return (
      Double((rgb >> 16) & 0xFF) / 255,
      Double((rgb >> 8) & 0xFF) / 255,
      Double(rgb & 0xFF) / 255
    )
  }
}
