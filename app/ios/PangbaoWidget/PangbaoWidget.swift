import WidgetKit
import SwiftUI

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
    let hero: WidgetRow?
    let recentLast: [WidgetRow]
    let tip: WidgetTip?

    enum CodingKeys: String, CodingKey {
        case state, message, header, hero, recentLast, tip
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        state = try c.decodeIfPresent(String.self, forKey: .state) ?? "empty"
        message = try c.decodeIfPresent(String.self, forKey: .message)
        header = try c.decodeIfPresent(WidgetHeader.self, forKey: .header)
        hero = try c.decodeIfPresent(WidgetRow.self, forKey: .hero)
        recentLast = try c.decodeIfPresent([WidgetRow].self, forKey: .recentLast) ?? []
        tip = try c.decodeIfPresent(WidgetTip.self, forKey: .tip)
    }
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

struct PangbaoWidgetEntryView: View {
    var entry: PangbaoWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.87, blue: 0.95),
                    Color(red: 0.91, green: 0.96, blue: 0.99),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            VStack(alignment: .leading, spacing: 6) {
                if let header = entry.payload?.header, entry.payload?.state != "empty" {
                    Text(formatHeader(header))
                        .font(.system(size: family == .systemLarge ? 14 : 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.24, green: 0.29, blue: 0.30))
                        .lineLimit(1)
                }
                contentBody
            }
            .padding(family == .systemLarge ? 12 : 10)
        }
        .widgetURL(URL(string: "pangbao://home"))
    }

    @ViewBuilder
    private var contentBody: some View {
        if entry.payload?.state == "loading" || entry.payload?.state == "empty" {
            Spacer(minLength: 0)
            Text(entry.payload?.message ?? "打开胖宝记录")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
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
                Text("即将发生")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                    .frame(maxWidth: .infinity, alignment: .center)
                eventOrb(size: 40)
                Text(hero.name)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                Text(predictSubtitle(for: hero))
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
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
        if items.isEmpty {
            fallbackMessage
        } else {
            Text("上次记录")
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
            HStack(alignment: .center, spacing: 0) {
                ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, row in
                    recentCell(row, logoSize: 28, nameSize: 9, timeSize: 8)
                        .frame(maxWidth: .infinity)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var largeBody: some View {
        let items = entry.payload?.recentLast ?? []
        let hasHero = entry.payload?.hero != nil
        let hasRecent = !items.isEmpty

        VStack(alignment: .leading, spacing: 6) {
            if let tip = entry.payload?.tip?.text, !tip.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("喂养小贴士")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                        Text(tip)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.24, green: 0.29, blue: 0.30))
                            .lineLimit(5)
                    }
                }
            }

            if hasHero || hasRecent {
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 10) {
                    if let hero = entry.payload?.hero {
                        Text("即将发生")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                            .frame(maxWidth: .infinity, alignment: .center)
                        HStack(alignment: .center, spacing: 12) {
                            eventOrb(size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hero.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                Text(predictSubtitle(for: hero))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if hasRecent {
                        Text("上次记录")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, row in
                                recentCell(row, logoSize: 32, nameSize: 10, timeSize: 9)
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
    private var fallbackMessage: some View {
        Spacer(minLength: 0)
        Text(entry.payload?.message ?? "打开胖宝记录")
            .font(.system(size: 13))
            .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
            .frame(maxWidth: .infinity, alignment: .center)
        Spacer(minLength: 0)
    }

    private func recentCell(_ row: WidgetRow, logoSize: CGFloat, nameSize: CGFloat, timeSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 4) {
            RoundedRectangle(cornerRadius: logoSize / 2)
                .fill(parseColor(row.color).opacity(0.25))
                .frame(width: logoSize, height: logoSize)
                .overlay(
                    Circle()
                        .fill(parseColor(row.color))
                        .frame(width: logoSize * 0.55, height: logoSize * 0.55),
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(row.name)
                    .font(.system(size: nameSize, weight: .semibold))
                    .lineLimit(1)
                Text(lastAtSubtitle(for: row))
                    .font(.system(size: timeSize))
                    .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.56))
                    .lineLimit(1)
            }
        }
    }

    private func eventOrb(size: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 0.36, green: 0.64, blue: 0.91).opacity(0.25))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(Color(red: 0.36, green: 0.64, blue: 0.91))
                    .frame(width: size * 0.55, height: size * 0.55),
            )
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

    private func parseColor(_ raw: String?) -> Color {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return Color(red: 0.36, green: 0.64, blue: 0.91)
        }
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 8 { s = String(s.suffix(6)) }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        return Color(red: Double((rgb >> 16) & 0xFF) / 255, green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}

@main
struct PangbaoWidgetMain: Widget {
    let kind: String = "PangbaoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PangbaoWidgetProvider()) { entry in
            PangbaoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("胖宝")
        .description("即将发生的喂养事件")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ISO8601DateFormatter {
    static let pangbao: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
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
