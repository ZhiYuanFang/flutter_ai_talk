import SwiftUI
import UIKit
import WidgetKit

private let appGroupId = "group.com.fzy.pangbao.widget"
private let payloadKey = "widgetPayload"

struct PangbaoWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?
}

struct WidgetPayload: Decodable {
    let state: String
    let message: String?
    let header: WidgetHeader?
    let visual: WidgetVisual?
    let hero: WidgetRow?
    let recentLast: [WidgetRow]
    let tip: WidgetTip?

    enum CodingKeys: String, CodingKey {
        case state, message, header, visual, hero, recentLast, tip
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? "empty"
        message = try c.decodeIfPresent(String.self, forKey: .message)
        header = try c.decodeIfPresent(WidgetHeader.self, forKey: .header)
        visual = try c.decodeIfPresent(WidgetVisual.self, forKey: .visual)
        hero = try c.decodeIfPresent(WidgetRow.self, forKey: .hero)
        recentLast = try c.decodeIfPresent([WidgetRow].self, forKey: .recentLast) ?? []
        tip = try c.decodeIfPresent(WidgetTip.self, forKey: .tip)
    }
}

struct WidgetVisual: Decodable {
    let shellGradientStart: String?
    let shellGradientEnd: String?
    let shellOpacity: Double?
    let textPrimary: String?
    let textSecondary: String?
}

struct WidgetHeader: Decodable {
    let nickname: String?
    let birthDate: String?
    let displayLine: String?
}

struct WidgetTip: Decodable {
    let text: String?
}

struct WidgetRow: Decodable {
    let kind: String
    let name: String
    let startAt: String?
    let nextAt: String?
    let lastAt: String?
    let status: String?
    let color: String?
    let logoFile: String?
}

struct PangbaoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PangbaoWidgetEntry {
        PangbaoWidgetEntry(date: Date(), payload: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PangbaoWidgetEntry) -> Void) {
        completion(PangbaoWidgetEntry(date: Date(), payload: loadPayload()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PangbaoWidgetEntry>) -> Void) {
        let entry = PangbaoWidgetEntry(date: Date(), payload: loadPayload())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadPayload() -> WidgetPayload? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let raw = defaults.string(forKey: payloadKey),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }
}

struct ShellGradientView: View {
    let visual: WidgetVisual?

    var body: some View {
        LinearGradient(
            colors: [
                parseColor(visual?.shellGradientStart ?? "#B8DFF2")
                    .opacity(visual?.shellOpacity ?? 0.7),
                parseColor(visual?.shellGradientEnd ?? "#E8F4FC")
                    .opacity(visual?.shellOpacity ?? 0.7),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }
}

struct WidgetShellBackgroundModifier: ViewModifier {
    let visual: WidgetVisual?

    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                ShellGradientView(visual: visual)
            }
        } else {
            ZStack {
                ShellGradientView(visual: visual)
                content
            }
        }
    }
}

struct PangbaoWidgetEntryView: View {
    var entry: PangbaoWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    private var visual: WidgetVisual? { entry.payload?.visual }

    private var textPrimary: Color {
        parseColor(visual?.textPrimary ?? "#3D454C")
    }

    private var textSecondary: Color {
        parseColor(visual?.textSecondary ?? "#7A8690")
    }

    private var headerFontSize: CGFloat {
        family == .systemLarge ? 14 : (family == .systemMedium ? 14 : 12)
    }

