import Foundation

/// An sRGB color stored as plain components so it round-trips through `Codable`
/// and renders the identical shade in the installed widget and the in-app live
/// preview. The SwiftUI `Color` accessor lives in the design-system file; this
/// type stays Foundation-only so `GuidanceWidgetSnapshot` can carry a theme
/// without importing SwiftUI.
nonisolated struct GuidanceColorSpec: Codable, Equatable, Sendable {
  var red: Double
  var green: Double
  var blue: Double
  var opacity: Double

  init(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) {
    self.red = red
    self.green = green
    self.blue = blue
    self.opacity = opacity
  }
}

// MARK: - Contrast / separation math (pure, for the custom-theme guardrails)

nonisolated extension GuidanceColorSpec {
  /// WCAG relative luminance.
  var relativeLuminance: Double {
    func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    return 0.2126 * lin(red) + 0.7152 * lin(green) + 0.0722 * lin(blue)
  }

  /// WCAG contrast ratio between two colors (1…21).
  static func contrastRatio(_ a: GuidanceColorSpec, _ b: GuidanceColorSpec) -> Double {
    let la = a.relativeLuminance
    let lb = b.relativeLuminance
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  }

  /// Hue-preserving luminance nudge: lighten (on a dark surface) or darken (on a
  /// light one) until this color clears `ratio` against `surface`, or it bottoms
  /// out. Used by "Fix contrast".
  func adjustedForContrast(against surface: GuidanceColorSpec, ratio target: Double = 4.5) -> GuidanceColorSpec {
    if Self.contrastRatio(self, surface) >= target { return self }
    let towardLight = surface.relativeLuminance < 0.5
    var best = self
    for step in 1...20 {
      let t = Double(step) / 20.0
      let candidate = GuidanceColorSpec(
        red + (towardLight ? (1 - red) : -red) * t,
        green + (towardLight ? (1 - green) : -green) * t,
        blue + (towardLight ? (1 - blue) : -blue) * t,
        opacity)
      best = candidate
      if Self.contrastRatio(candidate, surface) >= target { break }
    }
    return best
  }

  /// Rough perceptual distance (0…~1.4) for the functional-hue separation check.
  func distance(to other: GuidanceColorSpec) -> Double {
    let dr = red - other.red, dg = green - other.green, db = blue - other.blue
    return (dr * dr + dg * dg + db * db).squareRoot()
  }
}

/// Whether the widget follows the system appearance or is pinned. Part of the
/// theme so the choice rides in the snapshot; in Phase 1 every theme is `.system`.
nonisolated enum GuidanceWidgetAppearance: String, Codable, Equatable, Sendable {
  case system
  case alwaysDark
  case alwaysLight
}

/// The **calm** palette for one appearance. Only these tokens are themeable; the
/// functional state colors (imminent red, count-up green, the audio tones, stop,
/// silent grey) are fixed constants in the design system and never live here.
nonisolated struct GuidanceWidgetPalette: Codable, Equatable, Sendable {
  /// The brand "guiding light" (brass in Nocturne): hairlines, date glyph, badges, glow.
  var accent: GuidanceColorSpec
  /// The next-prayer / resting color (blue in Nocturne): the countdown + active row.
  var primary: GuidanceColorSpec
  var backgroundTop: GuidanceColorSpec
  var backgroundBottom: GuidanceColorSpec
  var glow: GuidanceColorSpec
}

