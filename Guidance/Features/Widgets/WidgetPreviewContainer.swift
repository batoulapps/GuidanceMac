import SwiftUI

/// Renders the real shared widget content at a faithful macOS point size,
/// reproducing the system widget container: the same `GuidanceWidgetBackground`
/// the extension installs via `.containerBackground`, clipped to a rounded
/// rectangle. Because it reuses `WidgetContentView` + the shared background and
/// resolves the theme the same way, the in-app preview and the installed widget
/// cannot drift. Used by design verification now and the Appearance tab (Phase 2).
struct WidgetPreviewContainer: View {
  let snapshot: GuidanceWidgetSnapshot
  let size: GuidanceWidgetSize
  var date: Date = Date()

  @Environment(\.colorScheme) private var scheme

  /// macOS desktop widget point sizes.
  private var pointSize: CGSize {
    switch size {
    case .small: CGSize(width: 158, height: 158)
    case .medium: CGSize(width: 338, height: 158)
    case .large: CGSize(width: 338, height: 354)
    }
  }

  var body: some View {
    let colors = snapshot.resolvedTheme.colors(for: scheme)
    content(colors)
      .frame(width: pointSize.width, height: pointSize.height)
      .background {
        GuidanceWidgetBackground(tone: snapshot.backgroundTone(at: date), colors: colors)
      }
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .environment(\.locale, previewLocale)
      .environment(\.layoutDirection, snapshot.layoutDirectionIsRTL ? .rightToLeft : .leftToRight)
      .guidanceColorScheme(snapshot.resolvedTheme.forcedColorScheme)
  }

  @ViewBuilder
  private func content(_ colors: GuidanceWidgetColors) -> some View {
    if let activeAlert = snapshot.activeAlert {
      WidgetStopContent(activeAlert: activeAlert, labels: snapshot.labels, size: size, colors: colors)
    } else {
      WidgetContentView(snapshot: snapshot, size: size, date: date)
    }
  }

  /// Mirror the extension's numbering-system rebuild so live digits match across
  /// Arabic/Urdu/Persian/Bengali. See `GuidanceWidgetSnapshot.resolvedLocale`.
  private var previewLocale: Locale { snapshot.resolvedLocale }
}

// MARK: - Verification gallery (previews only)

/// All three sizes for one snapshot, for side-by-side design review. Renders at
/// the real "now" so the live relative timer (which always counts from the system
/// clock) agrees with the now-anchored preview prayer times.
private struct WidgetSizeGallery: View {
  let title: String
  let snapshot: GuidanceWidgetSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(verbatim: title).font(.headline)
      HStack(alignment: .top, spacing: 20) {
        WidgetPreviewContainer(snapshot: snapshot, size: .small)
        WidgetPreviewContainer(snapshot: snapshot, size: .medium)
      }
      WidgetPreviewContainer(snapshot: snapshot, size: .large)
    }
    .padding(24)
  }
}

/// Preview language: supplies the localized chrome + prayer names + digit shaping
/// so RTL and Arabic-Indic digits can be verified, mirroring the real snapshot.
private enum PreviewLang {
  case en, ar, fr

  var labels: GuidanceWidgetLabels {
    switch self { case .en: .english; case .ar: .arabic; case .fr: .french }
  }
  var id: String { switch self { case .en: "en"; case .ar: "ar"; case .fr: "fr" } }
  var rtl: Bool { self == .ar }
  var location: String { self == .ar ? "مكة" : "Makkah" }
  var hijri: (day: String, month: String, year: String) {
    self == .ar ? ("١٢", "رمضان", "١٤٤٧ هـ") : ("12", "Ramadan", "1447 AH")
  }

  func name(_ id: String) -> String {
    switch self {
    case .ar:
      switch id {
      case "fajr": "الفجر"; case "sunrise": "الشروق"; case "dhuhr": "الظهر"
      case "asr": "العصر"; case "maghrib": "المغرب"; case "isha": "العشاء"; default: id
      }
    case .fr:
      switch id {
      case "fajr": "Fajr"; case "sunrise": "Lever"; case "dhuhr": "Dhuhr"
      case "asr": "Asr"; case "maghrib": "Maghreb"; case "isha": "Isha"; default: id
      }
    case .en:
      switch id {
      case "fajr": "Fajr"; case "sunrise": "Sunrise"; case "dhuhr": "Dhuhr"
      case "asr": "Asr"; case "maghrib": "Maghrib"; case "isha": "Isha"; default: id
      }
    }
  }

