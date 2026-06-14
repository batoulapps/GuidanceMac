import AppKit
import SwiftUI

@main
struct GuidanceApp: App {
  @NSApplicationDelegateAdaptor(GuidanceAppDelegate.self) private var appDelegate

  // Run BEFORE @State property initialization so the AppleLanguages override
  // is in place before any Bundle.preferredLocalizations cache forms. This is
  // what makes the macOS Settings window title use the localized
  // CFBundleDisplayName (هداية / Guidance) instead of always English.
  init() {
    if let raw = UserDefaults.standard.string(forKey: "kBAUserDefaultsAppLanguage"),
      let lang = AppLanguage(rawValue: raw),
      let override = lang.appleLanguagesOverride
    {
      UserDefaults.standard.set(override, forKey: "AppleLanguages")
    }
  }

  @State private var prayerManager = PrayerManager()
  @State private var preferences = Preferences.shared

  private var appLocale: Locale {
    preferences.appLanguage.locale
  }

  private var appLayoutDirection: LayoutDirection {
    appLocale.preferredLayoutDirection
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarDropdownView(prayerManager: prayerManager)
        .environment(\.locale, appLocale)
        .environment(\.layoutDirection, appLayoutDirection)
    } label: {
      MenuBarLabel(
        text: prayerManager.statusBarText,
        showIcon: prayerManager.preferences.displayIcon || hasLocationAttention,
        attention: hasLocationAttention,
        tint: menuBarTint,
        layoutDirection: appLayoutDirection
      )
      .background(SettingsOpenerBridge())
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .environment(\.locale, appLocale)
        .environment(\.layoutDirection, appLayoutDirection)
    }
  }

  /// Menu-bar tint for the current state, or `nil` for the normal state. `nil`
  /// keeps the system's default template rendering (the text auto-adapts to a
  /// light or dark menu bar); a non-nil color is drawn explicitly by
  /// `MenuBarLabel`, since `MenuBarExtra` otherwise strips its label's colors.
  private var menuBarTint: Color? {
    switch prayerManager.menuBarStatusTone {
    case .normal: nil
    case .imminent: .red
    case .playingPreReminderAudio: .orange
    case .playingPrayerAudio: .green
    case .playingPostReminderAudio: .purple
    }
  }

  /// A live terminal failure (e.g. location permission denied) badges the
  /// menu-bar icon so the user knows something needs attention - without a modal.
  private var hasLocationAttention: Bool {
    FailureReporter.shared.currentNotice?.category == .terminal
  }
}

/// Receives the widget's tap URL and opens the app's Settings window. A menu-bar
/// (`LSUIElement`) app has no API to open its `MenuBarExtra` popover, so the tap
/// routes to Settings - the app's only window.
final class GuidanceAppDelegate: NSObject, NSApplicationDelegate {
  func application(_ application: NSApplication, open urls: [URL]) {
    guard urls.contains(where: { $0.scheme == GuidanceWidgetConstants.deepLinkScheme }) else { return }
    // Bring the app forward (the tap should steal focus), then open Settings via
    // SwiftUI's `openSettings` action. The AppKit `showSettingsWindow:` selector
    // only *focuses* an existing window - it can't *create* one for this menu-bar
    // app, which is why a tap did nothing while Settings was closed.
    NSApp.activate(ignoringOtherApps: true)
    SettingsOpener.shared.requestOpen()
  }
}

/// Bridges SwiftUI's `openSettings` action to AppKit so the deep-link handler
/// above (which has no SwiftUI environment) can open the Settings scene,
/// creating the window when none is open.
@MainActor
final class SettingsOpener {
  static let shared = SettingsOpener()
  private init() {}

  private var open: (() -> Void)?
  private var hasPendingRequest = false

  /// Registered by `SettingsOpenerBridge` once `openSettings` is available.
  func register(_ action: @escaping () -> Void) {
    open = action
    if hasPendingRequest {
      hasPendingRequest = false
      action()
    }
  }

  /// Opens Settings now if the action is ready, else defers until it registers
  /// (covers a cold launch where the tap arrives before the scene sets up).
  func requestOpen() {
    if let open {
      open()
    } else {
      hasPendingRequest = true
    }
  }
}

/// Zero-size view that captures `openSettings` from a live scene (the menu-bar
/// label, and the popover) into `SettingsOpener`.
private struct SettingsOpenerBridge: View {
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .accessibilityHidden(true)
      .onAppear { SettingsOpener.shared.register { openSettings() } }
  }
}

/// The menu-bar label (icon + status text).
///
/// macOS renders a `MenuBarExtra` label as a monochrome *template*: it discards
/// any SwiftUI foreground color, so the imminent-red / count-up-green tint never
/// reached the menu bar (it stayed default-colored). The original app colored the
/// status item via `NSStatusItem`'s `attributedTitle` + `NSForegroundColorAttribute`;
/// we keep the SwiftUI `MenuBarExtra` (and its popover) and get the same result by
/// rasterizing the tinted label to a **non-template** image with `ImageRenderer`,
/// which the status item then shows in full color.
///
/// The normal (untinted) state stays a plain SwiftUI label, so it keeps the
/// system template behavior and auto-adapts to a light or dark menu bar.
private struct MenuBarLabel: View {
  let text: String
  let showIcon: Bool
  let attention: Bool
  /// Non-nil only for a colored state (imminent / playing); `nil` = normal.
  let tint: Color?
  let layoutDirection: LayoutDirection

  var body: some View {
    if let tint {
      tintedImage(tint)
    } else {
      content(font: nil, color: .primary)
    }
  }

  @ViewBuilder
  private func content(font: Font?, color: Color) -> some View {
    HStack(spacing: 4) {
      if showIcon {
        Image(systemName: "moon.stars")
          .overlay(alignment: .topTrailing) {
            if attention {
              Circle()
                .fill(.orange)
                .frame(width: 5, height: 5)
                .offset(x: 3, y: -2)
            }
          }
      }
      if !text.isEmpty {
        Text(text)
      }
    }
    .font(font)
    .foregroundStyle(color)
    .environment(\.layoutDirection, layoutDirection)
  }

  /// Rasterize the tinted label to a non-template image (see the type comment).
  /// The raster needs an explicit menu-bar font since it leaves the live view
  /// tree; the normal path inherits the system menu-bar font as before.
  private func tintedImage(_ tint: Color) -> some View {
    let renderer = ImageRenderer(
      content: content(font: .system(size: NSFont.menuBarFont(ofSize: 0).pointSize), color: tint)
    )
    renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
    let nsImage = renderer.nsImage
    nsImage?.isTemplate = false
    return Group {
      if let nsImage {
        Image(nsImage: nsImage).renderingMode(.original)
      } else {
        content(font: nil, color: tint)
      }
    }
  }
}
