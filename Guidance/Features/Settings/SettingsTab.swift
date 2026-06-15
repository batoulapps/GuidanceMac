import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
  case general, location, calculation, adjustments, notifications, appearance

  var id: String { rawValue }

  var title: LocalizedStringKey {
    switch self {
    case .general: "settings.tab.general"
    case .location: "settings.tab.location"
    case .calculation: "settings.tab.calculation"
    case .adjustments: "settings.tab.adjustments"
    case .notifications: "settings.tab.notifications"
    case .appearance: "settings.tab.appearance"
    }
  }

  var icon: String {
    switch self {
    case .general: "gearshape.fill"
    case .location: "location.fill"
    case .calculation: "function"
    case .adjustments: "slider.horizontal.3"
    case .notifications: "bell.fill"
    case .appearance: "paintpalette.fill"
    }
  }

  var iconColor: Color {
    switch self {
    case .general: .gray
    case .location: .blue
    case .calculation: .orange
    case .adjustments: .purple
    case .notifications: .red
    case .appearance: .indigo
    }
  }
}