  var locale: Locale {
    switch self {
    case .ar:
      var c = Locale.Components(languageCode: .arabic)
      c.numberingSystem = Locale.NumberingSystem("arab")
      return Locale(components: c)
    case .fr: return Locale(identifier: "fr")
    case .en: return Locale(identifier: "en")
    }
  }

  func digits(_ n: Int) -> String {
    let s = "\(n)"
    guard self == .ar else { return s }
    let map: [Character: Character] = [
      "0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
      "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩",
    ]
    return String(s.map { map[$0] ?? $0 })
  }

  /// Reminder detail line, localized with correct word order (mirrors the app).
  func detail(pre: Int?, post: Int?) -> String? {
    func unit() -> String { switch self { case .ar: " د"; case .fr: " min"; case .en: "m" } }
    func phrase(_ m: Int, _ word: String) -> String {
      let v = "\(digits(m))\(unit())"
      return self == .ar ? "\(word) \(v)" : "\(v) \(word)"
    }
    var parts: [String] = []
    if let pre { parts.append(phrase(pre, labels.before)) }
    if let post { parts.append(phrase(post, labels.after)) }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }
}

/// Builds preview snapshots with prayer times anchored to the real `now` (in
/// minute offsets), so both the state logic and the live relative timer render
/// truthfully, in the chosen language.
private enum WidgetPreviewData {
  struct Spec {
    var id: String
    var offset: Int          // minutes from now (negative = already passed)
    var alert = true
    var pre: Int? = nil
    var post: Int? = nil
  }

  static func make(
    prayers specs: [Spec],
    tomorrowFajrOffset: Int? = nil,
    silent: Bool = false,
    playingID: String? = nil,
    lang: PreviewLang = .en
  ) -> GuidanceWidgetSnapshot {
    let now = Date()
    let cal = Calendar.current
    let todayStart = cal.startOfDay(for: now)
    let nextDay = cal.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86_400)
    let tf = DateFormatter()
    tf.locale = lang.locale
    tf.timeStyle = .short
    let ctf = DateFormatter()
    ctf.locale = lang.locale
    ctf.setLocalizedDateFormatFromTemplate("j:mm")  // period-less, locale digits
    let gf = DateFormatter()
    gf.locale = lang.locale
    gf.dateStyle = .full
    gf.timeStyle = .none

    func mk(_ s: Spec) -> GuidanceWidgetPrayer {
      let time = now.addingTimeInterval(TimeInterval(s.offset * 60))
      let pre = s.pre.map { lang.digits($0) + (lang == .ar ? "د" : (lang == .fr ? "min" : "m")) }
      return GuidanceWidgetPrayer(
        id: s.id, name: lang.name(s.id), abbreviation: lang.name(s.id), time: time,
        timeText: tf.string(from: time), compactTimeText: ctf.string(from: time),
        alertEnabled: s.alert, preReminderMinutes: s.pre, postReminderMinutes: s.post,
        reminderSummaryText: "", preReminderShortText: pre,
        reminderDetailText: lang.detail(pre: s.pre, post: s.post))
    }

    let prayers = specs.map(mk)
    let tomorrow = tomorrowFajrOffset.map {
      mk(Spec(id: "fajr", offset: $0, pre: 30))
    }
    var alert: GuidanceWidgetActiveAlert?
    if let playingID, let p = prayers.first(where: { $0.id == playingID }) {
      alert = GuidanceWidgetActiveAlert(
        prayerID: p.id, prayerName: p.name, slot: .alert, offsetMinutes: nil,
        prayerTime: p.time, title: lang.labels.playingAdhan,
        subtitle: "\(p.name) · \(p.timeText)")
    }

