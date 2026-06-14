import Foundation

/// The single value the app hands to the widget. It is intentionally a plain,
/// `Codable`/`Sendable` value type with **no dependency on Adhan or the app's
/// localization layer** - every user-facing string (prayer names, times,
/// reminder summaries, chrome labels) is already localized by the app before it
/// lands here. The widget renders verbatim, so it needs no calculation or
/// localization code of its own.
nonisolated struct GuidanceWidgetSnapshot: Codable, Equatable, Sendable {
  var generatedAt: Date
  var todayStart: Date
  /// Next-day wall-clock midnight in the prayer time zone, used as the daily
  /// reload boundary so it stays correct even if the device time zone differs
  /// from the stored prayer time zone.
  var nextDayStart: Date
  var localeIdentifier: String
  var layoutDirectionIsRTL: Bool
  var locationName: String
  var hijriDay: String
  var hijriMonth: String
  var hijriYear: String
  var gregorianDateText: String
  var prayers: [GuidanceWidgetPrayer]
  var tomorrowFajr: GuidanceWidgetPrayer?
  var silentMode: Bool
  var activeAlert: GuidanceWidgetActiveAlert?
  var labels: GuidanceWidgetLabels
  /// The calm-color theme (accent / primary / background) for both appearances.
  /// Optional so snapshots written before theming still decode; reads go through
  /// `resolvedTheme`, which falls back to the default Nocturne look.
  var theme: GuidanceWidgetTheme?

  /// The theme to render with - the stored one, or the default Nocturne when a
  /// pre-theming snapshot is loaded after an upgrade (self-heals on next publish).
  var resolvedTheme: GuidanceWidgetTheme { theme ?? .nocturne }

  /// The locale to render the widget's *live* (relative) text with. Rebuilding a
  /// `Locale` from a bare identifier drops the numbering system, which would make
  /// the relative countdown fall back to Latin digits under Arabic/Urdu/Persian
  /// (arabext) or Bengali (beng). Re-apply it explicitly here, mirroring
  /// `AppLanguage.locale`, so the extension and the in-app preview share one rule.
  var resolvedLocale: Locale {
    let base = Locale(identifier: localeIdentifier)
    let numbering: String?
    switch base.language.languageCode?.identifier {
    case "ar": numbering = "arab"
    case "ur", "fa": numbering = "arabext"
    case "bn": numbering = "beng"
    default: numbering = nil
    }
    guard let numbering else { return base }
    var components = Locale.Components(locale: base)
    components.numberingSystem = Locale.NumberingSystem(numbering)
    return Locale(components: components)
  }

  /// The Iqama count-up / "Now" window: how long a just-fired prayer leads as the
  /// focus (count-up) and stays flagged "Now" before reverting. A timeline entry
  /// at +nowWindow forces the refresh. Widened from 5 to 15 min for the count-up.
  static let nowWindow: TimeInterval = 15 * 60

  /// Sunrise is a daylight marker, not an alerted prayer: it never earns the green
  /// count-up nor the imminent red. Excluding it here keeps `currentPrayer`, the
  /// `.current` row state, the count-up focus, and `tone` all consistent.
  static let sunriseID = "sunrise"

  func nextPrayer(at date: Date) -> GuidanceWidgetPrayer? {
    prayers.first { $0.time > date } ?? tomorrowFajr ?? prayers.first
  }

  /// The most recent **alerted** prayer whose time has started (the "current
  /// window"). Sunrise is excluded so it never lights up as "Now" or count-up;
  /// the focus simply moves on to Dhuhr after sunrise.
  func currentPrayer(at date: Date) -> GuidanceWidgetPrayer? {
    prayers.last { $0.time <= date && $0.id != GuidanceWidgetSnapshot.sunriseID }
  }

  /// The most recent prayer whose time has started, INCLUDING Sunrise - the
  /// start of the interval the user is currently in. Drives the always-on "since"
  /// count-up. Nil before the day's first prayer time (yesterday's Isha is not
  /// carried in the snapshot).
  func previousPrayer(at date: Date) -> GuidanceWidgetPrayer? {
    prayers.last { $0.time <= date }
  }

  /// The "since previous prayer" count-up string for `prayer` ("+1:30"), or nil
  /// unless `prayer` is the most-recent-passed row AND not currently inside its
  /// green "Now" window (during which the count-up focus already leads). Used by
  /// the Medium/Large schedule to anchor the row the user is "at".
  func sinceText(for prayer: GuidanceWidgetPrayer, at date: Date) -> String? {
    guard let prev = previousPrayer(at: date),
      prev.id == prayer.id, prev.time == prayer.time
    else { return nil }
    if case .current = rowState(for: prayer, at: date) { return nil }
    return RelativeDurationFormatter.string(
      seconds: date.timeIntervalSince(prev.time), direction: .up,
      locale: resolvedLocale, bidiIsolated: true)
  }

  func prayer(id: String) -> GuidanceWidgetPrayer? {
    prayers.first { $0.id == id }
  }

  func isActive(_ prayer: GuidanceWidgetPrayer) -> Bool {
    activeAlert?.prayerID == prayer.id
  }

  func clearingActiveAlert(generatedAt date: Date = Date()) -> GuidanceWidgetSnapshot {
    var snapshot = self
    snapshot.generatedAt = date
    snapshot.activeAlert = nil
    return snapshot
  }

  /// Equality that ignores `generatedAt` - pure build-time metadata that nothing
  /// renders or times off, so two snapshots differing only in when they were
  /// built display identically at every timeline entry. Lets the store skip a
  /// reload when a re-publish carries no visible change.
  func hasSameContent(as other: GuidanceWidgetSnapshot) -> Bool {
    var normalized = other
    normalized.generatedAt = generatedAt
    return self == normalized
  }

  /// Tone for a given moment. The active-alert and silent states are captured at
  /// build time (any change to them triggers a timeline reload), while the
  /// "imminent" state is derived from `date` so the red treatment appears in the
  /// 15 minutes before a prayer as the timeline advances - without a reload.
  func tone(at date: Date) -> GuidanceWidgetTone {
    if silentMode { return .silent }
    if let activeAlert { return activeAlert.slot.tone }
    guard let next = nextPrayer(at: date) else { return .normal }
    // The widget never turns red before sunrise - it is not an alerted prayer.
    if next.id == GuidanceWidgetSnapshot.sunriseID { return .normal }
    let secondsUntilPrayer = next.time.timeIntervalSince(date)
    return (secondsUntilPrayer >= 0 && secondsUntilPrayer <= 15 * 60) ? .imminent : .normal
  }

  /// The single element that leads every surface at a given moment (section-6
  /// precedence, audio handled separately by the shell). Exactly one focus shows
  /// at a time, and it travels down the day as prayers fire.
  enum Focus: Equatable {
    /// A just-fired alerted prayer, leading as the green count-up for `nowWindow`.
    case countUp(GuidanceWidgetPrayer)
    /// The next prayer's calm count-down (the resting state).
    case countdown(GuidanceWidgetPrayer)
    /// End of day: counting down to tomorrow's Fajr (not a row in today's list).
    case tomorrow(GuidanceWidgetPrayer)

    var prayer: GuidanceWidgetPrayer {
      switch self {
      case let .countUp(p), let .countdown(p), let .tomorrow(p): return p
      }
    }
  }

  func focus(at date: Date) -> Focus? {
    // Count-up wins: a non-sunrise prayer fired within the window leads everywhere.
    // Strictly `<` so that the timeline entry placed at exactly `time + nowWindow`
    // flips to the next prayer's countdown - otherwise that boundary entry would
    // still read count-up and the live `.relative` text would keep climbing for
    // hours until the next (far-off) entry.
    if let current = currentPrayer(at: date),
      date.timeIntervalSince(current.time) < GuidanceWidgetSnapshot.nowWindow {
      return .countUp(current)
    }
    guard let next = nextPrayer(at: date) else { return nil }
    // After Isha, `nextPrayer` falls back to tomorrow's Fajr (time ≥ next-day
    // start). That has no row in today's list, so it floats as the Tomorrow card.
    if next.time >= nextDayStart { return .tomorrow(next) }
    return .countdown(next)
  }

  /// Tone for the ambient background wash. Unlike `tone(at:)` it reflects the
  /// post-prayer count-up, so the backdrop greens while a prayer is "now".
  func backgroundTone(at date: Date) -> GuidanceWidgetTone {
    if silentMode { return .silent }
    if let activeAlert { return activeAlert.slot.tone }
    if case .countUp = focus(at: date) { return .playingPrayerAudio }
    return tone(at: date)
  }

  /// The display state for a row, combining the per-moment tone (next prayer)
  /// with the active-audio override.
  func rowState(for prayer: GuidanceWidgetPrayer, at date: Date) -> GuidanceWidgetRowState {
    if let activeAlert, activeAlert.prayerID == prayer.id {
      return .active(activeAlert.slot.tone)
    }
    // Match on time as well as id: after Isha, `nextPrayer(at:)` falls back to
    // `tomorrowFajr`, which shares the "fajr" id with today's (passed) Fajr row.
    // Comparing time prevents that row from lighting up as "next".
    if let next = nextPrayer(at: date), next.id == prayer.id, next.time == prayer.time {
      return .next(tone(at: date))
    }
    // "Now" is a brief, just-fired marker: it shows only in the few minutes after
    // a prayer's time, then clears. Without the window the most-recent prayer
    // would read "Now" for hours (e.g. Sunrise lingering until Dhuhr).
    if let current = currentPrayer(at: date), current.id == prayer.id,
      date.timeIntervalSince(current.time) < GuidanceWidgetSnapshot.nowWindow {
      return .current
    }
    return prayer.time <= date ? .passed : .upcoming
  }

  /// Coarse-to-fine widget timeline. The countdown / count-up renders as a
  /// **static** minute-resolution string (never `Text(_, style: .relative)`,
  /// which ticks per-second on a real widget), so the host advances the shown
  /// value only at these entries. Cadence: **every minute** inside any alerted
  /// prayer's final 15 minutes (imminent red) and its 15-minute count-up (green)
  /// - where counting down/up minute-by-minute matters - and **every 5 minutes**
  /// elsewhere, out to a horizon just past the next prayer. `.after(reload)`
  /// (the returned `reload` = horizon) re-densifies for the prayer after that.
  /// Sunrise is excluded from the fine windows (it is not an alerted prayer).
  func timeline(from now: Date) -> (dates: [Date], reload: Date) {
    let minute: TimeInterval = 60
    let alerted = prayers.filter { $0.id != GuidanceWidgetSnapshot.sunriseID }

    // Densely cover up to just past the next prayer (so its approach + count-up
    // are minute-precise), but keep the timeline bounded: at least 2 h ahead, at
    // most 4 h, never past the daily rollover.
    let nextTime = nextPrayer(at: now)?.time ?? nextDayStart
    let horizon = min(
      max(now.addingTimeInterval(2 * 3600), nextTime.addingTimeInterval(GuidanceWidgetSnapshot.nowWindow)),
      min(now.addingTimeInterval(4 * 3600), nextDayStart))

    // A minute is "fine" when it sits in some alerted prayer's [-15 min, +15 min]
    // window (positive = before the prayer / imminent, negative = after / count-up).
    func isFine(_ t: Date) -> Bool {
      alerted.contains { p in
        let secondsUntil = p.time.timeIntervalSince(t)
        return secondsUntil <= 15 * 60 && secondsUntil >= -GuidanceWidgetSnapshot.nowWindow
      }
    }

    var dates: [Date] = []
    let span = max(0, Int(horizon.timeIntervalSince(now) / minute))
    for step in 0...span {
      let t = now.addingTimeInterval(Double(step) * minute)
      if step % 5 == 0 || isFine(t) { dates.append(t) }
    }

    // Exact prayer / reminder edges beyond the dense window, plus the daily
    // rollover, so a tone or state change still lands on an entry out there.
    let tail = (prayers.flatMap(\.timelineBoundaryDates) + [nextDayStart]).filter { $0 > horizon }

    let merged = Set(dates + tail).sorted()
    return (Array(merged.prefix(96)), horizon)
  }

  /// True once the snapshot's day has fully passed (with a short grace), so the
  /// running app should already have published a fresh one. Lets the widget show
  /// an "open the app" prompt instead of yesterday's schedule when the app has
  /// been quit. While the app runs it republishes at midnight, so this stays
  /// false in normal use.
  func isStale(at date: Date) -> Bool {
    date >= nextDayStart.addingTimeInterval(5 * 60)
  }

  static func sample(now: Date = Date()) -> GuidanceWidgetSnapshot {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: now)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)

    func date(hour: Int, minute: Int, in day: Date = start) -> Date {
      calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? now
    }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en")
    formatter.timeStyle = .short

    func prayer(
      _ id: String, _ name: String, _ abbr: String,
      hour: Int, minute: Int,
      summary: String, preShort: String? = nil, detail: String? = nil,
      pre: Int? = nil, post: Int? = nil, alert: Bool = true,
      day: Date = start
    ) -> GuidanceWidgetPrayer {
      let time = date(hour: hour, minute: minute, in: day)
      let clock = formatter.string(from: time)
      return GuidanceWidgetPrayer(
        id: id, name: name, abbreviation: abbr, time: time,
        timeText: clock,
        compactTimeText: clock.replacingOccurrences(of: " AM", with: "").replacingOccurrences(of: " PM", with: ""),
        alertEnabled: alert,
        preReminderMinutes: pre,
        postReminderMinutes: post,
        reminderSummaryText: summary,
        preReminderShortText: preShort,
        reminderDetailText: detail
      )
    }

    let prayers = [
      prayer("fajr", "Fajr", "Fjr", hour: 4, minute: 18, summary: "Alert on · 30m before", preShort: "30m", detail: "30m before", pre: 30),
      prayer("sunrise", "Sunrise", "Sun", hour: 5, minute: 41, summary: "Alert off", alert: false),
      prayer("dhuhr", "Dhuhr", "Dhu", hour: 12, minute: 6, summary: "Alert on"),
      prayer("asr", "Asr", "Asr", hour: 15, minute: 31, summary: "Alert on"),
      prayer("maghrib", "Maghrib", "Mag", hour: 18, minute: 42, summary: "Alert on · 10m before · 5m after", preShort: "10m", detail: "10m before · 5m after", pre: 10, post: 5),
      prayer("isha", "Isha", "Ish", hour: 20, minute: 0, summary: "Alert on"),
    ]

    let tomorrowFajr = prayer(
      "fajr", "Fajr", "Fjr", hour: 4, minute: 18,
      summary: "Alert on · 30m before", preShort: "30m", detail: "30m before", pre: 30, day: nextDay
    )

    return GuidanceWidgetSnapshot(
      generatedAt: now,
      todayStart: start,
      nextDayStart: nextDay,
      localeIdentifier: "en",
      layoutDirectionIsRTL: false,
      locationName: "Makkah",
      hijriDay: "12",
      hijriMonth: "Ramadan",
      hijriYear: "1447 AH",
      gregorianDateText: "Saturday, May 30, 2026",
      prayers: prayers,
      tomorrowFajr: tomorrowFajr,
      silentMode: false,
      activeAlert: nil,
      labels: .english,
      theme: .nocturne
    )
  }
}

