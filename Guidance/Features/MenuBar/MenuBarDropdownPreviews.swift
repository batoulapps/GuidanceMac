#if DEBUG
import SwiftUI

// MARK: - Preview fixtures

/// Menu-bar dropdown preview snapshots, anchored to the real `now` (minute
/// offsets) so the live countdown renders truthfully - mirroring the widget's
/// `WidgetPreviewData` so the two surfaces are verified against the same states.
private enum MenuPreviewData {
  struct Spec {
    var id: String
    var offset: Int          // minutes from now (negative = already passed)
    var alert = true
    var pre: Int? = nil
    var post: Int? = nil
  }

  static let standard: [Spec] = [
    Spec(id: "fajr", offset: -8 * 60, pre: 30),
    Spec(id: "sunrise", offset: -6 * 60, alert: false),
    Spec(id: "dhuhr", offset: -3 * 60),
    Spec(id: "asr", offset: -60),
    Spec(id: "maghrib", offset: 162, pre: 10, post: 5),
    Spec(id: "isha", offset: 4 * 60),
  ]

  static func names(_ rtl: Bool) -> [String: String] {
    rtl
      ? ["fajr": "الفجر", "sunrise": "الشروق", "dhuhr": "الظهر", "asr": "العصر", "maghrib": "المغرب", "isha": "العشاء"]
      : ["fajr": "Fajr", "sunrise": "Sunrise", "dhuhr": "Dhuhr", "asr": "Asr", "maghrib": "Maghrib", "isha": "Isha"]
  }

  static func make(
    _ specs: [Spec], tomorrowFajrOffset: Int? = nil, silent: Bool = false,
    playingID: String? = nil, rtl: Bool = false, theme: GuidanceWidgetTheme = .nocturne
  ) -> GuidanceWidgetSnapshot {
    let now = Date()
    let cal = Calendar.current
    let todayStart = cal.startOfDay(for: now)
    let nextDay = cal.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86_400)
    let labels: GuidanceWidgetLabels = rtl ? .arabic : .english
    let nameMap = names(rtl)
    let locale = Locale(identifier: rtl ? "ar" : "en")
    let tf = DateFormatter()
    tf.locale = locale
    tf.timeStyle = .short

    func mk(_ s: Spec) -> GuidanceWidgetPrayer {
      let time = now.addingTimeInterval(TimeInterval(s.offset * 60))
      let detail: String?
      switch (s.pre, s.post) {
      case let (p?, q?): detail = rtl ? nil : "\(p)m before · \(q)m after"
      case let (p?, nil): detail = rtl ? nil : "\(p)m before"
      case let (nil, q?): detail = rtl ? nil : "\(q)m after"
      default: detail = nil
      }
      let name = nameMap[s.id] ?? s.id
      return GuidanceWidgetPrayer(
        id: s.id, name: name, abbreviation: name, time: time,
        timeText: tf.string(from: time), compactTimeText: tf.string(from: time),
        alertEnabled: s.alert, preReminderMinutes: s.pre, postReminderMinutes: s.post,
        reminderSummaryText: "", preReminderShortText: nil, reminderDetailText: detail)
    }

    let prayers = specs.map(mk)
    let tomorrow = tomorrowFajrOffset.map { mk(Spec(id: "fajr", offset: $0, pre: 30)) }
    var alert: GuidanceWidgetActiveAlert?
    if let playingID, let p = prayers.first(where: { $0.id == playingID }) {
      alert = GuidanceWidgetActiveAlert(
        prayerID: p.id, prayerName: p.name, slot: .alert, offsetMinutes: nil,
        prayerTime: p.time, title: labels.playingAdhan, subtitle: "\(p.name) · \(p.timeText)")
    }