    return GuidanceWidgetSnapshot(
      generatedAt: now, todayStart: todayStart, nextDayStart: nextDay,
      localeIdentifier: lang.id, layoutDirectionIsRTL: lang.rtl, locationName: lang.location,
      hijriDay: lang.hijri.day, hijriMonth: lang.hijri.month, hijriYear: lang.hijri.year,
      gregorianDateText: gf.string(from: now),
      prayers: prayers, tomorrowFajr: tomorrow, silentMode: silent,
      activeAlert: alert, labels: lang.labels, theme: .nocturne)
  }

  /// A normal day with the next prayer (Maghrib, +2h42m) carrying pre+post reminders.
  static func standard(silent: Bool = false, playingID: String? = nil, lang: PreviewLang = .en) -> GuidanceWidgetSnapshot {
    make(
      prayers: [
        Spec(id: "fajr", offset: -8 * 60, pre: 30),
        Spec(id: "sunrise", offset: -6 * 60, alert: false),
        Spec(id: "dhuhr", offset: -3 * 60),
        Spec(id: "asr", offset: -60),
        Spec(id: "maghrib", offset: 162, pre: 10, post: 5),
        Spec(id: "isha", offset: 4 * 60),
      ],
      silent: silent, playingID: playingID, lang: lang)
  }

  static func idle(_ lang: PreviewLang = .en) -> GuidanceWidgetSnapshot { standard(lang: lang) }
  static var silent: GuidanceWidgetSnapshot { standard(silent: true) }
  static var playing: GuidanceWidgetSnapshot { standard(playingID: "maghrib") }

  /// 10 min before Maghrib → imminent red.
  static func imminent(_ lang: PreviewLang = .en) -> GuidanceWidgetSnapshot {
    make(prayers: [
      Spec(id: "fajr", offset: -13 * 60),
      Spec(id: "sunrise", offset: -11 * 60, alert: false),
      Spec(id: "dhuhr", offset: -7 * 60),
      Spec(id: "asr", offset: -3 * 60),
      Spec(id: "maghrib", offset: 10, pre: 10, post: 5),
      Spec(id: "isha", offset: 80),
    ], lang: lang)
  }

  /// 4 min after Dhuhr fired → green count-up leads; Asr is the secondary next.
  static func countUp(_ lang: PreviewLang = .en) -> GuidanceWidgetSnapshot {
    make(prayers: [
      Spec(id: "fajr", offset: -7 * 60, pre: 30),
      Spec(id: "sunrise", offset: -5 * 60, alert: false),
      Spec(id: "dhuhr", offset: -4),
      Spec(id: "asr", offset: 3 * 60 + 20),
      Spec(id: "maghrib", offset: 6 * 60, pre: 10, post: 5),
      Spec(id: "isha", offset: 8 * 60),
    ], lang: lang)
  }

  /// 16 min after Dhuhr fired → the 15-min count-up window has closed, so the
  /// focus must be back to the next prayer's countdown (Asr), with no green.
  /// Guards the `focus(at:)` boundary: the count-up must not linger past 15 min
  /// (the bug where the widget stayed green and kept counting up for hours).
  static func countUpEnded(_ lang: PreviewLang = .en) -> GuidanceWidgetSnapshot {
    make(prayers: [
      Spec(id: "fajr", offset: -7 * 60, pre: 30),
      Spec(id: "sunrise", offset: -5 * 60, alert: false),
      Spec(id: "dhuhr", offset: -16),
      Spec(id: "asr", offset: 44, pre: 10),
      Spec(id: "maghrib", offset: 3 * 60, pre: 10, post: 5),
      Spec(id: "isha", offset: 5 * 60),
    ], lang: lang)
  }

  /// 90 min after Dhuhr fired (the green window long closed) → resting countdown
  /// to Asr, with the always-on "since previous prayer" treatment: Small shows
  /// "Dhuhr since: 1:30"; Medium/Large show the un-dimmed Dhuhr row carrying
  /// "+1:30". Mirrors the user's example and exercises the h:mm since tier.
  static func since(_ lang: PreviewLang = .en) -> GuidanceWidgetSnapshot {
    make(prayers: [
      Spec(id: "fajr", offset: -10 * 60, pre: 30),
      Spec(id: "sunrise", offset: -8 * 60, alert: false),
      Spec(id: "dhuhr", offset: -90),
      Spec(id: "asr", offset: 100, pre: 10),
      Spec(id: "maghrib", offset: 5 * 60, pre: 10, post: 5),
      Spec(id: "isha", offset: 7 * 60),
    ], lang: lang)
  }

  /// After Isha → all today prayers passed, focus is tomorrow's Fajr (after midnight).
  static var tomorrow: GuidanceWidgetSnapshot {
    make(
      prayers: [
        Spec(id: "fajr", offset: -16 * 60),
        Spec(id: "sunrise", offset: -14 * 60, alert: false),
        Spec(id: "dhuhr", offset: -9 * 60),
        Spec(id: "asr", offset: -5 * 60),
        Spec(id: "maghrib", offset: -2 * 60),
        Spec(id: "isha", offset: -30),
      ],
      tomorrowFajrOffset: 18 * 60)
  }
}

