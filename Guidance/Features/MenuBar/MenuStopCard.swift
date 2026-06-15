import SwiftUI

/// Shown in the focus position while an adhan / reminder / du'ā' plays. Unlike the
/// widget's full-panel `WidgetStopContent` (a single Stop intent), the in-process
/// menu bar keeps the schedule visible and offers a real Stop button beside the
/// playing state, tinted by the slot tone.
struct MenuStopCard: View {
  let activeAlert: GuidanceWidgetActiveAlert
  let labels: GuidanceWidgetLabels
  let colors: GuidanceWidgetColors
  let onStop: () -> Void

  private var tone: Color { activeAlert.slot.tone.color(colors) }

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 3) {
        Text(verbatim: activeAlert.title)
          .font(.system(.subheadline, design: .serif, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text(verbatim: activeAlert.subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 8)
      Button(action: onStop) {
        HStack(spacing: 5) {
          Image(systemName: "stop.fill")
          Text(verbatim: labels.stopShort)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(tone.opacity(0.18)))
        .overlay(Capsule().strokeBorder(tone.opacity(0.55), lineWidth: 1))
        .foregroundStyle(tone)
        .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      .menuPointerCursor()
      .accessibilityLabel(Text(verbatim: labels.stopAudio))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .guidanceHeroCard(toneColor: tone, accent: colors.accent)
  }
}
