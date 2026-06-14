import AppKit
import Adhan
import SwiftUI

/// The menu-bar dropdown: a themed "Living Schedule" - header → vertical prayer
/// list where the next prayer expands in place into a hero card → end-of-day
/// Tomorrow card → action footer. Rendered from a live, in-process snapshot built
/// from `PrayerManager`, so it matches the on-screen widget exactly while ticking
/// live and staying interactive (per-prayer alert toggles, Silent, Stop). Replaces
/// the old `PrayerTimesView`. The visual core lives in `MenuDropdownContent`; this
/// root only builds the snapshot and wires the actions.
struct MenuBarDropdownView: View {
  var prayerManager: PrayerManager

  @Environment(\.openSettings) private var openSettings
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    // `.everyMinute` advances the schedule at each minute boundary (so the focus,
    // tones and minute-resolution countdown stay current while the popover is
    // open); the hero's final-minute per-second tick is handled by the system
    // timer primitive inside `MenuLiveCountdown`, with no per-second tree redraw.
    TimelineView(.everyMinute) { context in
      content(now: context.date)
    }
    .onAppear { SettingsOpener.shared.register { openSettings() } }
  }

  @ViewBuilder
  private func content(now: Date) -> some View {
    if let snapshot = prayerManager.currentWidgetSnapshot(now: now) {
      MenuDropdownContent(
        snapshot: snapshot, now: now,
        onToggleAlert: toggleAlert,
        onToggleSilent: toggleSilent,
        onStop: stopAudio,
        onOpenSettings: openSettingsRequested,
        onQuit: { NSApp.terminate(nil) })
    } else {
      noData
    }
  }

  /// No usable prayer times yet (no location / still calculating). Falls back to
  /// the stored theme and surfaces the location notice if there is one.
  private var noData: some View {
    let theme = Preferences.shared.resolvedWidgetTheme
    let colors = theme.colors(for: scheme)
    let message = FailureReporter.shared.currentNotice?.message
      ?? localizedString("settings.location.error.unavailable")
    return ZStack {
      GuidanceWidgetBackground(tone: .normal, colors: colors)
      WidgetMessageContent(
        systemImage: "location.slash",
        message: Text(verbatim: message),
        accent: colors.accent)
    }
    .frame(width: MenuDropdownMetrics.width, height: 200)
    .environment(\.locale, .app)
    .guidanceColorScheme(theme.forcedColorScheme)
  }

  // MARK: - Actions

  /// Flip a prayer's alert. Date-aware so toggling Dhuhr on a Friday edits the
  /// Jumu'ah config, matching the row's displayed name/state. (Sunrise never
  /// reaches here - `MenuDropdownContent` gives it no toggle.)
  private func toggleAlert(_ prayer: GuidanceWidgetPrayer) {
    guard let resolved = Prayer.allCases.first(where: { $0.settingsKey == prayer.id }) else { return }
    let prefs = prayerManager.preferences
    var config = prefs.config(for: resolved, on: prayer.time)
    config.alertEnabled.toggle()
    prefs.setConfig(config, for: resolved, on: prayer.time)
  }

  private func toggleSilent() {
    prayerManager.preferences.silentMode.toggle()
  }

  private func stopAudio() {
    prayerManager.audioPlaybackController.stop()
  }

  private func openSettingsRequested() {
    NSApp.activate(ignoringOtherApps: true)
    openSettings()
  }
}
