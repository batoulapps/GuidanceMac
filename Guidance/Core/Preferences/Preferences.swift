import Adhan
import Foundation
import OSLog

@Observable
final class Preferences {
  static let shared = Preferences()

  let defaults = UserDefaults.standard

  // MARK: - Change propagation

  /// True only while `init` loads stored values, so the didSets below persist
  /// without emitting a refresh before anything is observing.
  @ObservationIgnored private var isLoading = true
  @ObservationIgnored private var batchDepth = 0
  @ObservationIgnored private var batchedEffects: PreferenceRefresh = []

  /// Declares what just-changed state needs downstream. Called from the
  /// state-affecting didSets so the classification lives next to the data (not
  /// in whatever view toggled it). Inside `batchUpdates` the effects accumulate
  /// and fire once; otherwise this posts immediately. No-op while loading.
  func requestRefresh(_ effects: PreferenceRefresh) {
    guard !isLoading else { return }
    if batchDepth > 0 {
      batchedEffects.formUnion(effects)
      return
    }
    NotificationCenter.default.post(
      name: .guidancePreferencesDidChange, object: nil,
      userInfo: [PreferenceRefresh.userInfoKey: effects.rawValue])
  }

  /// Groups several preference writes (e.g. applying a picked location's city,
  /// coordinates, and time zone together) into a single coalesced refresh.
  func batchUpdates(_ body: () -> Void) {
    batchDepth += 1
    body()
    batchDepth -= 1
    guard batchDepth == 0, !batchedEffects.isEmpty else { return }
    let effects = batchedEffects
    batchedEffects = []
    requestRefresh(effects)
  }

  // MARK: - Display

  var displayNextPrayer: Bool = true {
    didSet {
      defaults.set(displayNextPrayer, forKey: Key.displayNextPrayer)
      enforceVisibleMenuBarContent()
      requestRefresh(.display)
    }
  }

  var nextPrayerDisplayType: NextPrayerDisplayType = .timeUntil {
    didSet {
      defaults.set(nextPrayerDisplayType.rawValue, forKey: Key.displayNextPrayerType)
      enforceVisibleMenuBarContent()
      requestRefresh(.display)
    }
  }

  var nextPrayerDisplayName: NextPrayerDisplayName = .full {
    didSet {
      defaults.set(nextPrayerDisplayName.rawValue, forKey: Key.displayNextPrayerName)
      enforceVisibleMenuBarContent()
      requestRefresh(.display)
    }
  }

  var displayIcon: Bool = true {
    didSet {
      defaults.set(displayIcon, forKey: Key.displayIcon)
      enforceVisibleMenuBarContent()
      requestRefresh(.display)
    }
  }

  // MARK: - Location

  var useCurrentLocation: Bool = true {
    didSet {
      defaults.set(useCurrentLocation, forKey: Key.autoLocation)
      requestRefresh(.display)
    }
  }

  var city: String = "Makkah" {
    didSet {
      defaults.set(city, forKey: Key.city)
      requestRefresh(.display)
    }
  }

  var state: String = "" {
    didSet {
      defaults.set(state, forKey: Key.state)
      requestRefresh(.display)
    }
  }

  var country: String = "SA" {
    didSet {
      defaults.set(country, forKey: Key.country)
      requestRefresh(.display)
    }
  }

  var countryName: String = "Saudi Arabia" {
    didSet {
      defaults.set(countryName, forKey: Key.countryName)
      requestRefresh(.display)
    }
  }

  var storedTimeZone: String = "Asia/Riyadh" {
    didSet {
      defaults.set(storedTimeZone, forKey: Key.timeZone)
      requestRefresh(.prayerTimes)
    }
  }

  var latitude: Double = 21.4167 {
    didSet {
      defaults.set(latitude, forKey: Key.latitude)
      requestRefresh(.prayerTimes)
    }
  }

  var longitude: Double = 39.8167 {
    didSet {
      defaults.set(longitude, forKey: Key.longitude)
      requestRefresh(.prayerTimes)
    }
  }

  // MARK: - Calculation

  var methodPreference: MethodPreference = .ummAlQura {
    didSet {
      defaults.set(methodPreference.rawValue, forKey: Key.method)
      requestRefresh(.prayerTimes)
    }
  }

  var madhabPreference: MadhabPreference = .shafi {
    didSet {
      defaults.set(madhabPreference.rawValue, forKey: Key.madhab)
      requestRefresh(.prayerTimes)
    }
  }

