import Adhan
import SwiftUI

struct MenuBarPreview: View {
  let language: AppLanguage
  @Bindable var prefs = Preferences.shared

  private var previewLocale: Locale {
    language.locale
  }

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      Text("settings.general.language.preview.label")
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(1)

      HStack(spacing: 4) {
        if prefs.displayIcon {
          Image(systemName: "moon.stars")
            .font(.system(size: 10))
        }
        if prefs.displayNextPrayer, !previewText.isEmpty {
          Text(previewText)
            .font(.system(size: 11, weight: .medium))
            .monospacedDigit()
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background(
        RoundedRectangle(cornerRadius: 5, style: .continuous)
          .fill(Color(nsColor: .windowBackgroundColor))
          .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
              .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
          )
      )
      .environment(\.locale, previewLocale)
      .environment(\.layoutDirection, previewLocale.preferredLayoutDirection)
      .id(previewIdentity)
      .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
    .animation(.snappy(duration: 0.22), value: previewIdentity)
  }

  private var previewIdentity: String {
    "\(language.rawValue)|\(prefs.displayIcon)|\(prefs.displayNextPrayer)|\(prefs.nextPrayerDisplayName.rawValue)|\(prefs.nextPrayerDisplayType.rawValue)"
  }

  private var previewText: String {
    let name = previewName
    let time = previewTime
    if name.isEmpty, time.isEmpty { return "" }
    if name.isEmpty { return time }
    if time.isEmpty { return name }
    return "\(name) \(time)"
  }

  private var previewName: String {
    switch prefs.nextPrayerDisplayName {
    case .full:
      return Prayer.isha.localizedName(on: Date(), locale: previewLocale)
    case .abbreviation:
      return Prayer.isha.abbreviation(on: Date(), locale: previewLocale)
    case .none:
      return ""
    }
  }

  private var previewTime: String {
    switch prefs.nextPrayerDisplayType {
    case .timeUntil:
      return previewCountdown
    case .timeOfPrayer:
      return previewClockTime
    case .none:
      return ""
    }
  }

  private var previewCountdown: String {
    let hours = 0
    let minutes = 34
    let h = hours.localizedDigits(locale: previewLocale)
    let m = minutes.localizedDigits(minDigits: 2, locale: previewLocale)
    return "\(h):\(m)".bidiIsolated
  }

  private var previewClockTime: String {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 20
    components.minute = 34
    let date = Calendar.current.date(from: components) ?? Date()

    let formatter = DateFormatter()
    formatter.dateFormat = DateFormatter.dateFormat(
      fromTemplate: "j:mm a", options: 0, locale: previewLocale)
    formatter.locale = previewLocale

    let periodFormatter = DateFormatter()
    periodFormatter.dateFormat = "a"
    periodFormatter.locale = previewLocale

    let periodTrim = CharacterSet.whitespacesAndNewlines
      .union(CharacterSet(charactersIn: "\u{00A0}\u{202F}"))

    return formatter.string(from: date)
      .replacingOccurrences(of: periodFormatter.string(from: date), with: "")
      .trimmingCharacters(in: periodTrim)
      .bidiIsolated
  }
}