nonisolated struct GuidanceWidgetPrayer: Codable, Equatable, Identifiable, Sendable {
  var id: String
  var name: String
  var abbreviation: String
  var time: Date
  /// Already localized + bidi-isolated by the app's `PrayerDisplayFormatter`.
  var timeText: String
  var compactTimeText: String
  var alertEnabled: Bool
  var preReminderMinutes: Int?
  var postReminderMinutes: Int?
  /// One-line, already-localized summary (e.g. "Sound · 10m before · 5m after",
  /// "صوت · قبل ١٠ د · بعد ٥ د", "Son · 10 min avant · 5 min après").
  var reminderSummaryText: String
  /// Compact pre-reminder chip text for the small widget (e.g. "15m"/"١٥د"), or nil.
  var preReminderShortText: String?
  /// The reminder-only detail line for the active card, already localized with
  /// correct per-language word order (e.g. "10m before · 5m after", "قبل ١٠ د ·
  /// بعد ٥ د"). Mirrors `reminderSummaryText` minus the "Alert on" head, so the
  /// card shows just the pre/post timing. Nil when no pre/post reminder is set.
  var reminderDetailText: String?

  var preReminderDate: Date? {
    guard let minutes = preReminderMinutes else { return nil }
    return time.addingTimeInterval(-TimeInterval(minutes) * 60)
  }

  var postReminderDate: Date? {
    guard let minutes = postReminderMinutes else { return nil }
    return time.addingTimeInterval(TimeInterval(minutes) * 60)
  }

  var timelineBoundaryDates: [Date] {
    [preReminderDate, time, postReminderDate].compactMap { $0 }
  }
}

