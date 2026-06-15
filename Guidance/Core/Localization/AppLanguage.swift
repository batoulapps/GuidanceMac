import Foundation

enum AppLanguage: String, Codable, CaseIterable {
  case system
  case english
  case arabic
  case french
  case urdu
  case indonesian
  case turkish
  case persian
  case bengali
  case malay

  /// Locale used for translation lookup, number formatting, and digit shaping.
  /// Arabic mode explicitly forces the `arab` numbering system because
  /// `Locale(identifier: "ar")` on macOS otherwise defaults to Latin digits in
  /// NumberFormatter output.
  var locale: Locale {
    switch self {
    case .system:
      // Bypass our own app-container `AppleLanguages` override by reading the
      // global preferences scope directly. `Locale.current` caches the
      // process's startup locale and `Locale.preferredLanguages` honours our
      // container override; neither flips back to the real system language
      // when the user toggles to `.system` mid-session.
      if let langs = CFPreferencesCopyValue(
        "AppleLanguages" as CFString,
        kCFPreferencesAnyApplication,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
      ) as? [String], let first = langs.first {
        return Locale(identifier: first)
      }
      return Locale.autoupdatingCurrent
    case .english:
      return Locale(identifier: "en")
    case .arabic:
      var components = Locale.Components(languageCode: .arabic)
      components.numberingSystem = Locale.NumberingSystem("arab")
      return Locale(components: components)
    case .french:
      return Locale(identifier: "fr")
    case .indonesian:
      return Locale(identifier: "id")
    case .turkish:
      return Locale(identifier: "tr")
    case .malay:
      return Locale(identifier: "ms")
    case .urdu:
      return Self.localeWithNumbering("ur", numberingSystem: "arabext")
    case .persian:
      return Self.localeWithNumbering("fa", numberingSystem: "arabext")
    case .bengali:
      return Self.localeWithNumbering("bn", numberingSystem: "beng")
    }
  }

  /// Builds a `Locale` whose `NumberFormatter`/digit shaping uses an explicit
  /// numbering system. Needed because `Locale(identifier:)` on macOS otherwise
  /// emits Latin digits for some languages (e.g. Urdu/Persian default to Latin
  /// unless `arabext` is forced; Bengali to `beng`). Mirrors the `.arabic` case.
  private static func localeWithNumbering(_ code: String, numberingSystem: String) -> Locale {
    var components = Locale.Components(languageCode: Locale.LanguageCode(code))
    components.numberingSystem = Locale.NumberingSystem(numberingSystem)
    return Locale(components: components)
  }

  /// Language identifier(s) for `AppleLanguages` UserDefaults. Setting this
  /// makes `Bundle.main.preferredLocalizations` resolve to the chosen language,
  /// which is what drives the macOS Settings window title (built from
  /// `CFBundleDisplayName` + system-localized "Settings"). Returns `nil` for
  /// `.system` so the OS picks based on user's global language order.
  var appleLanguagesOverride: [String]? {
    switch self {
    case .system: return nil
    case .english: return ["en"]
    case .arabic: return ["ar"]
    case .french: return ["fr"]
    case .urdu: return ["ur"]
    case .indonesian: return ["id"]
    case .turkish: return ["tr"]
    case .persian: return ["fa"]
    case .bengali: return ["bn"]
    case .malay: return ["ms"]
    }
  }
}

// MARK: - Display helpers

extension AppLanguage {
  /// All concrete language cases (excludes `.system`). Source of truth the
  /// picker iterates over so adding a new language is a single enum case.
  static var concreteCases: [AppLanguage] {
    AppLanguage.allCases.filter { $0 != .system }
  }

  /// ISO language code for concrete languages. Used as a search token and to
  /// resolve display names via `Locale.localizedString(forLanguageCode:)`.
  var languageCode: String? {
    switch self {
    case .system: return nil
    case .english: return "en"
    case .arabic: return "ar"
    case .french: return "fr"
    case .urdu: return "ur"
    case .indonesian: return "id"
    case .turkish: return "tr"
    case .persian: return "fa"
    case .bengali: return "bn"
    case .malay: return "ms"
    }
  }

  /// Native name written in the language's own script. Callers handle the
  /// `.system` case separately since its label is localized via the catalog.
  var nativeName: String {
    switch self {
    case .system: return ""
    case .english: return "English"
    case .arabic: return "العربية"
    case .french: return "Français"
    case .urdu: return "اردو"
    case .indonesian: return "Bahasa Indonesia"
    case .turkish: return "Türkçe"
    case .persian: return "فارسی"
    case .bengali: return "বাংলা"
    case .malay: return "Bahasa Melayu"
    }
  }

  /// Two-glyph specimen shown in the picker's language tile (e.g. "Aa", "أب").
  /// Empty for `.system`, which renders a gear icon instead. Sourced here so the
  /// picker stays data-driven as languages are added.
  var glyphText: String {
    switch self {
    case .system: return ""
    case .english: return "Aa"
    case .arabic: return "أب"
    case .french: return "Àé"
    case .urdu: return "اب"
    case .indonesian: return "Ba"
    case .turkish: return "Tü"
    case .persian: return "فا"
    case .bengali: return "অআ"
    case .malay: return "Ba"
    }
  }

  /// Font used to render `glyphText`. Latin-script specimens use Georgia for a
  /// distinct serif look; non-Latin scripts use the system font (which carries
  /// the right shaping). `nil` means the system font.
  var glyphFontName: String? {
    switch self {
    case .english, .french, .indonesian, .turkish, .malay: return "Georgia"
    case .system, .arabic, .urdu, .persian, .bengali: return nil
    }
  }

  /// Catalog key for the caption shown under the option (e.g. "App is in Urdu",
  /// localized into the current UI language). `.system` uses a format-string key
  /// that takes the macOS language name as an argument.
  var captionKey: String {
    "settings.general.language.caption.\(rawValue)"
  }

  /// Language name translated into `displayLocale`. E.g. `.arabic` becomes
  /// "Arabe" in French, "العربية" in Arabic, "Arabic" in English.
  func translatedName(in displayLocale: Locale) -> String {
    guard let code = languageCode else { return nativeName }
    let resolved = displayLocale.localizedString(forLanguageCode: code) ?? code
    return resolved.prefix(1).uppercased() + resolved.dropFirst()
  }

  /// Case-insensitive substring match against native name, translated name,
  /// and raw code. Empty queries match everything.
  func matches(searchQuery: String, in displayLocale: Locale) -> Bool {
    let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return true }
    let needle = trimmed.lowercased()
    let haystack: [String] = [
      nativeName.lowercased(),
      translatedName(in: displayLocale).lowercased(),
      languageCode?.lowercased() ?? "",
      rawValue.lowercased(),
    ]
    return haystack.contains { !$0.isEmpty && $0.contains(needle) }
  }
}
