import Adhan
import Foundation

extension Preferences {
  func config(for prayer: Prayer) -> PrayerNotificationConfig {
    (notificationSettings[prayer.settingsKey] ?? PrayerNotificationConfig.defaultConfig(for: prayer))
      .sanitized()
  }

  func config(for prayer: Prayer, on date: Date) -> PrayerNotificationConfig {
    if usesJumuahOverride(for: prayer, on: date) {
      return jumuahConfig
    }
    return config(for: prayer)
  }

  func setConfig(_ config: PrayerNotificationConfig, for prayer: Prayer) {
    notificationSettings[prayer.settingsKey] = config.sanitized()
  }

  func setConfig(_ config: PrayerNotificationConfig, for prayer: Prayer, on date: Date) {
    if usesJumuahOverride(for: prayer, on: date) {
      setJumuahConfig(config)
    } else {
      setConfig(config, for: prayer)
    }
  }

  var jumuahConfig: PrayerNotificationConfig {
    (notificationSettings[Prayer.jumuahSettingsKey] ?? config(for: .dhuhr)).sanitized()
  }

  func setJumuahConfig(_ config: PrayerNotificationConfig) {
    notificationSettings[Prayer.jumuahSettingsKey] = config.sanitized()
  }

  func seedJumuahConfigIfNeeded() {
    guard notificationSettings[Prayer.jumuahSettingsKey] == nil else { return }
    notificationSettings[Prayer.jumuahSettingsKey] = config(for: .dhuhr)
  }

  private func usesJumuahOverride(for prayer: Prayer, on date: Date) -> Bool {
    prayer == .dhuhr && jumuahOverrideEnabled && isFridayInStoredTimeZone(date)
  }

  private func isFridayInStoredTimeZone(_ date: Date) -> Bool {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: storedTimeZone) ?? .current
    return calendar.component(.weekday, from: date) == 6
  }

  func updateAutoDetectedSettings() {
    // Re-entrant-safe: when called from inside `updateLocation`'s batch, these
    // writes join that batch; called on its own they coalesce to one refresh.
    batchUpdates {
      if autoDetectMethod {
        methodPreference = MethodPreference.detect(forCountry: country)
      }
      if autoDetectHighLatitudeRule {
        highLatitudeRulePreference = abs(latitude) > 48 ? .seventhOfTheNight : .middleOfTheNight
      }
    }
  }

  func updateLocation(
    latitude: Double, longitude: Double, city: String, state: String, country: String,
    countryName: String, timeZone: String
  ) {
    // One coalesced refresh for the whole location change, not seven.
    batchUpdates {
      self.latitude = latitude
      self.longitude = longitude
      self.city = city
      self.state = state
      self.country = country
      self.countryName = countryName
      self.storedTimeZone = timeZone
      updateAutoDetectedSettings()
    }
  }

  func enforceVisibleMenuBarContent() {
    if !displayIcon && !displayNextPrayer {
      displayIcon = true
    }

    if displayNextPrayer && nextPrayerDisplayName == .none && nextPrayerDisplayType == .none {
      nextPrayerDisplayType = .timeUntil
    }
  }
}
