import Adhan
import Foundation
import OSLog

extension Preferences {
  func migrateLegacyPreferencesIfNeeded() {
    defer {
      defaults.set(currentAppVersion, forKey: Key.version)
    }

    guard let storedVersion else { return }
    guard storedVersion.compare("2.0.2", options: .numeric) == .orderedAscending else { return }
    guard MethodPreference(rawValue: defaults.integer(forKey: Key.method)) == .gulf else { return }

    defaults.set(MethodPreference.custom.rawValue, forKey: Key.method)
    AppLog.migration.notice("Migrated legacy gulf calculation method to custom")
  }

  func migrateLegacyNotificationSettings() -> [String: PrayerNotificationConfig] {
    var settings: [String: PrayerNotificationConfig] = [:]

    settings[Prayer.fajr.settingsKey] = legacyConfig(
      for: .fajr,
      alertEnabledKey: Key.fajrAlertEnabled,
      soundKey: Key.fajrAlertSound,
      customSoundKey: Key.fajrCustomSound,
      defaultSound: .fajr,
      preReminderEnabledKey: Key.fajrReminderEnabled,
      preReminderOffsetKey: Key.fajrReminderOffset
    )
    settings[Prayer.sunrise.settingsKey] = legacyConfig(
      for: .sunrise,
      alertEnabledKey: Key.shuruqAlertEnabled,
      soundKey: Key.fajrAlertSound,
      customSoundKey: Key.fajrCustomSound,
      defaultSound: .system,
      preReminderEnabledKey: Key.shuruqReminderEnabled,
      preReminderOffsetKey: Key.shuruqReminderOffset
    )
    settings[Prayer.dhuhr.settingsKey] = legacyConfig(
      for: .dhuhr,
      alertEnabledKey: Key.dhuhrAlertEnabled,
      soundKey: Key.dhuhrAlertSound,
      customSoundKey: Key.dhuhrCustomSound,
      defaultSound: .alafasy
    )
    settings[Prayer.asr.settingsKey] = legacyConfig(
      for: .asr,
      alertEnabledKey: Key.asrAlertEnabled,
      soundKey: Key.asrAlertSound,
      customSoundKey: Key.asrCustomSound,
      defaultSound: .alafasy
    )
    settings[Prayer.maghrib.settingsKey] = legacyConfig(
      for: .maghrib,
      alertEnabledKey: Key.maghribAlertEnabled,
      soundKey: Key.maghribAlertSound,
      customSoundKey: Key.maghribCustomSound,
      defaultSound: .alafasy
    )
    settings[Prayer.isha.settingsKey] = legacyConfig(
      for: .isha,
      alertEnabledKey: Key.ishaAlertEnabled,
      soundKey: Key.ishaAlertSound,
      customSoundKey: Key.ishaCustomSound,
      defaultSound: .alafasy
    )

    return settings
  }

  private func legacyConfig(
    for prayer: Prayer,
    alertEnabledKey: String,
    soundKey: String,
    customSoundKey: String?,
    defaultSound: AdhanSound,
    preReminderEnabledKey: String? = nil,
    preReminderOffsetKey: String? = nil
  ) -> PrayerNotificationConfig {
    var config = PrayerNotificationConfig.defaultConfig(for: prayer)
    config.alertEnabled = defaults.bool(forKey: alertEnabledKey)
    config.alertSound = legacySound(
      forKey: soundKey,
      customSoundKey: customSoundKey,
      defaultSound: defaultSound
    )

    if let preReminderEnabledKey {
      config.preReminderEnabled = defaults.bool(forKey: preReminderEnabledKey)
    }
    if let preReminderOffsetKey {
      config.preReminderOffset = defaults.integer(forKey: preReminderOffsetKey)
    }
    config.preReminderSound = config.alertSound == .none ? .system : config.alertSound

    return config
  }

  private func legacySound(
    forKey key: String,
    customSoundKey: String?,
    defaultSound: AdhanSound
  ) -> AdhanSound {
    switch defaults.integer(forKey: key) {
    case 0: .none
    case 2: .alafasy
    case 3: .yusuf
    case 4: .makkah
    case 5: .istanbul
    case 6: .aqsa
    case 7: .fajr
    case 10:
      if let customSoundKey, let data = defaults.data(forKey: customSoundKey), !data.isEmpty {
        .custom(CustomAdhanFile(legacyBookmarkData: data))
      } else {
        defaultSound
      }
    default: defaultSound
    }
  }

  private var storedVersion: String? {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
    return defaults.persistentDomain(forName: bundleIdentifier)?[Key.version] as? String
  }

  private var currentAppVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "3.0.0"
  }
}
