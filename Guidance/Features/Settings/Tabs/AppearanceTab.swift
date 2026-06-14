import AppKit
import SwiftUI

/// The Appearance tab: themes the calm look of the widgets (accent, primary,
/// background) via presets or a guard-railed custom theme, with a live preview
/// rendered from the same shared components the widget uses.
struct AppearanceContent: View {
  @Bindable var prefs = Preferences.shared
  @Environment(\.colorScheme) private var settingsScheme
  @State private var previewSize: GuidanceWidgetSize = .medium
  @State private var showCustomize = false

  var body: some View {
    Section {
      preview
    } header: {
      Text("settings.appearance.preview")
    }

    Section("settings.appearance.theme") {
      presetRow
    }

    Section {
      DisclosureGroup(isExpanded: $showCustomize) {
        customControls
      } label: {
        Text("settings.appearance.customize")
      }
    }
    .onChange(of: showCustomize) { _, expanded in
      seedCustomFromPresetIfNeeded(expanded)
    }
  }

  // MARK: Live preview

  private var preview: some View {
    VStack(spacing: 12) {
      WidgetPreviewContainer(snapshot: previewSnapshot, size: previewSize)
        .frame(maxWidth: .infinity)
      Picker("settings.appearance.size", selection: $previewSize) {
        Text("settings.appearance.size.small").tag(GuidanceWidgetSize.small)
        Text("settings.appearance.size.medium").tag(GuidanceWidgetSize.medium)
        Text("settings.appearance.size.large").tag(GuidanceWidgetSize.large)
      }
      .pickerStyle(.segmented)
      .labelsHidden()
    }
    .padding(.vertical, 6)
  }

  /// The user's current published snapshot (real prayer times + language),
  /// re-themed with the in-progress selection so the preview matches the
  /// installed widget exactly. Falls back to sample data before the first
  /// publish. The static-time flag keeps its countdown calm.
  private var previewSnapshot: GuidanceWidgetSnapshot {
    var snapshot = GuidanceWidgetStore.loadSnapshot() ?? .sample()
    snapshot.theme = prefs.resolvedWidgetTheme
    return snapshot
  }

  // MARK: Presets