#Preview("Idle · dark") {
  WidgetSizeGallery(title: "Idle", snapshot: WidgetPreviewData.idle()).preferredColorScheme(.dark)
}

#Preview("Idle · light") {
  WidgetSizeGallery(title: "Idle", snapshot: WidgetPreviewData.idle()).preferredColorScheme(.light)
}

#Preview("Imminent · dark") {
  WidgetSizeGallery(title: "Imminent", snapshot: WidgetPreviewData.imminent()).preferredColorScheme(.dark)
}

#Preview("Count-up · dark") {
  WidgetSizeGallery(title: "Count-up", snapshot: WidgetPreviewData.countUp()).preferredColorScheme(.dark)
}

#Preview("Count-up ended · dark") {
  WidgetSizeGallery(title: "Count-up ended → next prayer", snapshot: WidgetPreviewData.countUpEnded())
    .preferredColorScheme(.dark)
}

#Preview("Since previous · dark") {
  WidgetSizeGallery(title: "Since previous prayer (resting)", snapshot: WidgetPreviewData.since())
    .preferredColorScheme(.dark)
}

#Preview("Arabic since previous · dark") {
  WidgetSizeGallery(title: "Arabic since previous prayer", snapshot: WidgetPreviewData.since(.ar))
    .preferredColorScheme(.dark)
}

#Preview("Tomorrow · dark") {
  WidgetSizeGallery(title: "Tomorrow", snapshot: WidgetPreviewData.tomorrow).preferredColorScheme(.dark)
}

#Preview("Silent · dark") {
  WidgetSizeGallery(title: "Silent", snapshot: WidgetPreviewData.silent).preferredColorScheme(.dark)
}

#Preview("Stop · dark") {
  WidgetSizeGallery(title: "Stop", snapshot: WidgetPreviewData.playing).preferredColorScheme(.dark)
}

#Preview("Arabic · dark") {
  WidgetSizeGallery(title: "Arabic", snapshot: WidgetPreviewData.idle(.ar)).preferredColorScheme(.dark)
}

#Preview("Arabic count-up · dark") {
  WidgetSizeGallery(title: "Arabic count-up", snapshot: WidgetPreviewData.countUp(.ar)).preferredColorScheme(.dark)
}

#Preview("French · dark") {
  WidgetSizeGallery(title: "French", snapshot: WidgetPreviewData.idle(.fr)).preferredColorScheme(.dark)
}

// Magnified single small widget, to judge vertical spacing closely.
#Preview("Small ×2 · dark") {
  WidgetPreviewContainer(snapshot: WidgetPreviewData.idle(), size: .small)
    .scaleEffect(2)
    .frame(width: 360, height: 360)
    .preferredColorScheme(.dark)
}

private func themedIdle(_ theme: GuidanceWidgetTheme) -> GuidanceWidgetSnapshot {
  var s = WidgetPreviewData.idle()
  s.theme = theme
  return s
}

// All presets at medium, to confirm each theme's calm palette reads well.
#Preview("Presets · dark") {
  VStack(spacing: 14) {
    ForEach(GuidanceWidgetTheme.allPresets, id: \.id) { theme in
      WidgetPreviewContainer(snapshot: themedIdle(theme), size: .medium)
    }
  }
  .padding(20)
  .preferredColorScheme(.dark)
}

#Preview("Presets · light") {
  VStack(spacing: 14) {
    ForEach(GuidanceWidgetTheme.allPresets, id: \.id) { theme in
      WidgetPreviewContainer(snapshot: themedIdle(theme), size: .medium)
    }
  }
  .padding(20)
  .preferredColorScheme(.light)
}
