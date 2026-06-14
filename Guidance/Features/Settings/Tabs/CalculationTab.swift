import SwiftUI

struct CalculationContent: View {
  @Bindable var prefs = Preferences.shared

  var body: some View {
    Section("settings.calc.method") {
      Toggle("settings.calc.autoDetect", isOn: $prefs.autoDetectMethod)

      Picker("settings.calc.methodPicker", selection: $prefs.methodPreference) {
        Text("settings.calc.method.egyptian").tag(MethodPreference.egyptian)
        Text("settings.calc.method.karachi").tag(MethodPreference.karachi)
        Text("settings.calc.method.northAmerica").tag(MethodPreference.northAmerica)
        Text("settings.calc.method.mwl").tag(MethodPreference.muslimWorldLeague)
        Text("settings.calc.method.ummAlQura").tag(MethodPreference.ummAlQura)
        Text("settings.calc.method.gulf").tag(MethodPreference.gulf)
        Text("settings.calc.method.moonsighting").tag(MethodPreference.moonsightingCommittee)
        Text("settings.calc.method.kuwait").tag(MethodPreference.kuwait)
        Text("settings.calc.method.qatar").tag(MethodPreference.qatar)
        Text("settings.calc.method.singapore").tag(MethodPreference.singapore)
        Text("settings.calc.method.tehran").tag(MethodPreference.tehran)
        Text("settings.calc.method.custom").tag(MethodPreference.custom)
      }
      .disabled(prefs.autoDetectMethod)
    }
    // Refreshes are emitted by the preference didSets; these only run the extra
    // auto-detect re-derivation when the toggles flip on.
    .onChange(of: prefs.autoDetectMethod) {
      if prefs.autoDetectMethod { prefs.updateAutoDetectedSettings() }
    }
    .onChange(of: prefs.autoDetectHighLatitudeRule) {
      if prefs.autoDetectHighLatitudeRule { prefs.updateAutoDetectedSettings() }
    }

    if prefs.methodPreference == .custom {
      Section("settings.calc.customAngles") {
        HStack {
          Text("settings.calc.fajrAngle")
          Spacer()
          TextField("", value: $prefs.customFajrAngle, format: .number)
            .frame(width: 60)
            .multilineTextAlignment(.trailing)
        }
        HStack {
          Text("settings.calc.ishaAngle")
          Spacer()
          TextField("", value: $prefs.customIshaAngle, format: .number)
            .frame(width: 60)
            .multilineTextAlignment(.trailing)
        }
      }
    }

    Section("settings.calc.madhab") {
      Picker("settings.calc.asrCalc", selection: $prefs.madhabPreference) {
        Text("settings.calc.madhab.shafi").tag(MadhabPreference.shafi)
        Text("settings.calc.madhab.hanafi").tag(MadhabPreference.hanafi)
      }
    }

    Section("settings.calc.highLat") {
      Toggle("settings.calc.highLat.autoDetect", isOn: $prefs.autoDetectHighLatitudeRule)

      Picker("settings.calc.highLat.rule", selection: $prefs.highLatitudeRulePreference) {
        Text("settings.calc.highLat.middle").tag(HighLatitudeRulePreference.middleOfTheNight)
        Text("settings.calc.highLat.seventh").tag(HighLatitudeRulePreference.seventhOfTheNight)
        Text("settings.calc.highLat.twilight").tag(HighLatitudeRulePreference.twilightAngle)
      }
      .disabled(prefs.autoDetectHighLatitudeRule)
    }
  }
}
