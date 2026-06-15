import Foundation

/// How a failure should be surfaced. Combined with whether a user is actively
/// *waiting* for the result, this selects the app-wide surfacing policy
/// (see `FailureReporter`).
///
/// - `transient`: retryable (network down/weak, timeouts). Self-heals; never
///   interrupts in the background.
/// - `terminal`: user-actionable, retrying won't help (permission denied or
///   restricted, a deleted file). Always let the user know, but never modally.
/// - `cosmetic`: ignorable (a stale label, `play()` returned false, one missed
///   schedule). Log-only.
enum FailureCategory: Sendable, Equatable {
  case transient
  case terminal
  case cosmetic
}

/// Adopted by each domain's failure enum so the central `FailureReporter` can
/// route any failure uniformly. Value-type enums are `Sendable` for free, which
/// lets a failure cross the `nonisolated` delegate -> main-actor hop that the
/// CoreLocation / AVFoundation / UserNotifications callbacks already perform.
protocol AppFailure: Error, Sendable {
  /// Drives the surfacing policy (combined with "is a user waiting?").
  var category: FailureCategory { get }

  /// Localization key, resolved against `Locale.app` only when a message is
  /// actually shown. Carrying a key (not a resolved `String`) keeps the value
  /// locale-agnostic and `Sendable`, and lets it re-localize live on a language
  /// change.
  var messageKey: String.LocalizationValue { get }

  /// Stable, English, non-localized text for the unified log. Never user-facing.
  var logMessage: String { get }

  /// Optional underlying OS/framework error appended to the diagnostic line.
  var underlyingError: (any Error)? { get }
}

extension AppFailure {
  var underlyingError: (any Error)? { nil }

  /// Resolved on demand, on the main actor (`Locale.app` reads `Preferences.shared`).
  @MainActor var localizedMessage: String {
    localizedString(messageKey, locale: .app)
  }
}
