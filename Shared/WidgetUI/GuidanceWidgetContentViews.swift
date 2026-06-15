import SwiftUI

// MARK: - Tight label style

/// A `Label` layout with a small, fixed icon-title gap. SwiftUI's default
/// `.titleAndIcon` spacing - plus an SF Symbol's own side bearing - reads as a
/// loose, "floating" gap, most visible in RTL. This pins the gap so the glyph
/// hugs its text. Used for every icon + text pairing in the widget chrome.
nonisolated struct TightLabelStyle: LabelStyle {
  var spacing: CGFloat = 3
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: spacing) {
      configuration.icon
      configuration.title
    }
  }
}

nonisolated extension LabelStyle where Self == TightLabelStyle {
  static var tight: TightLabelStyle { TightLabelStyle() }
}

// MARK: - Top-level idle content

/// The idle "living schedule" - the same hierarchy at three densities. Renders
/// purely from a snapshot + size + date, so both the widget extension (idle
/// branch) and the in-app Appearance preview use it unchanged. Setup/stale and
/// the playing/stop state are handled by the extension shell (they need
/// `widgetURL` / `Button(intent:)`), with their content below.
nonisolated struct WidgetContentView: View {
  let snapshot: GuidanceWidgetSnapshot
  let size: GuidanceWidgetSize
  let date: Date
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let colors = snapshot.resolvedTheme.colors(for: scheme)
    switch size {
    case .small: SmallContent(snapshot: snapshot, date: date, colors: colors)
    case .medium: MediumContent(snapshot: snapshot, date: date, colors: colors)
    case .large: LargeContent(snapshot: snapshot, date: date, colors: colors)
    }
  }
}

// MARK: - Header