/// A complete widget theme: the calm tokens for both appearances plus the
/// appearance mode. Resolved app-side and embedded in `GuidanceWidgetSnapshot`;
/// the widget reads it verbatim. Functional colors are deliberately absent (see
/// `GuidanceWidgetTone` in the design system) so they can never drift per theme.
nonisolated struct GuidanceWidgetTheme: Codable, Equatable, Sendable {
  /// Preset identifier (e.g. "nocturne") or "custom".
  var id: String
  var appearance: GuidanceWidgetAppearance
  var dark: GuidanceWidgetPalette
  var light: GuidanceWidgetPalette

  /// The default look (today's "Nocturne": brass accent, blue primary, midnight
  /// base in dark / warm dawn base in light). Phase-1 snapshots resolve to this;
  /// Phase 2's Appearance tab swaps in the user's choice through the same field.
  static let nocturne = GuidanceWidgetTheme(
    id: "nocturne",
    appearance: .system,
    dark: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.88, 0.69, 0.29),          // brass
      primary: GuidanceColorSpec(0.04, 0.52, 1.00),         // blue
      backgroundTop: GuidanceColorSpec(0.075, 0.094, 0.180),
      backgroundBottom: GuidanceColorSpec(0.027, 0.035, 0.078),
      glow: GuidanceColorSpec(0.88, 0.69, 0.29)             // brass glow
    ),
    light: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.62, 0.45, 0.12),          // deeper brass for contrast
      primary: GuidanceColorSpec(0.00, 0.40, 0.85),         // deeper blue, readable on cream
      backgroundTop: GuidanceColorSpec(0.992, 0.976, 0.945),
      backgroundBottom: GuidanceColorSpec(0.953, 0.925, 0.875),
      glow: GuidanceColorSpec(0.88, 0.69, 0.29)
    )
  )

  /// Warm "Dawn": sand base, gold accent, soft-teal primary. A light-first mood.
  static let dawn = GuidanceWidgetTheme(
    id: "dawn",
    appearance: .system,
    dark: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.85, 0.62, 0.30),
      primary: GuidanceColorSpec(0.32, 0.64, 0.68),
      backgroundTop: GuidanceColorSpec(0.16, 0.13, 0.11),
      backgroundBottom: GuidanceColorSpec(0.09, 0.07, 0.055),
      glow: GuidanceColorSpec(0.85, 0.62, 0.30)
    ),
    light: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.66, 0.44, 0.12),
      primary: GuidanceColorSpec(0.00, 0.44, 0.50),
      backgroundTop: GuidanceColorSpec(0.992, 0.952, 0.890),
      backgroundBottom: GuidanceColorSpec(0.968, 0.910, 0.820),
      glow: GuidanceColorSpec(0.85, 0.62, 0.30)
    )
  )

  /// "Oasis": midnight base, emerald accent, teal-blue primary.
  static let oasis = GuidanceWidgetTheme(
    id: "oasis",
    appearance: .system,
    dark: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.20, 0.74, 0.58),
      primary: GuidanceColorSpec(0.18, 0.62, 0.80),
      backgroundTop: GuidanceColorSpec(0.05, 0.11, 0.11),
      backgroundBottom: GuidanceColorSpec(0.02, 0.05, 0.05),
      glow: GuidanceColorSpec(0.20, 0.74, 0.58)
    ),
    light: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.00, 0.50, 0.40),
      primary: GuidanceColorSpec(0.00, 0.42, 0.60),
      backgroundTop: GuidanceColorSpec(0.930, 0.972, 0.962),
      backgroundBottom: GuidanceColorSpec(0.860, 0.930, 0.912),
      glow: GuidanceColorSpec(0.20, 0.74, 0.58)
    )
  )

  /// "Ink": graphite base, near-monochrome - a cool slate primary + brass whisper.
  static let ink = GuidanceWidgetTheme(
    id: "ink",
    appearance: .system,
    dark: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.72, 0.64, 0.48),
      primary: GuidanceColorSpec(0.62, 0.67, 0.76),
      backgroundTop: GuidanceColorSpec(0.13, 0.13, 0.15),
      backgroundBottom: GuidanceColorSpec(0.07, 0.07, 0.085),
      glow: GuidanceColorSpec(0.72, 0.64, 0.48)
    ),
    light: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.42, 0.37, 0.28),
      primary: GuidanceColorSpec(0.30, 0.35, 0.44),
      backgroundTop: GuidanceColorSpec(0.962, 0.962, 0.972),
      backgroundBottom: GuidanceColorSpec(0.900, 0.900, 0.920),
      glow: GuidanceColorSpec(0.42, 0.37, 0.28)
    )
  )

  /// "High Contrast": near-black/white base with a color-blind-safe yellow accent
  /// + blue primary. A deliberate look that complements honoring the system
  /// Increase-Contrast setting (which boosts whatever theme is active).
  static let highContrast = GuidanceWidgetTheme(
    id: "highContrast",
    appearance: .system,
    dark: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(1.00, 0.84, 0.00),
      primary: GuidanceColorSpec(0.35, 0.70, 1.00),
      backgroundTop: GuidanceColorSpec(0.04, 0.04, 0.05),
      backgroundBottom: GuidanceColorSpec(0.00, 0.00, 0.00),
      glow: GuidanceColorSpec(1.00, 0.84, 0.00)
    ),
    light: GuidanceWidgetPalette(
      accent: GuidanceColorSpec(0.50, 0.38, 0.00),
      primary: GuidanceColorSpec(0.00, 0.32, 0.80),
      backgroundTop: GuidanceColorSpec(1.00, 1.00, 1.00),
      backgroundBottom: GuidanceColorSpec(0.95, 0.95, 0.96),
      glow: GuidanceColorSpec(0.50, 0.38, 0.00)
    )
  )

  /// The starter set, in display order. Differ only in the calm palette.
  static let allPresets: [GuidanceWidgetTheme] = [.nocturne, .dawn, .oasis, .ink, .highContrast]

  static func preset(id: String) -> GuidanceWidgetTheme? {
    allPresets.first { $0.id == id }
  }

  /// Build a one-off custom theme: the user-picked accent + primary (applied to
  /// both appearances), a curated background base, and an appearance mode. The
  /// glow follows the accent (the brand "guiding light").
  static func custom(
    accent: GuidanceColorSpec,
    primary: GuidanceColorSpec,
    base: GuidanceWidgetBackgroundBase,
    appearance: GuidanceWidgetAppearance
  ) -> GuidanceWidgetTheme {
    GuidanceWidgetTheme(
      id: "custom",
      appearance: appearance,
      dark: GuidanceWidgetPalette(
        accent: accent, primary: primary,
        backgroundTop: base.darkTop, backgroundBottom: base.darkBottom, glow: accent),
      light: GuidanceWidgetPalette(
        accent: accent, primary: primary,
        backgroundTop: base.lightTop, backgroundBottom: base.lightBottom, glow: accent)
    )
  }
}