  var autoDetectMethod: Bool = true {
    didSet {
      defaults.set(autoDetectMethod, forKey: Key.autoDetectMethod)
      requestRefresh(.prayerTimes)
    }
  }

  var autoDetectHighLatitudeRule: Bool = true {
    didSet {
      defaults.set(autoDetectHighLatitudeRule, forKey: Key.autoDetectHighLatitudeRule)
      requestRefresh(.prayerTimes)
    }
  }

  var highLatitudeRulePreference: HighLatitudeRulePreference = .middleOfTheNight {
    didSet {
      defaults.set(highLatitudeRulePreference.rawValue, forKey: Key.highLatitudeRule)
      requestRefresh(.prayerTimes)
    }
  }

  var customFajrAngle: Double = 18.0 {
    didSet {
      // Adhan twilight angles must be positive - match v2's "save only when > 0"
      // by snapping non-positive input back to the previous value.
      guard customFajrAngle > 0 else {
        customFajrAngle = oldValue > 0 ? oldValue : 18.0
        return
      }
      defaults.set(customFajrAngle, forKey: Key.customFajrAngle)
      requestRefresh(.prayerTimes)
    }
  }

  var customIshaAngle: Double = 17.5 {
    didSet {
      guard customIshaAngle > 0 else {
        customIshaAngle = oldValue > 0 ? oldValue : 17.5
        return
      }
      defaults.set(customIshaAngle, forKey: Key.customIshaAngle)
      requestRefresh(.prayerTimes)
    }
  }

  // MARK: - Adjustments

  var fajrAdjustment: Int = 0 {
    didSet {
      defaults.set(fajrAdjustment, forKey: Key.adjustmentFajr)
      requestRefresh(.prayerTimes)
    }
  }

  var shuruqAdjustment: Int = 0 {
    didSet {
      defaults.set(shuruqAdjustment, forKey: Key.adjustmentShuruq)
      requestRefresh(.prayerTimes)
    }
  }

  var dhuhrAdjustment: Int = 0 {
    didSet {
      defaults.set(dhuhrAdjustment, forKey: Key.adjustmentDhuhr)
      requestRefresh(.prayerTimes)
    }
  }

  var asrAdjustment: Int = 0 {
    didSet {
      defaults.set(asrAdjustment, forKey: Key.adjustmentAsr)
      requestRefresh(.prayerTimes)
    }
  }

  var maghribAdjustment: Int = 0 {
    didSet {
      defaults.set(maghribAdjustment, forKey: Key.adjustmentMaghrib)
      requestRefresh(.prayerTimes)
    }
  }

  var ishaAdjustment: Int = 0 {
    didSet {
      defaults.set(ishaAdjustment, forKey: Key.adjustmentIsha)
      requestRefresh(.prayerTimes)
    }
  }

  // MARK: - Advanced

  var hijriOffset: Int = 0 {
    didSet {
      defaults.set(hijriOffset, forKey: Key.hijriOffset)
      requestRefresh(.display)
    }
  }

  var delayedIshaInRamadan: Bool = true {
    didSet {
      defaults.set(delayedIshaInRamadan, forKey: Key.delayedIshaInRamadan)
      requestRefresh(.prayerTimes)
    }
  }

  var alertVolume: Int = 50 {
    didSet {
      let clamped = max(0, min(alertVolume, 100))
      if alertVolume != clamped {
        alertVolume = clamped
        return
      }

      defaults.set(alertVolume, forKey: Key.alertVolume)
      requestRefresh(.audioRuntime)
    }
  }

  var duaEnabled: Bool = true {
    didSet {
      defaults.set(duaEnabled, forKey: Key.duaEnabled)
      requestRefresh(.audioRuntime)
    }
  }

  var silentMode: Bool = false {
    didSet {
      defaults.set(silentMode, forKey: Key.silentMode)
      // `.prayerTimes` (not just `.display`) because the scheduled notifications'
      // sound is decided at schedule time from `silentMode` - toggling it has to
      // reschedule, not only restyle. `.audioRuntime` stops any playing audio.
      requestRefresh([.prayerTimes, .audioRuntime])
    }
  }

  // MARK: - Notifications

  var jumuahOverrideEnabled: Bool = false {
    didSet {
      defaults.set(jumuahOverrideEnabled, forKey: Key.jumuahOverrideEnabled)
      if jumuahOverrideEnabled {
        seedJumuahConfigIfNeeded()
      }
      requestRefresh(.prayerTimes)
    }
  }