nonisolated struct GuidanceWidgetActiveAlert: Codable, Equatable, Sendable {
  var prayerID: String
  var prayerName: String
  var slot: GuidanceWidgetAlertSlot
  var offsetMinutes: Int?
  var prayerTime: Date
  /// Already-localized title/subtitle for the playing banner.
  var title: String
  var subtitle: String
}

nonisolated enum GuidanceWidgetAlertSlot: String, Codable, Equatable, Sendable {
  case alert
  case preReminder
  case postReminder

  var tone: GuidanceWidgetTone {
    switch self {
    case .alert: .playingPrayerAudio
    case .preReminder: .playingPreReminderAudio
    case .postReminder: .playingPostReminderAudio
    }
  }
}

/// Mirrors `MenuBarStatusTone` from the app so the widget speaks the same state
/// language the menu bar already uses.
nonisolated enum GuidanceWidgetTone: String, Codable, Equatable, Sendable {
  case normal
  case imminent
  case playingPreReminderAudio
  case playingPrayerAudio
  case playingPostReminderAudio
  case silent
}

/// Resolved per-row display state for the medium/large schedules.
nonisolated enum GuidanceWidgetRowState: Equatable {
  case passed
  case current
  case next(GuidanceWidgetTone)
  case upcoming
  case active(GuidanceWidgetTone)
}