    return GuidanceWidgetSnapshot(
      generatedAt: now, todayStart: todayStart, nextDayStart: nextDay,
      localeIdentifier: rtl ? "ar" : "en", layoutDirectionIsRTL: rtl,
      locationName: rtl ? "مكة" : "Makkah",
      hijriDay: rtl ? "١٢" : "12", hijriMonth: rtl ? "رمضان" : "Ramadan",
      hijriYear: rtl ? "١٤٤٧ هـ" : "1447 AH",
      gregorianDateText: rtl ? "السبت، ٣٠ مايو ٢٠٢٦" : "Saturday, May 30, 2026",
      prayers: prayers, tomorrowFajr: tomorrow, silentMode: silent,
      activeAlert: alert, labels: labels, theme: theme)
  }

  static func idle(rtl: Bool = false, theme: GuidanceWidgetTheme = .nocturne) -> GuidanceWidgetSnapshot {
    make(standard, rtl: rtl, theme: theme)
  }
  static var silent: GuidanceWidgetSnapshot { make(standard, silent: true) }
  static var playing: GuidanceWidgetSnapshot { make(standard, playingID: "maghrib") }

  /// 9 min before Maghrib → imminent red.
  static var imminent: GuidanceWidgetSnapshot {
    make([
      Spec(id: "fajr", offset: -13 * 60),
      Spec(id: "sunrise", offset: -11 * 60, alert: false),
      Spec(id: "dhuhr", offset: -7 * 60),
      Spec(id: "asr", offset: -3 * 60),
      Spec(id: "maghrib", offset: 9, pre: 10, post: 5),
      Spec(id: "isha", offset: 80),
    ])
  }

  /// 4 min after Dhuhr fired → green count-up leads; Asr is the secondary next.
  static func countUp(rtl: Bool = false) -> GuidanceWidgetSnapshot {
    make([
      Spec(id: "fajr", offset: -7 * 60, pre: 30),
      Spec(id: "sunrise", offset: -5 * 60, alert: false),
      Spec(id: "dhuhr", offset: -4),
      Spec(id: "asr", offset: 3 * 60 + 20),
      Spec(id: "maghrib", offset: 6 * 60, pre: 10, post: 5),
      Spec(id: "isha", offset: 8 * 60),
    ], rtl: rtl)
  }

  /// 90 min after Dhuhr → resting countdown to Asr with the un-dimmed "since" row.
  static var since: GuidanceWidgetSnapshot {
    make([
      Spec(id: "fajr", offset: -10 * 60, pre: 30),
      Spec(id: "sunrise", offset: -8 * 60, alert: false),
      Spec(id: "dhuhr", offset: -90),
      Spec(id: "asr", offset: 100, pre: 10),
      Spec(id: "maghrib", offset: 5 * 60, pre: 10, post: 5),
      Spec(id: "isha", offset: 7 * 60),
    ])
  }

  /// After Isha → all today prayers passed, focus is tomorrow's Fajr.
  static var tomorrow: GuidanceWidgetSnapshot {
    make([
      Spec(id: "fajr", offset: -16 * 60),
      Spec(id: "sunrise", offset: -14 * 60, alert: false),
      Spec(id: "dhuhr", offset: -9 * 60),
      Spec(id: "asr", offset: -5 * 60),
      Spec(id: "maghrib", offset: -2 * 60),
      Spec(id: "isha", offset: -30),
    ], tomorrowFajrOffset: 18 * 60)
  }
}

/// One labelled dropdown, clipped like the popover, for side-by-side review.
private struct MenuDropdownPreview: View {
  let title: String
  let snapshot: GuidanceWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(verbatim: title).font(.headline)
      MenuDropdownContent(snapshot: snapshot, now: Date())
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
    }
    .padding(20)
  }
}

// MARK: - Previews

#Preview("Idle · dark") {
  MenuDropdownPreview(title: "Idle", snapshot: MenuPreviewData.idle()).preferredColorScheme(.dark)
}

#Preview("Idle · light") {
  MenuDropdownPreview(title: "Idle", snapshot: MenuPreviewData.idle()).preferredColorScheme(.light)
}

#Preview("Imminent · dark") {
  MenuDropdownPreview(title: "Imminent (<15m)", snapshot: MenuPreviewData.imminent).preferredColorScheme(.dark)
}

#Preview("Count-up · dark") {
  MenuDropdownPreview(title: "Count-up “Now”", snapshot: MenuPreviewData.countUp()).preferredColorScheme(.dark)
}

#Preview("Since previous · dark") {
  MenuDropdownPreview(title: "Since previous prayer", snapshot: MenuPreviewData.since).preferredColorScheme(.dark)
}

#Preview("Tomorrow · dark") {
  MenuDropdownPreview(title: "End of day → Tomorrow", snapshot: MenuPreviewData.tomorrow).preferredColorScheme(.dark)
}

#Preview("Silent · dark") {
  MenuDropdownPreview(title: "Silent", snapshot: MenuPreviewData.silent).preferredColorScheme(.dark)
}

#Preview("Playing · dark") {
  MenuDropdownPreview(title: "Playing adhan (Stop)", snapshot: MenuPreviewData.playing).preferredColorScheme(.dark)
}

#Preview("Arabic idle · dark") {
  MenuDropdownPreview(title: "Arabic (RTL)", snapshot: MenuPreviewData.idle(rtl: true)).preferredColorScheme(.dark)
}

#Preview("Arabic count-up · dark") {
  MenuDropdownPreview(title: "Arabic count-up (RTL)", snapshot: MenuPreviewData.countUp(rtl: true)).preferredColorScheme(.dark)
}

#Preview("Themes · dark") {
  ScrollView {
    VStack(spacing: 16) {
      ForEach(GuidanceWidgetTheme.allPresets, id: \.id) { theme in
        MenuDropdownContent(snapshot: MenuPreviewData.idle(theme: theme), now: Date())
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
    .padding(20)
  }
  .preferredColorScheme(.dark)
}
#endif