  var notificationSettings: [String: PrayerNotificationConfig] = [:] {
    didSet {
      do {
        let data = try JSONEncoder().encode(notificationSettings)
        defaults.set(data, forKey: Key.notificationSettings)
      } catch {
        AppLog.preferences.error(
          "Failed to encode notificationSettings: \(error.localizedDescription, privacy: .public)")
      }
      requestRefresh(.prayerTimes)
    }
  }

  // MARK: - Localization

  var appLanguage: AppLanguage = .system {
    didSet {
      defaults.set(appLanguage.rawValue, forKey: Key.appLanguage)
      applyAppleLanguagesOverride()
      requestRefresh(.localization)
    }
  }

  /// Mirrors `appLanguage` into the `AppleLanguages` UserDefaults so
  /// `Bundle.main.preferredLocalizations` matches our in-app choice. Drives
  /// system-rendered chrome like the Settings window title (built from
  /// `CFBundleDisplayName` + the system-localized "Settings" word). Takes
  /// effect on next launch; the currently-open Settings window keeps the title
  /// it was created with.
  func applyAppleLanguagesOverride() {
    if let override = appLanguage.appleLanguagesOverride {
      defaults.set(override, forKey: "AppleLanguages")
    } else {
      defaults.removeObject(forKey: "AppleLanguages")
    }
    // Force the change through CFPreferences immediately so any reader that
    // queries the preferences chain on the same run loop sees the new state.
    defaults.synchronize()
  }

  // MARK: - Widget Appearance

  /// Selected widget theme: a preset id ("nocturne", "dawn", …) or "custom".
  /// Like every state-affecting preference, the didSet persists *and* emits its
  /// refresh effect (`.display`) - so tabs never wire this up by hand.
  var widgetThemeID: String = "nocturne" {
    didSet {
      defaults.set(widgetThemeID, forKey: Key.widgetThemeID)
      requestRefresh(.display)
    }
  }
  /// Custom-theme accent (used when `widgetThemeID == "custom"`).
  var widgetCustomAccent: GuidanceColorSpec = GuidanceWidgetTheme.nocturne.dark.accent {
    didSet {
      storeColorSpec(widgetCustomAccent, forKey: Key.widgetCustomAccent)
      requestRefresh(.display)
    }
  }
  /// Custom-theme primary (the next-prayer / countdown color).
  var widgetCustomPrimary: GuidanceColorSpec = GuidanceWidgetTheme.nocturne.dark.primary {
    didSet {
      storeColorSpec(widgetCustomPrimary, forKey: Key.widgetCustomPrimary)
      requestRefresh(.display)
    }
  }
  var widgetCustomBase: GuidanceWidgetBackgroundBase = .midnight {
    didSet {
      defaults.set(widgetCustomBase.rawValue, forKey: Key.widgetCustomBase)
      requestRefresh(.display)
    }
  }
  var widgetAppearance: GuidanceWidgetAppearance = .system {
    didSet {
      defaults.set(widgetAppearance.rawValue, forKey: Key.widgetAppearance)
      requestRefresh(.display)
    }
  }

  /// The theme the widget snapshot should carry, resolved from the selection.
  /// Both the snapshot builder and the in-app live preview read this, so they
  /// render the identical theme.
  var resolvedWidgetTheme: GuidanceWidgetTheme {
    if widgetThemeID == "custom" {
      return .custom(
        accent: widgetCustomAccent, primary: widgetCustomPrimary,
        base: widgetCustomBase, appearance: widgetAppearance)
    }
    return GuidanceWidgetTheme.preset(id: widgetThemeID) ?? .nocturne
  }

  private func storeColorSpec(_ spec: GuidanceColorSpec, forKey key: String) {
    if let data = try? JSONEncoder().encode(spec) { defaults.set(data, forKey: key) }
  }
  private func loadColorSpec(forKey key: String, default fallback: GuidanceColorSpec) -> GuidanceColorSpec {
    guard let data = defaults.data(forKey: key),
      let spec = try? JSONDecoder().decode(GuidanceColorSpec.self, from: data)
    else { return fallback }
    return spec
  }

  // MARK: - Init

