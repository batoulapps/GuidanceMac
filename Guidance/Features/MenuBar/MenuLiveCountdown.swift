import SwiftUI

/// The hero countdown / count-up, refined for the in-process menu bar. Like the
/// widget's (private) `RelativeTime` it stays calm at minute resolution - a static
/// `RelativeDurationFormatter` string advanced by the dropdown's minute timeline -
/// and drops to Apple's per-second system timer text inside the final minute (and
/// a count-up's first minute), which ticks on its own off the system clock with no
/// re-render of the schedule. Mirrors `RelativeTime` (which is file-private to the
/// widget) using the public `RelativeDurationFormatter`, with one menu-bar tweak:
/// the threshold is `<= 60`, so the minute-aligned timeline entry that lands one
/// minute out already shows the live-ticking final minute instead of a static "1m".
struct MenuLiveCountdown: View {
  /// The prayer time - in the future for a count-down, in the past for a count-up.
  let target: Date
  /// "Now": the dropdown's timeline date, advanced each minute.
  let reference: Date
  let color: Color
  let font: Font
  var bold: Bool = false
  var countingUp: Bool = false

  @Environment(\.locale) private var locale

  var body: some View {
    let magnitude = abs(target.timeIntervalSince(reference))
    Group {
      if magnitude <= 60 {
        // Final minute: Apple's system timer text, the one primitive that ticks
        // per-second on its own. `countsDown` is explicit so direction is exact.
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
        // A minute or more out: the calm, static, timeline-advanced string.
        Text(verbatim: RelativeDurationFormatter.string(
          seconds: magnitude, direction: countingUp ? .up : .down, locale: locale))
      }
    }
    .font(bold ? font.weight(.bold) : font)
    .monospacedDigit()
    .foregroundStyle(color)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
  }
}
