import Adhan
import Foundation

enum NextPrayerDisplayType: Int {
  case timeUntil = 0
  case timeOfPrayer = 1
  case none = 2
}

enum NextPrayerDisplayName: Int {
  case full = 0
  case abbreviation = 1
  case none = 2
}

enum MadhabPreference: Int {
  case shafi = 0
  case hanafi = 1
}

enum MethodPreference: Int, CaseIterable {
  case egyptian = 0
  case karachi = 1
  case northAmerica = 2
  case muslimWorldLeague = 3
  case ummAlQura = 4
  case gulf = 5
  case moonsightingCommittee = 6
  case custom = 7
  case kuwait = 8
  case qatar = 9
  case singapore = 10
  case tehran = 11

  var adhanMethod: CalculationMethod {
    switch self {
    case .egyptian: .egyptian
    case .karachi: .karachi
    case .northAmerica: .northAmerica
    case .muslimWorldLeague: .muslimWorldLeague
    case .ummAlQura: .ummAlQura
    case .gulf: .dubai
    case .moonsightingCommittee: .moonsightingCommittee
    case .custom: .other
    case .kuwait: .kuwait
    case .qatar: .qatar
    case .singapore: .singapore
    case .tehran: .tehran
    }
  }

  static func detect(forCountry country: String) -> MethodPreference {
    switch country {
    case "EG", "SD", "SS", "LY", "DZ", "LB", "SY", "IL", "MA", "PS", "IQ", "TR", "MY":
      .egyptian
    case "PK", "IN", "BD", "AF", "JO":
      .karachi
    case "SA":
      .ummAlQura
    case "AE":
      .gulf
    case "US", "CA", "UK", "GB":
      .moonsightingCommittee
    case "KW":
      .kuwait
    case "BH", "OM", "YE", "QA":
      .qatar
    case "SG":
      .singapore
    case "IR":
      .tehran
    default:
      .muslimWorldLeague
    }
  }
}

enum HighLatitudeRulePreference: Int {
  case middleOfTheNight = 0
  case seventhOfTheNight = 1
  case twilightAngle = 2

  var adhanRule: HighLatitudeRule {
    switch self {
    case .middleOfTheNight: .middleOfTheNight
    case .seventhOfTheNight: .seventhOfTheNight
    case .twilightAngle: .twilightAngle
    }
  }
}