/// Localized chrome strings. Built by the app (which owns the full localization
/// layer) and shipped inside the snapshot so the widget needs zero catalog access.
nonisolated struct GuidanceWidgetLabels: Codable, Equatable, Sendable {
  // Rendered by the widget:
  var guidance: String
  var nextPrayer: String
  var today: String
  var tomorrow: String
  var now: String
  /// Word joining a prayer name to its elapsed count-up ("Dhuhr since 1:30").
  var since: String
  var remaining: String
  var at: String
  var silent: String
  var stopAdhan: String
  var stopShort: String
  /// Generic stop label for the larger sizes - covers adhan, du'ā', and reminders.
  var stopAudio: String
  /// Hint shown on the whole-widget stop control while audio plays.
  var tapToStop: String
  /// Shown when the stored snapshot's day has passed (app likely quit).
  var openToUpdate: String
  // Playing-banner titles (rendered by the widget, composed by the app):
  var playingAdhan: String
  var playingDua: String
  var playingPreReminder: String
  var playingPostReminder: String
  // Used by the app's snapshot builder to compose reminder summaries:
  var alertOn: String
  var alertOff: String
  var before: String
  var after: String

  static let english = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "Next Prayer",
    today: "Today",
    tomorrow: "Tomorrow",
    now: "Now",
    since: "since",
    remaining: "remaining",
    at: "at",
    silent: "Silent",
    stopAdhan: "Stop Adhan",
    stopShort: "Stop",
    stopAudio: "Stop Audio",
    tapToStop: "Tap to stop",
    openToUpdate: "Open Guidance to update",
    playingAdhan: "Playing Adhan",
    playingDua: "Playing Du’ā’",
    playingPreReminder: "Pre-reminder",
    playingPostReminder: "Post-reminder",
    alertOn: "Alert on",
    alertOff: "Alert off",
    before: "before",
    after: "after"
  )

  static let arabic = GuidanceWidgetLabels(
    guidance: "هداية",
    nextPrayer: "الصلاة القادمة",
    today: "اليوم",
    tomorrow: "غدًا",
    now: "الآن",
    since: "منذ",
    remaining: "متبقّية",
    at: "في",
    silent: "صامت",
    stopAdhan: "إيقاف الأذان",
    stopShort: "إيقاف",
    stopAudio: "إيقاف الصوت",
    tapToStop: "اضغط للإيقاف",
    openToUpdate: "افتح هداية للتحديث",
    playingAdhan: "جارٍ تشغيل الأذان",
    playingDua: "جارٍ تشغيل الدعاء",
    playingPreReminder: "تذكير قبل الصلاة",
    playingPostReminder: "تذكير بعد الصلاة",
    alertOn: "تنبيه مُفعّل",
    alertOff: "تنبيه مُعطّل",
    before: "قبل",
    after: "بعد"
  )

  static let french = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "Prochaine prière",
    today: "Aujourd’hui",
    tomorrow: "Demain",
    now: "Maintenant",
    since: "depuis",
    remaining: "restant",
    at: "à",
    silent: "Silencieux",
    stopAdhan: "Arrêter l’adhan",
    stopShort: "Arrêter",
    stopAudio: "Arrêter le son",
    tapToStop: "Appuyer pour arrêter",
    openToUpdate: "Ouvrir Guidance pour actualiser",
    playingAdhan: "Adhan en cours",
    playingDua: "Du’ā’ en cours",
    playingPreReminder: "Rappel avant",
    playingPostReminder: "Rappel après",
    alertOn: "Alerte activée",
    alertOff: "Alerte désactivée",
    before: "avant",
    after: "après"
  )

  static let urdu = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "اگلی نماز",
    today: "آج",
    tomorrow: "کل",
    now: "ابھی",
    since: "سے",
    remaining: "باقی",
    at: "بوقت",
    silent: "خاموش",
    stopAdhan: "اذان روکیں",
    stopShort: "روکیں",
    stopAudio: "آواز روکیں",
    tapToStop: "روکنے کے لیے ٹیپ کریں",
    openToUpdate: "اپ ڈیٹ کے لیے Guidance کھولیں",
    playingAdhan: "اذان چل رہی ہے",
    playingDua: "دعا چل رہی ہے",
    playingPreReminder: "نماز سے پہلے یاددہانی",
    playingPostReminder: "نماز کے بعد یاددہانی",
    alertOn: "الرٹ فعال",
    alertOff: "الرٹ غیر فعال",
    before: "پہلے",
    after: "بعد"
  )

  static let indonesian = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "Salat Berikutnya",
    today: "Hari Ini",
    tomorrow: "Besok",
    now: "Sekarang",
    since: "sejak",
    remaining: "tersisa",
    at: "pukul",
    silent: "Senyap",
    stopAdhan: "Hentikan Azan",
    stopShort: "Hentikan",
    stopAudio: "Hentikan Audio",
    tapToStop: "Ketuk untuk menghentikan",
    openToUpdate: "Buka Guidance untuk memperbarui",
    playingAdhan: "Memutar Azan",
    playingDua: "Memutar Doa",
    playingPreReminder: "Pengingat sebelum",
    playingPostReminder: "Pengingat sesudah",
    alertOn: "Peringatan aktif",
    alertOff: "Peringatan nonaktif",
    before: "sebelum",
    after: "setelah"
  )

  static let turkish = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "Sonraki Namaz",
    today: "Bugün",
    tomorrow: "Yarın",
    now: "Şimdi",
    since: "önce",
    remaining: "kaldı",
    at: "saat",
    silent: "Sessiz",
    stopAdhan: "Ezanı Durdur",
    stopShort: "Durdur",
    stopAudio: "Sesi Durdur",
    tapToStop: "Durdurmak için dokun",
    openToUpdate: "Güncellemek için Guidance'ı aç",
    playingAdhan: "Ezan Çalıyor",
    playingDua: "Dua Çalıyor",
    playingPreReminder: "Namaz öncesi hatırlatma",
    playingPostReminder: "Namaz sonrası hatırlatma",
    alertOn: "Uyarı açık",
    alertOff: "Uyarı kapalı",
    before: "önce",
    after: "sonra"
  )

  static let persian = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "نماز بعدی",
    today: "امروز",
    tomorrow: "فردا",
    now: "اکنون",
    since: "از",
    remaining: "مانده",
    at: "در",
    silent: "بی‌صدا",
    stopAdhan: "توقف اذان",
    stopShort: "توقف",
    stopAudio: "توقف صدا",
    tapToStop: "برای توقف ضربه بزنید",
    openToUpdate: "برای به‌روزرسانی Guidance را باز کنید",
    playingAdhan: "در حال پخش اذان",
    playingDua: "در حال پخش دعا",
    playingPreReminder: "یادآور پیش از نماز",
    playingPostReminder: "یادآور پس از نماز",
    alertOn: "هشدار روشن",
    alertOff: "هشدار خاموش",
    before: "قبل",
    after: "بعد"
  )

  static let bengali = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "পরবর্তী নামাজ",
    today: "আজ",
    tomorrow: "আগামীকাল",
    now: "এখন",
    since: "থেকে",
    remaining: "বাকি",
    at: "সময়",
    silent: "নীরব",
    stopAdhan: "আজান বন্ধ করুন",
    stopShort: "বন্ধ",
    stopAudio: "অডিও বন্ধ করুন",
    tapToStop: "বন্ধ করতে ট্যাপ করুন",
    openToUpdate: "আপডেট করতে Guidance খুলুন",
    playingAdhan: "আজান বাজছে",
    playingDua: "দোয়া বাজছে",
    playingPreReminder: "নামাজের আগে অনুস্মারক",
    playingPostReminder: "নামাজের পরে অনুস্মারক",
    alertOn: "সতর্কতা চালু",
    alertOff: "সতর্কতা বন্ধ",
    before: "আগে",
    after: "পরে"
  )

  static let malay = GuidanceWidgetLabels(
    guidance: "Guidance",
    nextPrayer: "Solat Seterusnya",
    today: "Hari Ini",
    tomorrow: "Esok",
    now: "Sekarang",
    since: "sejak",
    remaining: "lagi",
    at: "pada",
    silent: "Senyap",
    stopAdhan: "Hentikan Azan",
    stopShort: "Henti",
    stopAudio: "Hentikan Audio",
    tapToStop: "Ketik untuk hentikan",
    openToUpdate: "Buka Guidance untuk kemas kini",
    playingAdhan: "Memainkan Azan",
    playingDua: "Memainkan Du’ā’",
    playingPreReminder: "Peringatan sebelum",
    playingPostReminder: "Peringatan selepas",
    alertOn: "Amaran hidup",
    alertOff: "Amaran mati",
    before: "sebelum",
    after: "selepas"
  )

  /// Picks the table for the resolved language. Falls back to English for any
  /// language Guidance doesn't translate (matching the app's catalog behavior).
  static func localized(forLanguageCode code: String?) -> GuidanceWidgetLabels {
    switch code {
    case "ar": return .arabic
    case "fr": return .french
    case "ur": return .urdu
    case "id": return .indonesian
    case "tr": return .turkish
    case "fa": return .persian
    case "bn": return .bengali
    case "ms": return .malay
    default: return .english
    }
  }
}