/// Date + location, on top of every size. `full` shows Hijri day/month/year with
/// the Gregorian date beneath; `compact` drops the year and Gregorian line.
private struct WidgetHeader: View {
  let snapshot: GuidanceWidgetSnapshot
  let colors: GuidanceWidgetColors
  var compact: Bool = false
  var showLocation: Bool = true

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 6) {
        Image(systemName: snapshot.silentMode ? "bell.slash.fill" : "moon.stars.fill")
          .font(compact ? .caption : .subheadline)
          .foregroundStyle(snapshot.silentMode ? Color.secondary : colors.accent)
          // Optically pull the Hijri date toward the glyph: `moon.stars.fill`
          // carries empty side-bearing that otherwise reads as a stray gap.
          .padding(.trailing, -2)
          .accessibilityHidden(true)
        Text(verbatim: hijriText)
          .font(.system(compact ? .subheadline : .headline, design: .serif, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Spacer(minLength: 8)
        if showLocation {
          Label {
            Text(verbatim: snapshot.locationName)
              .lineLimit(1)
              .privacySensitive()
          } icon: {
            Image(systemName: "location.fill")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .labelStyle(.tight)
        }
      }
      if !compact {
        Text(verbatim: snapshot.gregorianDateText)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var hijriText: String {
    compact
      ? "\(snapshot.hijriDay) \(snapshot.hijriMonth)"
      : "\(snapshot.hijriDay) \(snapshot.hijriMonth) \(snapshot.hijriYear)"
  }
}

// MARK: - Relative countdown / count-up

/// Relative time for the focus timer. At a minute or more it is a **static**,
/// minute-resolution string (via `RelativeDurationFormatter`) advanced by the
/// timeline - calm, never the per-second churn of `Text(_, style: .relative)`
/// across a whole hour. Under a minute it switches to Apple's system timer text,
/// the one widget primitive that ticks per-second on its own (no timeline cost);
/// that renders "0:45", not the menu bar's custom "45s". Count-up is prefixed
/// "+". Arabic-Indic digits come from the locale environment the shell installs.
private struct RelativeTime: View {
  /// The prayer time - in the future for a count-down, in the past for a count-up.
  let target: Date
  /// The moment this view represents: the timeline entry's date in the widget,
  /// or "now" in the in-app preview.
  let reference: Date
  let color: Color
  let font: Font
  var bold: Bool = false
  var countingUp: Bool = false
  @Environment(\.locale) private var locale

  var body: some View {
    let remaining = abs(target.timeIntervalSince(reference))
    Group {
      if remaining < 60 {
        // Under a minute: the system timer text the host ticks per-second for
        // free. `countsDown` is set explicitly (not inferred from past/future)
        // so the direction is exact. Renders "0:45".
        if countingUp {
          HStack(spacing: 0) {
            Text(verbatim: "+")
            Text(
              timerInterval: target...target.addingTimeInterval(3600),
              countsDown: false, showsHours: false)
          }
        } else {
          Text(
            timerInterval: reference...max(reference, target),
            countsDown: true, showsHours: false)
        }
      } else {
        // A minute or more: the calm, static, timeline-advanced tier string.
        Text(verbatim: RelativeDurationFormatter.string(
          seconds: remaining, direction: countingUp ? .up : .down, locale: locale))
      }
    }
    .font(bold ? font.weight(.bold) : font)
    .monospacedDigit()
    .foregroundStyle(color)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
  }
}

// MARK: - Schedule row (collapsed)

/// One collapsed prayer: alert bell + name + time. `full` (large) carries an icon
/// and a state background; `compact` (medium) is a light name+time line. The next
/// prayer is toned, the current (count-up) prayer is green, passed prayers dim.
private struct ScheduleRowView: View {
  let prayer: GuidanceWidgetPrayer
  let state: GuidanceWidgetRowState
  let colors: GuidanceWidgetColors
  let nowLabel: String
  var compact: Bool = false
  /// The most-recent-passed "since previous prayer" count-up ("+1:30"), shown on
  /// the trailing edge. Its presence also keeps this row un-dimmed - the "you are
  /// here" anchor between passed and upcoming.
  var sinceText: String? = nil

  var body: some View {
    HStack(spacing: compact ? 6 : 10) {
      if !compact {
        Image(systemName: iconName)
          .font(.subheadline)
          .foregroundStyle(emphasisColor ?? .secondary)
          .frame(width: 20)
          .accessibilityHidden(true)
      }

      Text(verbatim: prayer.name)
        .font(.system(compact ? .subheadline : .body, design: .serif).weight(weight))
        .foregroundStyle(emphasisColor ?? (compact ? .primary : .primary))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(minWidth: compact ? nil : 62, alignment: .leading)

      if isCurrent {
        InlineBadge(text: nowLabel, tint: GuidanceWidgetTone.prayerColor(colors))
      }

      Spacer(minLength: 6)

      // The "since" count-up floats in the gap (between name and time) rather
      // than after the time, so the time stays in the same right-aligned column
      // as every other row instead of being pushed off when this row carries it.
      if let sinceText {
        Text(verbatim: sinceText)
          .font((compact ? Font.caption : Font.subheadline).monospacedDigit())
          .foregroundStyle(GuidanceWidgetTone.prayerColor(colors).opacity(0.9))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .layoutPriority(-1)
        Spacer(minLength: 6)
      }

      Text(verbatim: prayer.timeText)
        .font((compact ? Font.subheadline : Font.body).monospacedDigit())
        .foregroundStyle(timeColor)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(minWidth: compact ? nil : 82, alignment: .trailing)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, compact ? 0 : 10)
    .padding(.vertical, compact ? 0 : 4)
    .background(compact ? AnyView(Color.clear) : AnyView(rowBackground))
    .opacity(state == .passed && sinceText == nil ? (compact ? 0.5 : 0.55) : 1)
    .accessibilityElement(children: .combine)
  }

  private var isCurrent: Bool { state == .current }

  /// Emphasis color for the name (and icon, full only): next→tone, active→tone,
  /// current→green; nil means use the default text color.
  private var emphasisColor: Color? {
    switch state {
    case let .next(tone), let .active(tone): return tone.color(colors)
    case .current: return GuidanceWidgetTone.prayerColor(colors)
    default: return nil
    }
  }

  private var timeColor: Color {
    switch state {
    case let .next(tone): return tone.color(colors)
    case .current: return GuidanceWidgetTone.prayerColor(colors)
    default: return compact ? .secondary : .primary
    }
  }

  private var weight: Font.Weight {
    switch state {
    case .next, .active, .current: return .semibold
    default: return .regular
    }
  }

  private var iconName: String {
    switch state {
    case .active: return "speaker.wave.2.fill"
    // `.forward` auto-mirrors under RTL, unlike `.right`.
    case .next: return "arrowtriangle.forward.fill"
    default:
      if prayer.id == GuidanceWidgetSnapshot.sunriseID { return "sunrise.fill" }
      return prayer.alertEnabled ? "bell.fill" : "bell.slash"
    }
  }

  @ViewBuilder
  private var rowBackground: some View {
    switch state {
    case let .next(tone):
      let c = tone.color(colors)
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(LinearGradient(colors: [c.opacity(0.22), c.opacity(0.08)], startPoint: .leading, endPoint: .trailing))
        .overlay(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .strokeBorder(c.opacity(0.45), lineWidth: 1)
        )
    case let .active(tone):
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(tone.color(colors).opacity(0.20))
    case .current:
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(GuidanceWidgetTone.prayerColor(colors).opacity(0.12))
    default:
      Color.clear
    }
  }
}

// MARK: - Active card (the focus)

/// The expanded focus, in one of three modes: count-down (next prayer),
/// count-up (green, 15 min after a prayer fires), or tomorrow (end-of-day Fajr).
/// Reuses the hero-card surface so the focus reads as inlaid into the backdrop.
private struct ActiveCardView: View {
  let focus: GuidanceWidgetSnapshot.Focus
  let snapshot: GuidanceWidgetSnapshot
  let colors: GuidanceWidgetColors
  let size: GuidanceWidgetSize
  let date: Date
  /// When true (Small), the focus fills the height with the eyebrow pinned to the
  /// top, the name+countdown centered, and the reminder at the bottom - so the
  /// negative space is balanced above and below the focus rather than dumped low.
  var distribute: Bool = false

  private var labels: GuidanceWidgetLabels { snapshot.labels }
  private var prayer: GuidanceWidgetPrayer { focus.prayer }

  private var tone: GuidanceWidgetTone {
    switch focus {
    case .countUp: return .playingPrayerAudio       // green
    case .countdown: return snapshot.tone(at: date) // normal / imminent
    case .tomorrow: return .normal
    }
  }
  private var toneColor: Color { tone.color(colors) }
  private var isImminent: Bool {
    if case .countdown = focus { return tone == .imminent }
    return false
  }
  private var isCountUp: Bool {
    if case .countUp = focus { return true }
    return false
  }

  // Per-size type scale.
  private var nameFont: Font {
    switch size {
    case .small: .system(.title3, design: .serif, weight: .semibold)
    case .medium: .system(.headline, design: .serif, weight: .semibold)
    case .large: .system(.title2, design: .serif, weight: .bold)
    }
  }
  private var timerFont: Font {
    switch size {
    case .small: .title3
    case .medium: .title3
    case .large: .title2
    }
  }

  var body: some View {
    // The hero-card surface (border + tint) only marks the inline expansion on
    // Large. On Small/Medium the focus fills its space directly - no nested box.
    Group {
      if size == .large {
        arranged.padding(12).guidanceHeroCard(toneColor: toneColor, accent: colors.accent)
      } else {
        arranged
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var arranged: some View {
    if distribute {
      VStack(alignment: .leading, spacing: 0) {
        statusLine
        Spacer(minLength: 6)
        VStack(alignment: .leading, spacing: 4) {
          nameRow
          timerRow
        }
        Spacer(minLength: 6)
        reminderRow
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    } else {
      VStack(alignment: .leading, spacing: size == .small ? 3 : 5) {
        statusLine
        nameRow
        timerRow
        reminderRow
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  // MARK: Pieces

  /// Leading indicator: the green "Now" badge (count-up) or the eyebrow.
  @ViewBuilder
  private var statusLine: some View {
    if isCountUp {
      InlineBadge(text: labels.now, tint: GuidanceWidgetTone.prayerColor(colors))
    } else {
      EyebrowLabel(text: eyebrowText, accent: colors.accent)
    }
  }

  /// Name + (on medium/large) the clock time on its trailing edge. Small drops
  /// the clock: at the focus name size there isn't room for both, and the
  /// countdown already conveys the timing - the absolute time lives on the bigger
  /// sizes and the menu bar.
  private var nameRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(verbatim: prayer.name)
        .font(nameFont)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      if size != .small {
        Spacer(minLength: 6)
        Label {
          Text(verbatim: prayer.timeText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        } icon: {
          Image(systemName: "clock")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .labelStyle(.tight)
        .layoutPriority(-1)
      }
    }
  }

  /// The big relative timer (count-down or count-up), tone-colored.
  private var timerRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 5) {
      if isImminent {
        Image(systemName: "exclamationmark.circle.fill")
          .font(timerFont)
          .foregroundStyle(toneColor)
          .accessibilityHidden(true)
      }
      RelativeTime(
        target: prayer.time, reference: date, color: toneColor,
        font: timerFont, bold: isImminent, countingUp: isCountUp)
    }
  }

  /// The always-on "since previous prayer" line for Small ("Dhuhr since: 1:30"),
  /// or nil during a count-up focus / before the day's first prayer. The value is
  /// always >= 15 min (it only shows once the green window ends), so it never hits
  /// the seconds tier and needs no live ticking.
  private var sinceLineText: String? {
    guard !isCountUp, let prev = snapshot.previousPrayer(at: date) else { return nil }
    let elapsed = RelativeDurationFormatter.string(
      seconds: date.timeIntervalSince(prev.time), direction: .up,
      locale: snapshot.resolvedLocale, bidiIsolated: true)
    return "\(prev.name) \(labels.since): \(elapsed)"
  }

  /// The card's subtitle. Small (no schedule) carries the "since previous prayer"
  /// count-up here, in place of the pre/post reminder. Medium/Large keep the
  /// pre/post reminder detail - those sizes show the since count-up on the
  /// schedule row instead (see `ScheduleRowView.sinceText`).
  @ViewBuilder
  private var reminderRow: some View {
    if size == .small {
      if let sinceLineText {
        Label {
          Text(verbatim: sinceLineText).lineLimit(1).minimumScaleFactor(0.7)
        } icon: {
          Image(systemName: "clock.arrow.circlepath")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .labelStyle(.tight)
      }
    } else if !isCountUp, let detail = prayer.reminderDetailText {
      Label {
        Text(verbatim: detail).lineLimit(1).minimumScaleFactor(0.7)
      } icon: {
        Image(systemName: "alarm")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .labelStyle(.tight)
    }
  }

  private var eyebrowText: String {
    switch focus {
    case .tomorrow: return labels.tomorrow
    default: return labels.nextPrayer
    }
  }
}

// MARK: - Small

/// The focus, alone, on a compact header (no room for a schedule).
private struct SmallContent: View {
  let snapshot: GuidanceWidgetSnapshot
  let date: Date
  let colors: GuidanceWidgetColors

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetHeader(snapshot: snapshot, colors: colors, compact: true, showLocation: false)
      if let focus = snapshot.focus(at: date) {
        // Distributed: eyebrow up, name+countdown centered, reminder down.
        ActiveCardView(focus: focus, snapshot: snapshot, colors: colors, size: .small, date: date, distribute: true)
      } else {
        Spacer(minLength: 0)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// MARK: - Medium

/// Focus beside the day: a full-width header on top, then the active card (left)
/// next to the day's schedule (right), split by the accent hairline.
private struct MediumContent: View {
  let snapshot: GuidanceWidgetSnapshot
  let date: Date
  let colors: GuidanceWidgetColors

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetHeader(snapshot: snapshot, colors: colors, compact: true)
      HStack(alignment: .top, spacing: 12) {
        if let focus = snapshot.focus(at: date) {
          // Distribute to fill the pane height, matching the schedule beside it.
          ActiveCardView(focus: focus, snapshot: snapshot, colors: colors, size: .medium, date: date, distribute: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        GuidanceHairline(accent: colors.accent)
        schedule
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var schedule: some View {
    VStack(spacing: 0) {
      ForEach(snapshot.prayers) { prayer in
        ScheduleRowView(
          prayer: prayer,
          state: snapshot.rowState(for: prayer, at: date),
          colors: colors,
          nowLabel: snapshot.labels.now,
          compact: true,
          sinceText: snapshot.sinceText(for: prayer, at: date)
        )
        .frame(maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Large

/// The day, with the focus inside it: a single vertical living schedule where the
/// next prayer's row expands in place into the active card. End-of-day floats the
/// Tomorrow card beneath the (dimmed) day.
private struct LargeContent: View {
  let snapshot: GuidanceWidgetSnapshot
  let date: Date
  let colors: GuidanceWidgetColors

  private var focus: GuidanceWidgetSnapshot.Focus? { snapshot.focus(at: date) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      WidgetHeader(snapshot: snapshot, colors: colors)
      VStack(spacing: 6) {
        ForEach(snapshot.prayers) { prayer in
          if isFocusRow(prayer), let focus {
            ActiveCardView(focus: focus, snapshot: snapshot, colors: colors, size: .large, date: date)
              .layoutPriority(1)
          } else {
            ScheduleRowView(
              prayer: prayer,
              state: snapshot.rowState(for: prayer, at: date),
              colors: colors,
              nowLabel: snapshot.labels.now,
              sinceText: snapshot.sinceText(for: prayer, at: date)
            )
            // Collapsed rows share the leftover height evenly, so the slack is
            // distributed as breathing room between every row instead of dumped
            // beneath the day - which read as a lopsided bottom gap when the
            // focus is the last prayer (Isha). Under the end-of-day overflow they
            // still compress first (priority 0) beneath the priority-1 cards.
            .frame(maxHeight: .infinity)
          }
        }
        // End of day: the focus is tomorrow's Fajr, which is not a today row.
        // The full six-row day plus this card slightly overflows the fixed height;
        // the priority lets the hero keep its natural height while the dimmed,
        // passed rows absorb the deficit (instead of the hero compressing).
        if case .tomorrow(let fajr)? = focus {
          ActiveCardView(
            focus: .tomorrow(fajr), snapshot: snapshot, colors: colors, size: .large, date: date)
            .layoutPriority(1)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// A today row is the focus when it matches the focused prayer (count-up's
  /// current, or count-down's next). Tomorrow never matches a today row.
  private func isFocusRow(_ prayer: GuidanceWidgetPrayer) -> Bool {
    guard let focus else { return false }
    switch focus {
    case .countUp(let p), .countdown(let p):
      return prayer.id == p.id && prayer.time == p.time
    case .tomorrow:
      return false
    }
  }
}

// MARK: - Message (setup / stale) content

/// Centered icon + message used when there is no snapshot yet (setup) or the
/// stored one is stale. The extension shell adds the `widgetURL` to Settings.
nonisolated struct WidgetMessageContent: View {
  let systemImage: String
  let message: Text
  var accent: Color = GuidanceWidgetTheme.nocturne.dark.accent.color

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.title)
        .foregroundStyle(accent)
        .accessibilityHidden(true)
      message
        .font(.callout.weight(.medium))
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Stop control content

/// Shown while an adhan/reminder plays. The whole widget is wrapped in a Stop
/// intent button by the shell, so this presents the playing state as one large
/// "tap to stop" control, sized for the family.
nonisolated struct WidgetStopContent: View {
  let activeAlert: GuidanceWidgetActiveAlert
  let labels: GuidanceWidgetLabels
  let size: GuidanceWidgetSize
  let colors: GuidanceWidgetColors

  private var isSmall: Bool { size == .small }

  var body: some View {
    let tone = activeAlert.slot.tone.color(colors)
    VStack(spacing: isSmall ? 6 : 10) {
      Spacer(minLength: 0)
      Image(systemName: "stop.circle.fill")
        .font(.system(size: isSmall ? 44 : 58))
        .foregroundStyle(tone)
        .accessibilityHidden(true)
      VStack(spacing: 3) {
        Text(verbatim: activeAlert.title)
          .font(.system(isSmall ? .subheadline : .title3, design: .serif, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text(verbatim: activeAlert.subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      Text(verbatim: labels.tapToStop)
        .font(.caption2.weight(.bold))
        .textCase(.uppercase)
        .foregroundStyle(tone)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(verbatim: "\(activeAlert.title). \(labels.tapToStop)"))
  }
}
