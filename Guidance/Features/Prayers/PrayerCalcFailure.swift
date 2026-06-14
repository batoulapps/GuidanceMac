import Foundation

/// Prayer-time calculation failed for the current coordinates - Adhan's failable
/// init returned nil (e.g. an extreme high latitude with no resolvable transit).
/// Terminal: retrying with the same coordinates won't help; the user needs a
/// different location. Surfaced once, never as a modal.
enum PrayerCalcFailure: AppFailure {
  case timesUnavailable(latitude: Double, longitude: Double)

  var category: FailureCategory { .terminal }

  var messageKey: String.LocalizationValue { "prayer.error.timesUnavailable" }

  var logMessage: String {
    switch self {
    case let .timesUnavailable(lat, lng):
      "PrayerTimes init returned nil for (\(lat), \(lng))"
    }
  }
}