/// The curated background moods a custom theme can choose from (never a free
/// color). Each supplies a dark and a light gradient.
nonisolated enum GuidanceWidgetBackgroundBase: String, Codable, Equatable, Sendable, CaseIterable {
  case midnight
  case sand
  case graphite

  var darkTop: GuidanceColorSpec {
    switch self {
    case .midnight: GuidanceColorSpec(0.075, 0.094, 0.180)
    case .sand: GuidanceColorSpec(0.16, 0.13, 0.11)
    case .graphite: GuidanceColorSpec(0.13, 0.13, 0.15)
    }
  }
  var darkBottom: GuidanceColorSpec {
    switch self {
    case .midnight: GuidanceColorSpec(0.027, 0.035, 0.078)
    case .sand: GuidanceColorSpec(0.09, 0.07, 0.055)
    case .graphite: GuidanceColorSpec(0.07, 0.07, 0.085)
    }
  }
  var lightTop: GuidanceColorSpec {
    switch self {
    case .midnight: GuidanceColorSpec(0.992, 0.976, 0.945)
    case .sand: GuidanceColorSpec(0.992, 0.952, 0.890)
    case .graphite: GuidanceColorSpec(0.962, 0.962, 0.972)
    }
  }
  var lightBottom: GuidanceColorSpec {
    switch self {
    case .midnight: GuidanceColorSpec(0.953, 0.925, 0.875)
    case .sand: GuidanceColorSpec(0.968, 0.910, 0.820)
    case .graphite: GuidanceColorSpec(0.900, 0.900, 0.920)
    }
  }
}
