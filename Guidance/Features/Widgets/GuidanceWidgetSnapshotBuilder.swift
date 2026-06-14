import Adhan
import Foundation

/// Translates the app's live state (Preferences + computed PrayerTimes + audio
/// state) into a `GuidanceWidgetSnapshot`. This is the one place that touches
/// Adhan and the localization layer; everything downstream renders verbatim.
@MainActor
struct GuidanceWidgetSnapshotBuilder {
  var preferences: Preferences
  var prayerTimes: PrayerTimes?
  var tomorrowPrayerTimes: PrayerTimes?
  var currentPrayer: Prayer?
  var nextPrayer: Prayer?
  var audioState: AudioPlaybackState
  var now: Date = Date()

  func build() -> GuidanceWidgetSnapshot? {
    guard let prayerTimes else { return nil }

    let timeZone = TimeZone(identifier: preferences.storedTimeZone) ?? .current
    let locale = preferences.appLanguage.locale
    let languageCode = locale.language.languageCode?.identifier
    let labels = GuidanceWidgetLabels.localized(forLanguageCode: languageCode)
    let formatter = PrayerDisplayFormatter(timeZone: timeZone, hijriOffset: preferences.hijriOffset)
    let calendar = prayerCalendar(timeZone: timeZone)
    let todayStart = calendar.startOfDay(for: now)
    let nextDayStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86_400)

    let prayers = Prayer.allCases.map {
      makeWidgetPrayer($0, time: prayerTimes.time(for: $0), formatter: formatter, locale: locale, labels: labels)
    }

    let tomorrowFajr = tomorrowPrayerTimes.map {
      makeWidgetPrayer(.fajr, time: $0.fajr, formatter: formatter, locale: locale, labels: labels)
    }

    let activeAlert = activeAlertSnapshot(
      from: audioState, prayerTimes: prayerTimes, formatter: formatter, locale: locale, labels: labels)

