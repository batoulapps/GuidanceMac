import SwiftUI

extension Locale {
  static var app: Locale {
    Preferences.shared.appLanguage.locale
  }

  var preferredLayoutDirection: LayoutDirection {
    self.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
  }
}

/// Resolves a localization key against the catalog using a specific locale.
///
/// Unlike `String(localized:locale:)`, whose `locale` parameter affects only
/// number/plural formatting, this helper uses `LocalizedStringResource` so the
/// `locale` argument actually swaps which translation is loaded.
func localizedString(_ key: String.LocalizationValue, locale: Locale = .app) -> String {
  String(localized: LocalizedStringResource(key, locale: locale))
}

/// Same as `localizedString(_:locale:)` but for a key only known at runtime -
/// e.g. derived from an `AppLanguage` case via `captionKey`. The key must exist
/// in the catalog; an unknown key resolves to itself (its own text).
func localizedString(dynamicKey key: String, locale: Locale = .app) -> String {
  String(localized: LocalizedStringResource(String.LocalizationValue(stringLiteral: key), locale: locale))
}
