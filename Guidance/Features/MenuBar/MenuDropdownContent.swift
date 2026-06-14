import SwiftUI

enum MenuDropdownMetrics {
  /// The dropdown width - a touch wider than the old 232pt panel so the serif
  /// schedule and hero read like the large widget, while staying a comfortable
  /// menu-bar popover rather than a desktop widget.
  static let width: CGFloat = 300
}

/// The rendered dropdown for a given snapshot + moment - the previewable visual
/// core shared by the live menu bar and the SwiftUI previews. The root
/// `MenuBarDropdownView` builds the snapshot from `PrayerManager` and supplies the
/// action closures; everything visual lives here.
struct MenuDropdownContent: View {
  let snapshot: GuidanceWidgetSnapshot
  let now: Date
  /// Flip a prayer's alert. The root resolves the `Prayer` and writes the
  /// (Jumu'ah-aware) config; previews pass a no-op.
  var onToggleAlert: (GuidanceWidgetPrayer) -> Void = { _ in }
  var onToggleSilent: () -> Void = {}
  var onStop: () -> Void = {}
  var onOpenSettings: () -> Void = {}
  var onQuit: () -> Void = {}

  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let theme = snapshot.resolvedTheme
    let colors = theme.colors(for: scheme)
    ZStack {
      GuidanceWidgetBackground(tone: snapshot.backgroundTone(at: now), colors: colors)
      VStack(alignment: .leading, spacing: 10) {
        MenuDropdownHeader(snapshot: snapshot, colors: colors)
        schedule(colors: colors)
        if let notice = FailureReporter.shared.currentNotice, notice.category == .terminal {
          noticeRow(notice)
        }
        Rectangle()
          .fill(colors.accent.opacity(0.15))
          .frame(height: 1)
        MenuDropdownFooter(
          snapshot: snapshot, colors: colors,
          onToggleSilent: onToggleSilent, onOpenSettings: onOpenSettings, onQuit: onQuit)
      }
      .padding(.horizontal, 12)
      .padding(.top, 12)
      .padding(.bottom, 10)
    }
    .frame(width: MenuDropdownMetrics.width)
    .environment(\.locale, snapshot.resolvedLocale)
    .environment(\.layoutDirection, snapshot.layoutDirectionIsRTL ? .rightToLeft : .leftToRight)
    .guidanceColorScheme(theme.forcedColorScheme)
  }

  // MARK: - Living schedule

  @ViewBuilder
  private func schedule(colors: GuidanceWidgetColors) -> some View {
    let focus = snapshot.focus(at: now)
    let playing = snapshot.activeAlert
    VStack(spacing: 6) {
      // While audio plays, the Stop control leads in the focus position and every
      // prayer drops to a collapsed row.
      if let playing {
        MenuStopCard(activeAlert: playing, labels: snapshot.labels, colors: colors, onStop: onStop)
      }
      ForEach(snapshot.prayers) { prayer in
        if playing == nil, isFocusRow(prayer, focus: focus), let focus {
          MenuHeroCard(
            focus: focus, snapshot: snapshot, colors: colors, date: now,
            onToggleAlert: toggleClosure(for: focus.prayer))
        } else {
          MenuScheduleRow(
            prayer: prayer, state: snapshot.rowState(for: prayer, at: now),
            colors: colors, labels: snapshot.labels,
            sinceText: snapshot.sinceText(for: prayer, at: now),
            onToggleAlert: toggleClosure(for: prayer))
        }
      }
      // End of day: tomorrow's Fajr is not a today row, so it floats beneath.
      if playing == nil, case .tomorrow(let fajr)? = focus {
        MenuHeroCard(focus: .tomorrow(fajr), snapshot: snapshot, colors: colors, date: now, onToggleAlert: nil)
      }
    }
    .animation(.smooth(duration: 0.3), value: focus?.prayer.id)
  }

  /// A today row is the focus when it matches the focused prayer (count-up's
  /// current, or count-down's next). Tomorrow never matches a today row.
  private func isFocusRow(_ prayer: GuidanceWidgetPrayer, focus: GuidanceWidgetSnapshot.Focus?) -> Bool {
    guard let focus else { return false }
    switch focus {
    case let .countUp(p), let .countdown(p):
      return prayer.id == p.id && prayer.time == p.time
    case .tomorrow:
      return false
    }
  }

  /// The per-row alert toggle, or nil for Sunrise (never alerted).
  private func toggleClosure(for prayer: GuidanceWidgetPrayer) -> (() -> Void)? {
    guard prayer.id != GuidanceWidgetSnapshot.sunriseID else { return nil }
    return { onToggleAlert(prayer) }
  }

  private func noticeRow(_ notice: FailureNotice) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "exclamationmark.triangle.fill").font(.caption)
      Text(verbatim: notice.message)
        .font(.caption)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
    }
    .foregroundStyle(.secondary)
    .padding(.horizontal, 4)
  }
}