    return GuidanceWidgetSnapshot(
      generatedAt: now,
      todayStart: todayStart,
      nextDayStart: nextDayStart,
      localeIdentifier: locale.identifier,
      layoutDirectionIsRTL: locale.language.characterDirection == .rightToLeft,
      locationName: preferences.city.isEmpty ? preferences.countryName : preferences.city,
      hijriDay: formatter.hijriDay(on: now),
      hijriMonth: formatter.hijriMonth(on: now),
      hijriYear: formatter.hijriYear(on: now),
      gregorianDateText: gregorianDateText(now, locale: locale, timeZone: timeZone),
      prayers: prayers,
      tomorrowFajr: tomorrowFajr,
      silentMode: preferences.silentMode,
      activeAlert: activeAlert,
      labels: labels,
      // The user's chosen theme (preset or custom), resolved from Preferences.
      // The in-app live preview reads the same `resolvedWidgetTheme`.
      theme: preferences.resolvedWidgetTheme
    )
  }

  // MARK: - Prayer rows

  private func makeWidgetPrayer(
    _ prayer: Prayer,
    time: Date,
    formatter: PrayerDisplayFormatter,
    locale: Locale,
    labels: GuidanceWidgetLabels
  ) -> GuidanceWidgetPrayer {
    let config = preferences.config(for: prayer, on: time).sanitized()
    return GuidanceWidgetPrayer(
      id: prayer.settingsKey,
      name: prayer.localizedName(on: time, locale: locale),
      abbreviation: prayer.abbreviation(on: time, locale: locale),
      time: time,
      timeText: formatter.fullTime(for: time),
      compactTimeText: formatter.compactTime(for: time),
      alertEnabled: config.alertEnabled,
      preReminderMinutes: config.preReminderEnabled ? config.preReminderOffset : nil,
      postReminderMinutes: config.postReminderEnabled ? config.postReminderOffset : nil,
      reminderSummaryText: reminderSummary(for: config, locale: locale, languageCode: locale.language.languageCode?.identifier, labels: labels),
      preReminderShortText: config.preReminderEnabled
        ? minutesText(config.preReminderOffset, locale: locale, languageCode: locale.language.languageCode?.identifier)
        : nil,
      reminderDetailText: reminderDetail(for: config, locale: locale, languageCode: locale.language.languageCode?.identifier, labels: labels)
    )
  }

  /// The reminder-only detail line for the active card: the same pre/post phrases
  /// as `reminderSummaryText` but without the "Alert on" head, so the card shows
  /// just the timing ("10m before · 5m after"). Nil when no pre/post is set.
  private func reminderDetail(
    for config: PrayerNotificationConfig,
    locale: Locale,
    languageCode: String?,
    labels: GuidanceWidgetLabels
  ) -> String? {
    var parts: [String] = []
    if config.preReminderEnabled {
      parts.append(offsetPhrase(config.preReminderOffset, word: labels.before, locale: locale, languageCode: languageCode))
    }
    if config.postReminderEnabled {
      parts.append(offsetPhrase(config.postReminderOffset, word: labels.after, locale: locale, languageCode: languageCode))
    }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
  }

  /// Composes a one-line, fully-localized reminder summary with localized digits
  /// and language-appropriate word order (e.g. Arabic "قبل ١٠ د" vs English
  /// "10m before").
  private func reminderSummary(
    for config: PrayerNotificationConfig,
    locale: Locale,
    languageCode: String?,
    labels: GuidanceWidgetLabels
  ) -> String {
    // Global silent mode overrides every per-prayer alert toggle, so lead with
    // "Silent" rather than a misleading "Alert on" when nothing will sound.
    let head = preferences.silentMode
      ? labels.silent
      : (config.alertEnabled ? labels.alertOn : labels.alertOff)
    var parts: [String] = [head]

    if config.preReminderEnabled {
      parts.append(offsetPhrase(config.preReminderOffset, word: labels.before, locale: locale, languageCode: languageCode))
    }
    if config.postReminderEnabled {
      parts.append(offsetPhrase(config.postReminderOffset, word: labels.after, locale: locale, languageCode: languageCode))
    }
    return parts.joined(separator: " · ")
  }

  private func offsetPhrase(_ minutes: Int, word: String, locale: Locale, languageCode: String?) -> String {
    let value = minutesText(minutes, locale: locale, languageCode: languageCode)
    switch languageCode {
    case "ar": return "\(word) \(value)"          // قبل ١٠ د
    case "fr": return "\(value) \(word)"          // 10 min avant
    default: return "\(value) \(word)"            // 10m before
    }
  }

  private func minutesText(_ minutes: Int, locale: Locale, languageCode: String?) -> String {
    let digits = minutes.localizedDigits(locale: locale)
    let unit = LocalizedTimeUnit.minuteSuffix(forLanguageCode: languageCode)
    return "\(digits)\(unit)".bidiIsolated
  }

  // MARK: - Active alert

  private func activeAlertSnapshot(
    from state: AudioPlaybackState,
    prayerTimes: PrayerTimes,
    formatter: PrayerDisplayFormatter,
    locale: Locale,
    labels: GuidanceWidgetLabels
  ) -> GuidanceWidgetActiveAlert? {
    guard case let .playing(context) = state else { return nil }
    guard context.source == .prayerAlert || context.source == .dua else { return nil }
    guard let prayer = context.prayer, let slot = context.slot else { return nil }

    let prayerTime = context.prayerTime ?? prayerTimes.time(for: prayer)
    let prayerName = prayer.localizedName(on: prayerTime, locale: locale)

    return GuidanceWidgetActiveAlert(
      prayerID: prayer.settingsKey,
      prayerName: prayerName,
      slot: GuidanceWidgetAlertSlot(slot),
      offsetMinutes: context.prayerAlertOffsetMinutes,
      prayerTime: prayerTime,
      title: title(for: context.source, slot: slot, labels: labels),
      subtitle: subtitle(
        for: prayerName, slot: slot, prayerTime: prayerTime,
        offsetMinutes: context.prayerAlertOffsetMinutes, formatter: formatter,
        locale: locale, labels: labels)
    )
  }

  private func title(for source: AudioPlaybackSource, slot: PrayerNotificationSoundSlot, labels: GuidanceWidgetLabels) -> String {
    if source == .dua { return labels.playingDua }
    switch slot {
    case .alert: return labels.playingAdhan
    case .preReminder: return labels.playingPreReminder
    case .postReminder: return labels.playingPostReminder
    }
  }

  private func subtitle(
    for prayerName: String,
    slot: PrayerNotificationSoundSlot,
    prayerTime: Date,
    offsetMinutes: Int?,
    formatter: PrayerDisplayFormatter,
    locale: Locale,
    labels: GuidanceWidgetLabels
  ) -> String {
    switch slot {
    case .alert:
      return "\(prayerName) · \(formatter.fullTime(for: prayerTime))"
    case .preReminder, .postReminder:
      guard let offsetMinutes else { return prayerName }
      // Spell out the unit and direction ("10m before" / "5m after") rather than
      // a bare number, so the banner reads the same way the reminder summary does.
      let word = slot == .preReminder ? labels.before : labels.after
      let phrase = offsetPhrase(
        offsetMinutes, word: word, locale: locale,
        languageCode: locale.language.languageCode?.identifier)
      return "\(prayerName) · \(phrase)"
    }
  }

  // MARK: - Helpers

  private func gregorianDateText(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.timeZone = timeZone
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private func prayerCalendar(timeZone: TimeZone) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar
  }
}

private extension GuidanceWidgetAlertSlot {
  init(_ slot: PrayerNotificationSoundSlot) {
    switch slot {
    case .alert: self = .alert
    case .preReminder: self = .preReminder
    case .postReminder: self = .postReminder
    }
  }
}