/// Localized abbreviations for compact relative time ("2h 15m", "+12m",
/// "10m before"). Kept in one place so adding a language updates every
/// countdown/count-up surface (menu bar + every widget size) at once. These are
/// short *display* units, not full words - confirmed forms may need a native
/// review pass for the non-Latin scripts.
nonisolated enum LocalizedTimeUnit {
  /// Hour and minute abbreviations for the live countdown, rendered hugging their
  /// number with a space between the two groups ("2h 15m" / "٢س ١٥د" / "۲گھ ۱۵منٹ").
  static func hourMinute(forLanguageCode code: String?) -> (hour: String, minute: String) {
    switch code {
    case "ar": return ("س", "د")
    case "fr": return ("h", "min")
    case "fa": return ("س", "د")
    case "ur": return ("گھ", "منٹ")
    case "tr": return ("sa", "dk")
    case "id": return ("j", "mnt")
    case "ms": return ("j", "min")
    case "bn": return ("ঘ", "মি")
    default: return ("h", "m")
    }
  }

  /// Second abbreviation, hugging its number like `hourMinute` ("45s" / "٤٥ث" /
  /// "45sn"). Used by the sub-minute timer tier. LLM-drafted for the non-Latin
  /// scripts, pending the same native review pass as the other units.
  static func second(forLanguageCode code: String?) -> String {
    switch code {
    case "ar": return "ث"
    case "fa": return "ث"
    case "ur": return "سیک"
    case "tr": return "sn"
    case "id": return "dtk"
    case "ms": return "s"
    case "bn": return "সে"
    case "fr": return "s"
    default: return "s"
    }
  }

  /// Minute abbreviation as a trailing unit for "+12m"/"+١٢ د"/"+12 min"-style
  /// strings. Every language except English separates the unit from the number
  /// with a space; English hugs it ("12m").
  static func minuteSuffix(forLanguageCode code: String?) -> String {
    let minute = hourMinute(forLanguageCode: code).minute
    if code == nil || code == "en" { return minute }
    return " \(minute)"
  }
}