    private var brandLogoSize: CGFloat {
        family == .systemLarge ? 24 : 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 占位10高度
            Spacer(minLength: 3)
            headerRow
            contentBody
        }
        .padding(family == .systemLarge ? 12 : (family == .systemMedium ? 8 : 10))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(WidgetShellBackgroundModifier(visual: visual))
        .widgetURL(URL(string: "pangbao://home"))
    }

    @ViewBuilder
    private var headerRow: some View {
        if let header = entry.payload?.header, entry.payload?.state != "empty" {
            HStack(alignment: .center, spacing: 6) {
                Text(formatHeader(header))
                    .font(.system(size: headerFontSize, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                brandLogo(size: brandLogoSize)
            }
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        if entry.payload?.state == "loading" || entry.payload?.state == "empty" {
            Spacer(minLength: 0)
            Text(entry.payload?.message ?? "打开胖宝记录")
                .font(.system(size: 13))
                .foregroundColor(textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 0)
        } else if family == .systemSmall {
            smallBody
        } else if family == .systemMedium {
            mediumBody
        } else {
            largeBody
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var smallBody: some View {
        if let hero = entry.payload?.hero {
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                sectionTitle("预测即将发生", size: 10, centered: true)
                eventLogo(path: hero.logoFile, color: hero.color, size: 50)
                Text(hero.name)
                    .font(.system(size: 14))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)
                Text(predictSubtitle(for: hero, semibold: true))
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        } else {
            fallbackMessage
        }
    }

    @ViewBuilder
    private var mediumBody: some View {
        let items = entry.payload?.recentLast ?? []
        // 增加喂养小贴士
        VStack(alignment: .leading, spacing: 6) {
            if let tip = entry.payload?.tip?.text, !tip.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("喂养小贴士")
                            .font(.system(size: 10))
                            .foregroundColor(textSecondary)
                        Text(tip)
                            .font(.system(size: 12))
                            .foregroundColor(textPrimary)
                            .lineLimit(2)
                    }
                }
            }
            if items.isEmpty {
                 fallbackMessage
             } else {
                Spacer(minLength: 3)
                VStack(spacing: 3) {
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, row in
                            recentCell(row, logoSize: 45, nameSize: 14, timeSize: 18)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        
    }

    @ViewBuilder
    private var largeBody: some View {
        let items = recentExcludingHero
        let hasHero = entry.payload?.hero != nil
        let hasRecent = !items.isEmpty

        VStack(alignment: .leading, spacing: 6) {
            if let tip = entry.payload?.tip?.text, !tip.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("喂养小贴士")
                            .font(.system(size: 10))
                            .foregroundColor(textSecondary)
                        Text(tip)
                            .font(.system(size: 12))
                            .foregroundColor(textPrimary)
                            .lineLimit(8)
                    }
                }
            }

            if hasHero || hasRecent {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 10) {
                    if let hero = entry.payload?.hero {
                        sectionTitle("预测即将发生", size: 12, centered: true)
                        HStack(alignment: .center, spacing: 12) {
                            eventLogo(path: hero.logoFile, color: hero.color, size: 66)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hero.name)
                                    .font(.system(size: 18))
                                    // 随事件颜色
                                    .foregroundColor(parseColor(hero.color ?? textPrimary))
                                    .lineLimit(1)
                                Text(predictSubtitle(for: hero))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(parseColor(hero.color ?? textSecondary))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if hasRecent {
                        sectionTitle("后续留意·上次记录", size: 10)
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, row in
                                recentCell(row, logoSize: 45, nameSize: 14, timeSize: 14)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                fallbackMessage
            }
        }
    }

    @ViewBuilder
    private func sectionTitle(_ text: String, size: CGFloat, centered: Bool = false) -> some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(textSecondary)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }

    @ViewBuilder
    private var fallbackMessage: some View {
        Spacer(minLength: 0)
        Text(entry.payload?.message ?? "打开胖宝记录")
            .font(.system(size: 13))
            .foregroundColor(textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
        Spacer(minLength: 0)
    }

    @ViewBuilder
    private func brandLogo(size: CGFloat) -> some View {
        if let uiImage = UIImage(named: "BrandLogo", in: Bundle.main, compatibleWith: nil) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private func recentCell(_ row: WidgetRow, logoSize: CGFloat, nameSize: CGFloat, timeSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 4) {
            eventLogo(path: row.logoFile, color: row.color, size: logoSize)
            VStack(alignment: .leading, spacing: 1) {
                Text(row.name)
                    .font(.system(size: nameSize, weight: .semibold))
                    .foregroundColor(parseColor(row.color ?? textPrimary))
                    .lineLimit(1)
                Text(lastAtSubtitle(for: row))
                    .font(.system(size: timeSize, weight: .semibold))
                    // 随事件颜色
                    .foregroundColor(parseColor(row.color ?? textSecondary))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func eventLogo(path: String?, color: String?, size: CGFloat) -> some View {
        if let uiImage = loadLogoImage(path: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        } else {
            eventOrb(color: color, size: size)
        }
    }

    private func eventOrb(color: String?, size: CGFloat) -> some View {
        let tint = parseColor(color ?? "#5BA3E8")
        return Circle()
            .fill(tint.opacity(0.25))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(tint)
                    .frame(width: size * 0.55, height: size * 0.55),
            )
    }

    private func loadLogoImage(path: String?) -> UIImage? {
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

    private func predictSubtitle(for row: WidgetRow) -> String {
        if let n = row.nextAt, let d = ISO8601DateFormatter.pangbao.date(from: n) {
            let overdue = row.status == "overdue" || d < Date()
            return overdue ? formatOverdue(since: d) : formatUpcoming(until: d)
        }
        return "约稍后"
    }

    private func lastAtSubtitle(for row: WidgetRow) -> String {
        guard let raw = row.lastAt, let d = ISO8601DateFormatter.pangbao.date(from: raw) else {
            return "暂无"
        }
        let cal = Calendar.current
        let h = cal.component(.hour, from: d)
        let m = cal.component(.minute, from: d)
        let hm = String(format: "%02d:%02d", h, m)
        if cal.isDateInToday(d) { return hm }
        if cal.isDateInYesterday(d) { return "昨天 \(hm)" }
        let month = cal.component(.month, from: d)
        let day = cal.component(.day, from: d)
        return "\(month)月\(day)日"
    }

    private func formatHeader(_ header: WidgetHeader) -> String {
        if let line = header.displayLine, !line.isEmpty { return line }
        return header.nickname ?? "宝宝"
    }
}

@main
struct PangbaoWidgetMain: Widget {
    let kind: String = "PangbaoWidget"

    var body: some WidgetConfiguration {
        let configuration = StaticConfiguration(kind: kind, provider: PangbaoWidgetProvider()) { entry in
            PangbaoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("胖宝")
        .description("即将发生的喂养事件")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])

        if #available(iOSApplicationExtension 17.0, *) {
            return configuration.contentMarginsDisabled()
        }
        return configuration
    }
}

extension ISO8601DateFormatter {
    static let pangbao: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

private func parseColor(_ raw: String) -> Color {
    var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    if s.count == 8 { s = String(s.suffix(6)) }
    var rgb: UInt64 = 0
    Scanner(string: s).scanHexInt64(&rgb)
    return Color(
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255,
    )
}

func formatElapsed(from start: Date) -> String {
    let sec = max(0, Int(Date().timeIntervalSince(start)))
    let h = sec / 3600
    let m = (sec % 3600) / 60
    let s = sec % 60
    if h < 1 { return String(format: "%02d:%02d", m, s) }
    return String(format: "%02d:%02d:%02d", h, m, s)
}

func formatOverdue(since date: Date) -> String {
    let mins = max(0, Int(Date().timeIntervalSince(date) / 60))
    if mins < 1 { return "已超时 · 约 1 分钟" }
    if mins < 60 { return "已超时 · 约 \(mins) 分钟" }
    if mins < 1440 { return "已超时 · 约 \(mins / 60) 小时" }
    return "已超时 · 约 \(mins / 1440) 天"
}

func formatUpcoming(until date: Date) -> String {
    let mins = max(0, Int(date.timeIntervalSince(Date()) / 60))
    if mins < 1 { return "约 1 分钟后" }
    if mins < 60 { return "约 \(mins) 分钟后" }
    if mins < 1440 { return "约 \(mins / 60) 小时后" }
    return "约 \(mins / 1440) 天后"
}

// MARK: - 过滤掉 hero 的最近记录
private var recentExcludingHero: [WidgetRow] {
    guard let hero = entry.payload?.hero else {
        return entry.payload?.recentLast ?? []
    }
    return (entry.payload?.recentLast ?? [])
        .filter { $0.kind != hero.kind }
}
