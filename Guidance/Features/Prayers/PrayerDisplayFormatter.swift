import Foundation

struct PrayerDisplayFormatter {
  var timeZone: TimeZone
  var hijriOffset: Int

  init(timeZone: TimeZone, hijriOffset: Int) {
    self.timeZone = timeZone
    self.hijriOffset = hijriOffset
  }

  /// Time remaining until a prayer, for the menu bar ("45s" / "49m" / "2:49").
  /// Delegates to the shared tiered formatter so the menu bar and every widget
  /// size render identically.
  func countdown(from startDate: Date, to endDate: Date) -> String {
    RelativeDurationFormatter.string(
      seconds: endDate.timeIntervalSince(startDate), direction: .down,
      locale: .app, bidiIsolated: true)
  }

  /// Elapsed time since a prayer fired, for the menu-bar Iqama count-up
  /// ("+45s" / "+12m" / "+2:49"). Same shared formatter as `countdown`, so the
  /// count-up and count-down share one style.
  func countUp(from startDate: Date, to endDate: Date) -> String {
    RelativeDurationFormatter.string(
      seconds: endDate.timeIntervalSince(startDate), direction: .up,
      locale: .app, bidiIsolated: true)
  }

  func compactTime(for date: Date) -> String {
    let formatter = timeFormatter()
    let periodFormatter = DateFormatter()
    periodFormatter.dateFormat = "a"
    periodFormatter.locale = formatter.locale
    periodFormatter.timeZone = timeZone
    let periodTrimCharacters = CharacterSet.whitespacesAndNewlines
      .union(CharacterSet(charactersIn: "\u{00A0}\u{202F}"))

    return formatter.string(from: date)
      .replacingOccurrences(of: periodFormatter.string(from: date), with: "")
      .trimmingCharacters(in: periodTrimCharacters)
      .bidiIsolated
  }

  func fullTime(for date: Date) -> String {
    timeFormatter().string(from: date).bidiIsolated
  }

  func adjustedHijriDate(for date: Date) -> Date {
    hijriCalendar.date(byAdding: .day, value: hijriOffset, to: date) ?? date
  }

  func hijriDay(on date: Date = Date()) -> String {
    let day = hijriCalendar.component(.day, from: adjustedHijriDate(for: date))
    return day.localizedDigits()
  }

  func hijriMonth(on date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = hijriCalendar
    formatter.dateFormat = "MMMM"
    formatter.locale = .app
    formatter.timeZone = timeZone
    return formatter.string(from: adjustedHijriDate(for: date))
  }

  func hijriYear(on date: Date = Date()) -> String {
    let year = hijriCalendar.component(.year, from: adjustedHijriDate(for: date))
    let suffix = localizedString("hijri.suffix", locale: .app)
    return "\(year.localizedDigits()) \(suffix)"
  }

  private func timeFormatter() -> DateFormatter {
    let locale = Locale.app
    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(
      fromTemplate: "j:mm a", options: 0, locale: locale)
    formatter.locale = locale
    formatter.timeZone = timeZone
    return formatter
  }

  private var hijriCalendar: Calendar {
    var calendar = Calendar(identifier: .islamicUmmAlQura)
    calendar.timeZone = timeZone
    return calendar
  }
}