/// Single source of truth for every relative up/down timer - the menu bar
/// (`PrayerDisplayFormatter`) and all widget sizes (`RelativeTime`). Tiers:
/// seconds under a minute (no more "0m"), minutes under an hour, clock `H:MM` at
/// an hour or more. Count-up is prefixed "+". Localized digits come from the
/// passed `Locale` (an inline `NumberFormatter`, mirroring the app-only
/// `Int.localizedDigits` so the widget extension can use it too); the optional
/// FSI/PDI wrap mirrors the app-only `String.bidiIsolated`. Floor-based, so a
/// partial final minute reads as its seconds rather than rounding up to a
/// misleading "0:01".
nonisolated enum RelativeDurationFormatter {
  enum Direction { case down, up }

  static func string(
    seconds: TimeInterval,
    direction: Direction,
    locale: Locale,
    bidiIsolated: Bool = false
  ) -> String {
    let total = max(0, Int(seconds))
    let code = locale.language.languageCode?.identifier
    func n(_ value: Int, minDigits: Int = 1) -> String {
      let formatter = NumberFormatter()
      formatter.locale = locale
      formatter.minimumIntegerDigits = minDigits
      formatter.usesGroupingSeparator = false
      return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    let core: String
    switch total {
    case ..<60:
      core = "\(n(total))\(LocalizedTimeUnit.second(forLanguageCode: code))"
    case ..<3600:
      core = "\(n(total / 60))\(LocalizedTimeUnit.hourMinute(forLanguageCode: code).minute)"
    default:
      let hours = total / 3600
      let minutes = (total % 3600) / 60
      core = "\(n(hours)):\(n(minutes, minDigits: 2))"
    }

    let signed = direction == .up ? "+\(core)" : core
    return bidiIsolated ? "\u{2068}\(signed)\u{2069}" : signed
  }
}