  private var presetRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(GuidanceWidgetTheme.allPresets, id: \.id) { theme in
          PresetSwatch(
            theme: theme,
            name: Self.presetName(theme.id),
            isSelected: prefs.widgetThemeID == theme.id
          ) {
            prefs.widgetThemeID = theme.id
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  // MARK: Customize

  @ViewBuilder
  private var customControls: some View {
    ColorPicker("settings.appearance.accent", selection: accentBinding, supportsOpacity: false)
    if accentTooClose { warningRow("settings.appearance.hueWarning") }

    ColorPicker("settings.appearance.primary", selection: primaryBinding, supportsOpacity: false)
    if primaryTooClose { warningRow("settings.appearance.hueWarning") }
    if isCustom, primaryContrast < 3.0 {  // WCAG AA large-text floor for the big countdown
      HStack(spacing: 8) {
        Label("settings.appearance.contrastWarning", systemImage: "exclamationmark.triangle.fill")
          .font(.caption)
          .foregroundStyle(.orange)
        Spacer(minLength: 8)
        Button("settings.appearance.fixContrast") { fixPrimaryContrast() }
          .font(.caption)
          .buttonStyle(.borderless)
      }
    }

    Picker("settings.appearance.background", selection: baseBinding) {
      Text("settings.appearance.base.midnight").tag(GuidanceWidgetBackgroundBase.midnight)
      Text("settings.appearance.base.sand").tag(GuidanceWidgetBackgroundBase.sand)
      Text("settings.appearance.base.graphite").tag(GuidanceWidgetBackgroundBase.graphite)
    }
    Picker("settings.appearance.mode", selection: appearanceBinding) {
      Text("settings.appearance.mode.system").tag(GuidanceWidgetAppearance.system)
      Text("settings.appearance.mode.dark").tag(GuidanceWidgetAppearance.alwaysDark)
      Text("settings.appearance.mode.light").tag(GuidanceWidgetAppearance.alwaysLight)
    }
  }

  private func warningRow(_ key: LocalizedStringKey) -> some View {
    Label(key, systemImage: "exclamationmark.triangle")
      .font(.caption)
      .foregroundStyle(.secondary)
  }

  // MARK: Guardrails

  private var isCustom: Bool { prefs.widgetThemeID == "custom" }

  /// The fixed functional hues a themed color must stay clear of.
  private static let functionalHues: [GuidanceColorSpec] = [
    GuidanceColorSpec(1.00, 0.27, 0.23),  // red
    GuidanceColorSpec(0.20, 0.84, 0.29),  // green
    GuidanceColorSpec(1.00, 0.62, 0.04),  // orange
    GuidanceColorSpec(0.75, 0.35, 0.95),  // purple
  ]
  private func tooClose(_ c: GuidanceColorSpec) -> Bool {
    Self.functionalHues.contains { c.distance(to: $0) < 0.28 }
  }
  private var accentTooClose: Bool { isCustom && tooClose(prefs.widgetCustomAccent) }
  private var primaryTooClose: Bool { isCustom && tooClose(prefs.widgetCustomPrimary) }

  /// The appearance the preview is currently showing.
  private var effectivePreviewScheme: ColorScheme {
    switch prefs.widgetAppearance {
    case .alwaysDark: .dark
    case .alwaysLight: .light
    case .system: settingsScheme
    }
  }
  /// The background the custom primary sits on, for the contrast check (the card
  /// tint is a thin wash over this, so it's a fair approximation of the surface).
  private var previewSurface: GuidanceColorSpec {
    effectivePreviewScheme == .dark ? prefs.widgetCustomBase.darkTop : prefs.widgetCustomBase.lightTop
  }
  private var primaryContrast: Double {
    GuidanceColorSpec.contrastRatio(prefs.widgetCustomPrimary, previewSurface)
  }
  private func fixPrimaryContrast() {
    setCustom { prefs.widgetCustomPrimary = prefs.widgetCustomPrimary.adjustedForContrast(against: previewSurface) }
  }

  private var accentBinding: Binding<Color> {
    Binding(
      get: { prefs.widgetCustomAccent.color },
      set: { newValue in setCustom { prefs.widgetCustomAccent = GuidanceColorSpec(color: newValue) } })
  }
  private var primaryBinding: Binding<Color> {
    Binding(
      get: { prefs.widgetCustomPrimary.color },
      set: { newValue in setCustom { prefs.widgetCustomPrimary = GuidanceColorSpec(color: newValue) } })
  }
  private var baseBinding: Binding<GuidanceWidgetBackgroundBase> {
    Binding(
      get: { prefs.widgetCustomBase },
      set: { newValue in setCustom { prefs.widgetCustomBase = newValue } })
  }
  private var appearanceBinding: Binding<GuidanceWidgetAppearance> {
    Binding(
      get: { prefs.widgetAppearance },
      set: { newValue in setCustom { prefs.widgetAppearance = newValue } })
  }

  /// Editing any custom control activates the custom theme. Batched so the color
  /// edit and the "custom" selection coalesce into a single widget refresh (each
  /// preference's didSet emits `.display`).
  private func setCustom(_ mutate: () -> Void) {
    prefs.batchUpdates {
      mutate()
      prefs.widgetThemeID = "custom"
    }
  }

  /// Opening Customize while on a preset seeds the wells from that preset, so the
  /// user starts from the current look.
  private func seedCustomFromPresetIfNeeded(_ expanded: Bool) {
    guard expanded, prefs.widgetThemeID != "custom",
      let preset = GuidanceWidgetTheme.preset(id: prefs.widgetThemeID)
    else { return }
    prefs.widgetCustomAccent = preset.dark.accent
    prefs.widgetCustomPrimary = preset.dark.primary
  }

  /// Preset display names are untranslated proper nouns.
  static func presetName(_ id: String) -> String {
    switch id {
    case "nocturne": "Nocturne"
    case "dawn": "Dawn"
    case "oasis": "Oasis"
    case "ink": "Ink"
    case "highContrast": "High Contrast"
    default: id.capitalized
    }
  }
}

// MARK: - Preset swatch

private struct PresetSwatch: View {
  let theme: GuidanceWidgetTheme
  let name: String
  let isSelected: Bool
  let action: () -> Void
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let colors = theme.colors(for: scheme)
    Button(action: action) {
      VStack(spacing: 6) {
        ZStack {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
              LinearGradient(
                colors: [colors.backgroundTop, colors.backgroundBottom],
                startPoint: .top, endPoint: .bottom))
          HStack(spacing: 5) {
            Circle().fill(colors.accent).frame(width: 11, height: 11)
            Circle().fill(colors.primary).frame(width: 11, height: 11)
          }
        }
        .frame(width: 60, height: 42)
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .strokeBorder(
              isSelected ? Color.accentColor : Color.secondary.opacity(0.35),
              lineWidth: isSelected ? 2.5 : 1))
        Text(verbatim: name)
          .font(.caption2)
          .foregroundStyle(isSelected ? Color.primary : Color.secondary)
          .lineLimit(1)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(verbatim: name))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

// MARK: - Color bridge (app-side; uses AppKit)

private extension GuidanceColorSpec {
  init(color: Color) {
    let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white.usingColorSpace(.sRGB)!
    self.init(
      Double(ns.redComponent), Double(ns.greenComponent),
      Double(ns.blueComponent), Double(ns.alphaComponent))
  }
}

#Preview("Appearance · dark") {
  Form { AppearanceContent() }
    .formStyle(.grouped)
    .frame(width: 660, height: 480)
    .preferredColorScheme(.dark)
}

#Preview("Appearance · light") {
  Form { AppearanceContent() }
    .formStyle(.grouped)
    .frame(width: 660, height: 480)
    .preferredColorScheme(.light)
}
