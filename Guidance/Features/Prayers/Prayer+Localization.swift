import Adhan
import Foundation

extension Prayer {
  var localizedName: String {
    localizedName(on: Date(), locale: .app)
  }

  func localizedName(on date: Date, locale: Locale = .app) -> String {
    let key: String.LocalizationValue =
      switch self {
      case .fajr: "prayer.fajr"
      case .sunrise: "prayer.sunrise"
      case .dhuhr: isFridayInStoredTimeZone(on: date) ? "prayer.dhuhr.jumuah" : "prayer.dhuhr"
      case .asr: "prayer.asr"
      case .maghrib: "prayer.maghrib"
      case .isha: "prayer.isha"
      }
    return localizedString(key, locale: locale)
  }

  /// Stable Settings label. Unlike `localizedName(on:)`, this never renames
  /// Dhuhr to Jumu'ah just because Settings is opened on a Friday.
  var settingsLocalizedName: String {
    settingsLocalizedName(locale: .app)
  }

  func settingsLocalizedName(locale: Locale = .app) -> String {
    let key: String.LocalizationValue =
      switch self {
      case .fajr: "prayer.fajr"
      case .sunrise: "prayer.sunrise"
      case .dhuhr: "prayer.dhuhr"
      case .asr: "prayer.asr"
      case .maghrib: "prayer.maghrib"
      case .isha: "prayer.isha"
      }
    return localizedString(key, locale: locale)
  }

  var abbreviation: String {
    abbreviation(on: Date(), locale: .app)
  }

  func abbreviation(on date: Date, locale: Locale = .app) -> String {
    let key: String.LocalizationValue =
      switch self {
      case .fajr: "prayer.fajr.abbr"
      case .sunrise: "prayer.sunrise.abbr"
      case .dhuhr: isFridayInStoredTimeZone(on: date) ? "prayer.dhuhr.jumuah.abbr" : "prayer.dhuhr.abbr"
      case .asr: "prayer.asr.abbr"
      case .maghrib: "prayer.maghrib.abbr"
      case .isha: "prayer.isha.abbr"
      }
    return localizedString(key, locale: locale)
  }

  private func isFridayInStoredTimeZone(on date: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: Preferences.shared.storedTimeZone) ?? .current
    return calendar.component(.weekday, from: date) == 6
  }
}
