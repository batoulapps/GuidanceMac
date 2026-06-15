import Adhan
import Foundation

// MARK: - Per-Prayer Notification Config

struct PrayerNotificationConfig: Codable, Equatable {
  var alertEnabled: Bool
  var alertSound: AdhanSound
  var preReminderEnabled: Bool
  var preReminderOffset: Int
  var preReminderSound: AdhanSound
  var postReminderEnabled: Bool
  var postReminderOffset: Int
  var postReminderSound: AdhanSound

  private enum CodingKeys: String, CodingKey {
    case alertEnabled
    case alertSound
    case preReminderEnabled
    case preReminderOffset
    case preReminderSound
    case postReminderEnabled
    case postReminderOffset
    case postReminderSound
  }

  init(
    alertEnabled: Bool,
    alertSound: AdhanSound,
    preReminderEnabled: Bool,
    preReminderOffset: Int,
    preReminderSound: AdhanSound,
    postReminderEnabled: Bool,
    postReminderOffset: Int,
    postReminderSound: AdhanSound
  ) {
    self.alertEnabled = alertEnabled
    self.alertSound = alertSound
    self.preReminderEnabled = preReminderEnabled
    self.preReminderOffset = Self.clampedOffset(preReminderOffset, fallback: 10)
    self.preReminderSound = preReminderSound
    self.postReminderEnabled = postReminderEnabled
    self.postReminderOffset = Self.clampedOffset(postReminderOffset, fallback: 5)
    self.postReminderSound = postReminderSound
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    alertEnabled = try container.decodeIfPresent(Bool.self, forKey: .alertEnabled) ?? true
    alertSound = try container.decodeIfPresent(AdhanSound.self, forKey: .alertSound) ?? .system

    preReminderEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .preReminderEnabled) ?? false
    preReminderOffset = Self.clampedOffset(
      try container.decodeIfPresent(Int.self, forKey: .preReminderOffset) ?? 10,
      fallback: 10
    )
    preReminderSound =
      try container.decodeIfPresent(AdhanSound.self, forKey: .preReminderSound) ?? .system

    postReminderEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .postReminderEnabled) ?? false
    postReminderOffset = Self.clampedOffset(
      try container.decodeIfPresent(Int.self, forKey: .postReminderOffset) ?? 5,
      fallback: 5
    )
    postReminderSound =
      try container.decodeIfPresent(AdhanSound.self, forKey: .postReminderSound) ?? .system
  }

  static func defaultConfig(for prayer: Prayer) -> PrayerNotificationConfig {
    switch prayer {
    case .fajr:
      return PrayerNotificationConfig(
        alertEnabled: true, alertSound: .fajr,
        preReminderEnabled: false, preReminderOffset: 30, preReminderSound: .system,
        postReminderEnabled: false, postReminderOffset: 5, postReminderSound: .system
      )
    case .sunrise:
      return PrayerNotificationConfig(
        alertEnabled: false, alertSound: .system,
        preReminderEnabled: false, preReminderOffset: 30, preReminderSound: .system,
        postReminderEnabled: false, postReminderOffset: 5, postReminderSound: .system
      )
    default:
      return PrayerNotificationConfig(
        alertEnabled: true, alertSound: .alafasy,
        preReminderEnabled: false, preReminderOffset: 10, preReminderSound: .system,
        postReminderEnabled: false, postReminderOffset: 5, postReminderSound: .system
      )
    }
  }

  func sanitized() -> PrayerNotificationConfig {
    PrayerNotificationConfig(
      alertEnabled: alertEnabled,
      alertSound: alertSound,
      preReminderEnabled: preReminderEnabled,
      preReminderOffset: preReminderOffset,
      preReminderSound: preReminderSound,
      postReminderEnabled: postReminderEnabled,
      postReminderOffset: postReminderOffset,
      postReminderSound: postReminderSound
    )
  }

  static func clampedOffset(_ value: Int, fallback: Int) -> Int {
    guard (1...120).contains(value) else { return fallback }
    return value
  }

  func sound(for slot: PrayerNotificationSoundSlot) -> AdhanSound {
    switch slot {
    case .alert: alertSound
    case .preReminder: preReminderSound
    case .postReminder: postReminderSound
    }
  }

  mutating func setSound(_ sound: AdhanSound, for slot: PrayerNotificationSoundSlot) {
    switch slot {
    case .alert:
      alertSound = sound
    case .preReminder:
      preReminderSound = sound
    case .postReminder:
      postReminderSound = sound
    }
  }
}

enum PrayerNotificationSoundSlot: String, Codable, Hashable {
  case alert
  case preReminder
  case postReminder
}

// MARK: - Sound Options

struct CustomAdhanFile: Codable, Equatable, Hashable {
  var fileName: String
  var bookmarkData: Data

  init(fileName: String, bookmarkData: Data) {
    self.fileName = fileName
    self.bookmarkData = bookmarkData
  }

  init(fileURL: URL) throws {
    self.fileName = fileURL.lastPathComponent
    self.bookmarkData = try fileURL.bookmarkData(
      options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }

  init(legacyBookmarkData: Data) {
    self.bookmarkData = legacyBookmarkData
    self.fileName =
      Self.resolve(bookmarkData: legacyBookmarkData)?.url.lastPathComponent
      ?? "Custom sound"
  }

  func resolvedURL() -> ResolvedCustomAdhanFile? {
    Self.resolve(bookmarkData: bookmarkData)
  }

  private static func resolve(bookmarkData: Data) -> ResolvedCustomAdhanFile? {
    var isStale = false
    guard
      let url = try? URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope, .withoutUI],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
    else {
      return nil
    }
    return ResolvedCustomAdhanFile(url: url, isStale: isStale)
  }
}

