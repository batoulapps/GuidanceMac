import Adhan

extension Preferences {
  var calculationMethod: CalculationMethod {
    methodPreference.adhanMethod
  }

  var madhab: Madhab {
    madhabPreference == .hanafi ? .hanafi : .shafi
  }

  var highLatitudeRule: HighLatitudeRule {
    highLatitudeRulePreference.adhanRule
  }
}
