import SwiftUI

// MARK: - Size

/// App-defined widget size, so the shared content views never depend on
/// WidgetKit's `WidgetFamily`. The extension maps `widgetFamily` to this; the
/// in-app preview passes it directly.
nonisolated enum GuidanceWidgetSize: Sendable, Hashable {
  case small
  case medium
  case large
}

// MARK: - Color bridge

nonisolated extension GuidanceColorSpec {
  /// sRGB so the widget and the in-app preview render the identical shade.
  var color: Color {
    Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }
}

/// A theme palette resolved to concrete SwiftUI `Color`s for one appearance.
nonisolated struct GuidanceWidgetColors: Sendable {
  var accent: Color
  var primary: Color
  var backgroundTop: Color
  var backgroundBottom: Color
  var glow: Color
  var isDark: Bool
}

nonisolated extension GuidanceWidgetTheme {
  /// Resolve the calm palette for the current system appearance, honoring the
  /// theme's `appearance` override (Phase 1 themes are always `.system`).
  func colors(for systemScheme: ColorScheme) -> GuidanceWidgetColors {
    let dark: Bool
    switch appearance {
    case .system: dark = systemScheme == .dark
    case .alwaysDark: dark = true
    case .alwaysLight: dark = false
    }
    let p = dark ? self.dark : self.light
    return GuidanceWidgetColors(
      accent: p.accent.color,
      primary: p.primary.color,
      backgroundTop: p.backgroundTop.color,
      backgroundBottom: p.backgroundBottom.color,
      glow: p.glow.color,
      isDark: dark
    )
  }

  /// The color scheme to force when the theme pins an appearance, so the system
  /// colors (`.secondary`, `.primary`) match the themed background; nil = follow
  /// the system.
  var forcedColorScheme: ColorScheme? {
    switch appearance {
    case .system: nil
    case .alwaysDark: .dark
    case .alwaysLight: .light
    }
  }
}

nonisolated extension View {
  /// Apply a forced color scheme when non-nil; otherwise pass through unchanged.
  @ViewBuilder
  func guidanceColorScheme(_ scheme: ColorScheme?) -> some View {
    if let scheme {
      environment(\.colorScheme, scheme)
    } else {
      self
    }
  }
}

// MARK: - Functional tones (fixed, never themed)

nonisolated extension GuidanceWidgetTone {
  // Fixed functional colors - identical across every *theme* by design (a
  // functional color must mean the same thing regardless of theme), but with a
  // dark and a light variant so they keep contrast on every background base. The
  // dark variants are the bright night-backdrop values; the light variants are
  // deepened to stay legible on cream / sand / white.
  static let imminentDark = Color(.sRGB, red: 1.00, green: 0.27, blue: 0.23) // red
  static let imminentLight = Color(.sRGB, red: 0.80, green: 0.12, blue: 0.10)
  static let preReminderDark = Color(.sRGB, red: 1.00, green: 0.62, blue: 0.04) // orange
  static let preReminderLight = Color(.sRGB, red: 0.78, green: 0.42, blue: 0.00)
  static let prayerDark = Color(.sRGB, red: 0.20, green: 0.84, blue: 0.29) // green
  static let prayerLight = Color(.sRGB, red: 0.10, green: 0.52, blue: 0.22)
  static let postReminderDark = Color(.sRGB, red: 0.75, green: 0.35, blue: 0.95) // purple
  static let postReminderLight = Color(.sRGB, red: 0.54, green: 0.20, blue: 0.74)

  /// The adhan / count-up "now" green for the given appearance - used directly
  /// for the count-up badge and current row.
  static func prayerColor(_ colors: GuidanceWidgetColors) -> Color {
    colors.isDark ? prayerDark : prayerLight
  }

  /// The render color for this tone. Only `.normal` is themeable (it is the calm
  /// "primary" / next-prayer color); the functional tones are fixed per-appearance.
  func color(_ colors: GuidanceWidgetColors) -> Color {
    switch self {
    case .normal: return colors.primary
    case .imminent: return colors.isDark ? Self.imminentDark : Self.imminentLight
    case .playingPreReminderAudio: return colors.isDark ? Self.preReminderDark : Self.preReminderLight
    case .playingPrayerAudio: return colors.isDark ? Self.prayerDark : Self.prayerLight
    case .playingPostReminderAudio: return colors.isDark ? Self.postReminderDark : Self.postReminderLight
    case .silent: return .secondary
    }
  }
}

// MARK: - Backdrop

/// Atmospheric widget backdrop: a vertical night/dawn gradient (from the theme)
/// lit by two soft glows - a tone-colored "horizon" that shifts with the prayer
/// state, and a themed accent highlight standing in for the guiding light.
nonisolated struct GuidanceWidgetBackground: View {
  let tone: GuidanceWidgetTone
  let colors: GuidanceWidgetColors
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    let dark = colors.isDark
    ZStack {
      LinearGradient(
        colors: [colors.backgroundTop, colors.backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
      )
      // The soft glows are the "transparency"; flatten to the base gradient when
      // the system asks to reduce transparency.
      if !reduceTransparency {
        RadialGradient(
          colors: [tone.color(colors).opacity(dark ? 0.40 : 0.18), .clear],
          center: .bottomTrailing,
          startRadius: 0,
          endRadius: 320
        )
        RadialGradient(
          colors: [colors.glow.opacity(dark ? 0.13 : 0.08), .clear],
          center: .topLeading,
          startRadius: 0,
          endRadius: 240
        )
      }
    }
  }
}

/// Thin vertical accent hairline dividing the medium widget's two columns.
nonisolated struct GuidanceHairline: View {
  let accent: Color

  var body: some View {
    LinearGradient(
      colors: [.clear, accent.opacity(0.35), .clear],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(width: 1)
  }
}

// MARK: - Micro-components

/// Accent "eyebrow" label (e.g. NEXT PRAYER). Uppercased for editorial weight - a
/// no-op for Arabic, and never letter-spaced, so cursive joining stays intact.
nonisolated struct EyebrowLabel: View {
  let text: String
  let accent: Color
  var muted: Bool = false

  var body: some View {
    Text(verbatim: text)
      .font(.caption2.weight(.semibold))
      .textCase(.uppercase)
      .foregroundStyle(muted ? Color.secondary : accent)
      .lineLimit(1)
  }
}

/// Small uppercase capsule for the "Tomorrow" / "Now" markers - a tinted tag with
/// a hairline border. The tint is supplied by the caller (accent or a tone color).
nonisolated struct InlineBadge: View {
  let text: String
  let tint: Color

  var body: some View {
    Text(verbatim: text)
      .font(.caption2.weight(.semibold))
      .textCase(.uppercase)
      .padding(.horizontal, 7)
      .padding(.vertical, 2)
      .background(Capsule().fill(tint.opacity(0.16)))
      .overlay(Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 0.75))
      .foregroundStyle(tint)
      .lineLimit(1)
  }
}

nonisolated extension View {
  /// Hero surface: a tone-tinted gradient fill with a fine accent-into-tone
  /// hairline, lifting the focus block off the backdrop like an inlay.
  func guidanceHeroCard(toneColor: Color, accent: Color) -> some View {
    background {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [toneColor.opacity(0.24), toneColor.opacity(0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
              LinearGradient(
                colors: [accent.opacity(0.45), toneColor.opacity(0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        )
    }
  }
}
