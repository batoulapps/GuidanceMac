import SwiftUI

/// One collapsed prayer in the menu-bar living schedule. Mirrors the widget's
/// (private) `ScheduleRowView` look - alert/state icon + serif name + time, with
/// the next/active tones and the dimmed-passed treatment - but adds the menu-bar
/// interactivity: the leading bell doubles as an alert toggle, and the row lifts on
/// hover. `sinceText` keeps the most-recent-passed row (the "you are here" anchor)
/// un-dimmed.
struct MenuScheduleRow: View {
  let prayer: GuidanceWidgetPrayer
  let state: GuidanceWidgetRowState
  let colors: GuidanceWidgetColors
  let labels: GuidanceWidgetLabels
  var sinceText: String? = nil
  /// Toggles this prayer's alert; nil for prayers that never alert (Sunrise).
  var onToggleAlert: (() -> Void)? = nil

  @State private var hovering = false

  var body: some View {
    HStack(spacing: 10) {
      leadingIcon

      Text(verbatim: prayer.name)
        .font(Font.system(.subheadline, design: .serif).weight(weight))
        .foregroundStyle(emphasisColor ?? .primary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(minWidth: 56, alignment: .leading)

      if state == .current {
        InlineBadge(text: labels.now, tint: GuidanceWidgetTone.prayerColor(colors))
      }

      Spacer(minLength: 6)

      // The "since" count-up floats in the gap so the time stays right-aligned in
      // the same column as every other row.
      if let sinceText {
        Text(verbatim: sinceText)
          .font(Font.footnote.monospacedDigit())
          .foregroundStyle(GuidanceWidgetTone.prayerColor(colors).opacity(0.9))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .layoutPriority(-1)
        Spacer(minLength: 6)
      }

      Text(verbatim: prayer.timeText)
        .font(Font.subheadline.monospacedDigit())
        .foregroundStyle(timeColor)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(minWidth: 70, alignment: .trailing)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(rowBackground)
    .opacity(state == .passed && sinceText == nil ? 0.55 : 1)
    .contentShape(Rectangle())
    .onHover { hovering = $0 }
  }

  // MARK: Leading icon / alert toggle

  @ViewBuilder
  private var leadingIcon: some View {
    if isBellToggle, let onToggleAlert {
      Button(action: onToggleAlert) {
        Image(systemName: prayer.alertEnabled ? "bell.fill" : "bell.slash")
          .font(.footnote)
          .foregroundStyle(bellColor)
          .frame(width: 18, height: 18)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .menuPointerCursor()
      .help(Text(verbatim: alertToggleLabel))
      .accessibilityLabel(Text(verbatim: alertToggleLabel))
      .accessibilityValue(Text(verbatim: prayer.alertEnabled ? labels.alertOn : labels.alertOff))
    } else {
      Image(systemName: stateIconName)
        .font(.footnote)
        .foregroundStyle(emphasisColor ?? .secondary)
        .frame(width: 18)
        .accessibilityHidden(true)
    }
  }

  /// The leading glyph doubles as the alert toggle only when it is the bell (a
  /// default-state, alertable prayer). `.next`/`.active` rows show their state
  /// glyph instead - the hero already carries the focus, and these are rare
  /// secondary rows.
  private var isBellToggle: Bool {
    guard onToggleAlert != nil, prayer.id != GuidanceWidgetSnapshot.sunriseID else { return false }
    switch state {
    case .next, .active: return false
    default: return true
    }
  }

  private var stateIconName: String {
    switch state {
    case .active: return "speaker.wave.2.fill"
    case .next: return "arrowtriangle.forward.fill"  // auto-mirrors under RTL
    default:
      if prayer.id == GuidanceWidgetSnapshot.sunriseID { return "sunrise.fill" }
      return prayer.alertEnabled ? "bell.fill" : "bell.slash"
    }
  }

  private var bellColor: Color {
    if hovering { return .primary }
    return prayer.alertEnabled ? .secondary : Color.secondary.opacity(0.6)
  }

  // MARK: Tones (mirror ScheduleRowView)

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
    default: return .primary
    }
  }

  private var weight: Font.Weight {
    switch state {
    case .next, .active, .current: return .semibold
    default: return .regular
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
            .strokeBorder(c.opacity(0.45), lineWidth: 1))
    case let .active(tone):
      RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tone.color(colors).opacity(0.20))
    case .current:
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(GuidanceWidgetTone.prayerColor(colors).opacity(0.12))
    default:
      if hovering {
        RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(0.06))
      } else {
        Color.clear
      }
    }
  }

  private var alertToggleLabel: String {
    "\(prayer.name) · \(localizedString("settings.notif.alert.toggle"))"
  }
}