  private init() {
    registerDefaults()
    migrateLegacyPreferencesIfNeeded()

    displayNextPrayer = defaults.bool(forKey: Key.displayNextPrayer)
    nextPrayerDisplayType =
      NextPrayerDisplayType(rawValue: defaults.integer(forKey: Key.displayNextPrayerType))
      ?? .timeUntil
    nextPrayerDisplayName =
      NextPrayerDisplayName(rawValue: defaults.integer(forKey: Key.displayNextPrayerName)) ?? .full
    displayIcon = defaults.bool(forKey: Key.displayIcon)

    useCurrentLocation = defaults.bool(forKey: Key.autoLocation)
    city = defaults.string(forKey: Key.city) ?? "Makkah"
    state = defaults.string(forKey: Key.state) ?? ""
    country = defaults.string(forKey: Key.country) ?? "SA"
    countryName = defaults.string(forKey: Key.countryName) ?? "Saudi Arabia"
    storedTimeZone = defaults.string(forKey: Key.timeZone) ?? "Asia/Riyadh"
    latitude = defaults.double(forKey: Key.latitude)
    longitude = defaults.double(forKey: Key.longitude)

    methodPreference =
      MethodPreference(rawValue: defaults.integer(forKey: Key.method)) ?? .ummAlQura
    madhabPreference = MadhabPreference(rawValue: defaults.integer(forKey: Key.madhab)) ?? .shafi
    autoDetectMethod = defaults.bool(forKey: Key.autoDetectMethod)
    autoDetectHighLatitudeRule = defaults.bool(forKey: Key.autoDetectHighLatitudeRule)
    highLatitudeRulePreference =
      HighLatitudeRulePreference(rawValue: defaults.integer(forKey: Key.highLatitudeRule))
      ?? .middleOfTheNight
    customFajrAngle = defaults.double(forKey: Key.customFajrAngle)
    customIshaAngle = defaults.double(forKey: Key.customIshaAngle)

    fajrAdjustment = defaults.integer(forKey: Key.adjustmentFajr)
    shuruqAdjustment = defaults.integer(forKey: Key.adjustmentShuruq)
    dhuhrAdjustment = defaults.integer(forKey: Key.adjustmentDhuhr)
    asrAdjustment = defaults.integer(forKey: Key.adjustmentAsr)
    maghribAdjustment = defaults.integer(forKey: Key.adjustmentMaghrib)
    ishaAdjustment = defaults.integer(forKey: Key.adjustmentIsha)

    hijriOffset = defaults.integer(forKey: Key.hijriOffset)
    delayedIshaInRamadan = defaults.bool(forKey: Key.delayedIshaInRamadan)
    alertVolume = defaults.integer(forKey: Key.alertVolume)
    duaEnabled = defaults.bool(forKey: Key.duaEnabled)
    silentMode = defaults.bool(forKey: Key.silentMode)

    if let data = defaults.data(forKey: Key.notificationSettings),
      let decoded = try? JSONDecoder().decode([String: PrayerNotificationConfig].self, from: data)
    {
      var resolved = decoded.mapValues { $0.sanitized() }

      for prayer in Prayer.allCases where resolved[prayer.settingsKey] == nil {
        resolved[prayer.settingsKey] = PrayerNotificationConfig.defaultConfig(for: prayer)
      }

      notificationSettings = resolved
    } else {
      notificationSettings = migrateLegacyNotificationSettings().mapValues { $0.sanitized() }
    }

    jumuahOverrideEnabled = defaults.bool(forKey: Key.jumuahOverrideEnabled)
    if jumuahOverrideEnabled {
      seedJumuahConfigIfNeeded()
    }

    appLanguage =
      AppLanguage(rawValue: defaults.string(forKey: Key.appLanguage) ?? "")
      ?? .system
    applyAppleLanguagesOverride()

    widgetThemeID = defaults.string(forKey: Key.widgetThemeID) ?? "nocturne"
    widgetCustomAccent = loadColorSpec(
      forKey: Key.widgetCustomAccent, default: GuidanceWidgetTheme.nocturne.dark.accent)
    widgetCustomPrimary = loadColorSpec(
      forKey: Key.widgetCustomPrimary, default: GuidanceWidgetTheme.nocturne.dark.primary)
    widgetCustomBase =
      GuidanceWidgetBackgroundBase(rawValue: defaults.string(forKey: Key.widgetCustomBase) ?? "")
      ?? .midnight
    widgetAppearance =
      GuidanceWidgetAppearance(rawValue: defaults.string(forKey: Key.widgetAppearance) ?? "")
      ?? .system

    enforceVisibleMenuBarContent()

    // Stored values are loaded; from here, didSets emit refreshes.
    isLoading = false
  }
}
