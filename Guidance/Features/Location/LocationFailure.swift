import Foundation

/// Why automatic location resolution failed.
///
/// `denied`/`restricted` are terminal - the user must act in System Settings.
/// `network`/`unavailable` are transient: on wake/cold-boot the network stack
/// isn't up yet, so the reverse-geocode fails, but it self-heals once back
/// online. Prayer times never need the network (they use stored coordinates);
/// only the city label does.
enum LocationFailure: AppFailure {
  case denied
  case network
  case restricted
  case unavailable

  var category: FailureCategory {
    switch self {
    case .denied, .restricted: .terminal
    case .network, .unavailable: .transient
    }
  }

  var messageKey: String.LocalizationValue {
    switch self {
    case .denied: "settings.location.error.denied"
    case .network: "settings.location.error.network"
    case .restricted: "settings.location.error.restricted"
    case .unavailable: "settings.location.error.unavailable"
    }
  }

  var logMessage: String {
    switch self {
    case .denied: "Location authorization denied"
    case .network: "Location/geocoder network failure"
    case .restricted: "Location services restricted"
    case .unavailable: "Location unavailable (no placemark)"
    }
  }
}