struct ResolvedCustomAdhanFile {
  var url: URL
  var isStale: Bool
}

enum BuiltInAdhanSound: String, Codable, CaseIterable, Hashable {
  case alafasy = "Adhan-Alafasy"
  case fajr = "Adhan-Fajr"
  case makkah = "Adhan-Makkah"
  case istanbul = "Adhan-Istanbul"
  case yusuf = "Adhan-Yusuf"
  case aqsa = "Adhan-Aqsa"

  var displayName: String {
    localizedString(localizationKey, locale: .app)
  }

  var fileExtension: String {
    switch self {
    case .alafasy: "m4a"
    case .fajr, .makkah, .istanbul, .yusuf, .aqsa: "mp3"
    }
  }

  var bundledURL: URL? {
    Bundle.main.url(forResource: rawValue, withExtension: fileExtension)
  }

  private var localizationKey: String.LocalizationValue {
    switch self {
    case .alafasy: "sound.alafasy"
    case .fajr: "sound.fajr"
    case .makkah: "sound.makkah"
    case .istanbul: "sound.istanbul"
    case .yusuf: "sound.yusuf"
    case .aqsa: "sound.aqsa"
    }
  }
}

enum AdhanSound: Codable, Equatable, Hashable {
  case builtIn(BuiltInAdhanSound)
  case system
  case none
  case custom(CustomAdhanFile)

  private enum CodingKeys: String, CodingKey {
    case kind
    case builtIn
    case custom
  }

  private enum Kind: String, Codable {
    case builtIn
    case system
    case none
    case custom
  }

  init(from decoder: Decoder) throws {
    let singleValue = try? decoder.singleValueContainer()
    if let rawValue = try? singleValue?.decode(String.self),
      let legacySound = Self.legacySound(rawValue: rawValue)
    {
      self = legacySound
      return
    }

    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .kind) {
    case .builtIn:
      self = .builtIn(try container.decode(BuiltInAdhanSound.self, forKey: .builtIn))
    case .system:
      self = .system
    case .none:
      self = .none
    case .custom:
      self = .custom(try container.decode(CustomAdhanFile.self, forKey: .custom))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .builtIn(sound):
      try container.encode(Kind.builtIn, forKey: .kind)
      try container.encode(sound, forKey: .builtIn)
    case .system:
      try container.encode(Kind.system, forKey: .kind)
    case .none:
      try container.encode(Kind.none, forKey: .kind)
    case let .custom(file):
      try container.encode(Kind.custom, forKey: .kind)
      try container.encode(file, forKey: .custom)
    }
  }

  var displayName: String {
    switch self {
    case let .builtIn(sound): sound.displayName
    case .system: localizedString("sound.system", locale: .app)
    case .none: localizedString("sound.none", locale: .app)
    case let .custom(file): file.fileName
    }
  }

  var bundledURL: URL? {
    guard case let .builtIn(sound) = self else { return nil }
    return sound.bundledURL
  }

  var canPreview: Bool {
    switch self {
    case .system:
      return true
    case .none:
      return false
    case .builtIn:
      return bundledURL != nil
    case let .custom(file):
      guard let resolved = file.resolvedURL() else { return false }
      let didStartAccessing = resolved.url.startAccessingSecurityScopedResource()
      defer {
        if didStartAccessing {
          resolved.url.stopAccessingSecurityScopedResource()
        }
      }
      return (try? resolved.url.checkResourceIsReachable()) == true
    }
  }

  var isCustomUnavailable: Bool {
    if case .custom = self {
      return !canPreview
    }
    return false
  }

  static let alafasy = AdhanSound.builtIn(.alafasy)
  static let fajr = AdhanSound.builtIn(.fajr)
  static let makkah = AdhanSound.builtIn(.makkah)
  static let istanbul = AdhanSound.builtIn(.istanbul)
  static let yusuf = AdhanSound.builtIn(.yusuf)
  static let aqsa = AdhanSound.builtIn(.aqsa)

  static var adhanSounds: [AdhanSound] {
    BuiltInAdhanSound.allCases.map(AdhanSound.builtIn)
  }

  func audioPlaybackResource(refreshCustomFile: ((CustomAdhanFile) -> Void)? = nil)
    -> AudioPlaybackResource?
  {
    switch self {
    case let .builtIn(sound):
      guard let url = sound.bundledURL else { return nil }
      return .url(url)
    case .system, .none:
      return nil
    case let .custom(file):
      guard let resolved = file.resolvedURL() else { return nil }
      let didStartAccessing = resolved.url.startAccessingSecurityScopedResource()
      defer {
        if didStartAccessing {
          resolved.url.stopAccessingSecurityScopedResource()
        }
      }

      if resolved.isStale, let refreshedFile = try? CustomAdhanFile(fileURL: resolved.url) {
        refreshCustomFile?(refreshedFile)
      }

      guard let data = try? Data(contentsOf: resolved.url) else { return nil }
      return .data(data)
    }
  }

  private static func legacySound(rawValue: String) -> AdhanSound? {
    switch rawValue {
    case "system": .system
    case "none": AdhanSound.none
    default:
      BuiltInAdhanSound(rawValue: rawValue).map(AdhanSound.builtIn)
    }
  }
}

// MARK: - Prayer Helpers

extension Prayer {
  static let jumuahSettingsKey = "jumuah"

  var settingsKey: String {
    switch self {
    case .fajr: "fajr"
    case .sunrise: "sunrise"
    case .dhuhr: "dhuhr"
    case .asr: "asr"
    case .maghrib: "maghrib"
    case .isha: "isha"
    }
  }
}
