import SwiftUI

/// The dropdown's themed header: the Hijri date (serif) with the Gregorian date
/// beneath, the guiding-light / silent glyph, and the location. Mirrors the
/// widget's (private) full `WidgetHeader` so the menu bar and widget read alike.
struct MenuDropdownHeader: View {
  let snapshot: GuidanceWidgetSnapshot
  let colors: GuidanceWidgetColors

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 6) {
        Image(systemName: snapshot.silentMode ? "bell.slash.fill" : "moon.stars.fill")
          .font(.subheadline)
          .foregroundStyle(snapshot.silentMode ? Color.secondary : colors.accent)
          .accessibilityHidden(true)
        Text(verbatim: hijriText)
          .font(.system(.headline, design: .serif, weight: .semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        Spacer(minLength: 8)
        Label {
          Text(verbatim: snapshot.locationName).lineLimit(1).privacySensitive()
        } icon: {
          Image(systemName: "location.fill")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
      }
      Text(verbatim: snapshot.gregorianDateText)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .accessibilityElement(children: .combine)
  }

  private var hijriText: String {
    "\(snapshot.hijriDay) \(snapshot.hijriMonth) \(snapshot.hijriYear)"
  }
}
