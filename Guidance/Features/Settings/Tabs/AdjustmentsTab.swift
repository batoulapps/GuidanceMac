import Adhan
import SwiftUI

struct AdjustmentsContent: View {
  @Bindable var prefs = Preferences.shared

  var body: some View {
    Section("settings.adj.hijriHeader") {
      Stepper(
        value: $prefs.hijriOffset,
        in: -3...3
      ) {
        Text(
          String(
            format: localizedString("settings.adj.dateOffset", locale: .app),
            locale: .app,
            prefs.hijriOffset.localizedDigits().bidiIsolated
          )
        )
      }
    }

    if prefs.calculationMethod.params.ishaInterval > 0 {
      Section {
        Toggle("settings.adj.delayedIsha", isOn: $prefs.delayedIshaInRamadan)
      } header: {
        Text("settings.adj.ramadan")
      } footer: {
        Text("settings.adj.delayedIsha.footer")
      }
    }

    Section {
      AdjustmentRow(label: "prayer.fajr", value: $prefs.fajrAdjustment)
      AdjustmentRow(label: "prayer.sunrise", value: $prefs.shuruqAdjustment)
      AdjustmentRow(label: "prayer.dhuhr", value: $prefs.dhuhrAdjustment)
      AdjustmentRow(label: "prayer.asr", value: $prefs.asrAdjustment)
      AdjustmentRow(label: "prayer.maghrib", value: $prefs.maghribAdjustment)
      AdjustmentRow(label: "prayer.isha", value: $prefs.ishaAdjustment)
    } header: {
      Text("settings.adj.offsetsHeader")
    } footer: {
      Text("settings.adj.offsetsFooter")
    }
  }
}
