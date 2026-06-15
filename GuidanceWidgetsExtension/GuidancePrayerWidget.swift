import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct GuidancePrayerWidgetEntry: TimelineEntry, Sendable {
  let date: Date
  let snapshot: GuidanceWidgetSnapshot
  /// True when no snapshot has ever been published (app not yet run). The views
  /// then show a setup prompt instead of sample data masquerading as real times.
  var isSetupNeeded: Bool = false
}

struct GuidancePrayerWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> GuidancePrayerWidgetEntry {
    GuidancePrayerWidgetEntry(date: Date(), snapshot: .sample())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (GuidancePrayerWidgetEntry) -> Void) {
    // The gallery (preview) always gets sample data; a real install with no
    // published snapshot yet gets an explicit setup prompt, never fake times.
    if context.isPreview {
      completion(GuidancePrayerWidgetEntry(date: Date(), snapshot: .sample()))
    } else if let snapshot = GuidanceWidgetStore.loadSnapshot() {
      completion(GuidancePrayerWidgetEntry(date: Date(), snapshot: snapshot))
    } else {
      completion(GuidancePrayerWidgetEntry(date: Date(), snapshot: .sample(), isSetupNeeded: true))
    }
  }

  func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<GuidancePrayerWidgetEntry>) -> Void) {
    let now = Date()
    guard let snapshot = GuidanceWidgetStore.loadSnapshot() else {
      // No snapshot has ever been written (app not run). Show a setup prompt and
      // retry within the hour; launching the app publishes data and reloads us.
      let entry = GuidancePrayerWidgetEntry(date: now, snapshot: .sample(now: now), isSetupNeeded: true)
      completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(60 * 60))))
      return
    }
    let timeline = snapshot.timeline(from: now)
    let entries = timeline.dates.map { GuidancePrayerWidgetEntry(date: $0, snapshot: snapshot) }
    // Static per-entry strings, so the host won't auto-advance them - regenerate
    // after the dense window to re-densify around the following prayer.
    completion(Timeline(entries: entries, policy: .after(timeline.reload)))
  }
}

// MARK: - Widget

struct GuidancePrayerWidget: Widget {
  var body: some WidgetConfiguration {
    // StaticConfiguration: the components were chosen to be useful with zero
    // setup, so there is no configuration intent.
    StaticConfiguration(
      kind: GuidanceWidgetConstants.prayerTimesWidgetKind,
      provider: GuidancePrayerWidgetProvider()
    ) { entry in
      GuidancePrayerWidgetEntryView(entry: entry)
    }
    .configurationDisplayName(Text("widget.prayerTimes.displayName"))
    .description(Text("widget.prayerTimes.description"))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    // Take over the full widget bounds; each view applies its own padding. The
    // default system content margins double-inset content and were a cause of
    // the large widget's vertical clipping.
    .contentMarginsDisabled()
  }
}

// MARK: - Shell (the only widget-host-dependent layer)

/// The extension shell: it owns everything that needs a widget host - the
/// container background, the deep-link `widgetURL`, and the Stop-intent button -
/// then delegates all rendering to the shared `WidgetUI` content views (which the
/// in-app Appearance preview reuses unchanged).
struct GuidancePrayerWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  let entry: GuidancePrayerWidgetEntry

  private var snapshot: GuidanceWidgetSnapshot { entry.snapshot }
  private var size: GuidanceWidgetSize { family.guidanceSize }

  /// Resolved render locale, re-applying the numbering system that a bare
  /// identifier round-trip drops (Arabic/Urdu/Persian/Bengali digits). See
  /// `GuidanceWidgetSnapshot.resolvedLocale`.
  private var locale: Locale { snapshot.resolvedLocale }

  var body: some View {
    let colors = snapshot.resolvedTheme.colors(for: scheme)
    Group {
      if entry.isSetupNeeded {
        WidgetMessageContent(systemImage: "moon.stars", message: Text("widget.openToSetUp"), accent: colors.accent)
          .widgetURL(GuidanceWidgetConstants.settingsDeepLinkURL)
      } else if snapshot.isStale(at: entry.date) {
        // Stored times are from a day that has already passed (app quit). Prompt
        // to reopen the app rather than render yesterday's schedule as if live.
        WidgetMessageContent(
          systemImage: "arrow.clockwise",
          message: Text(verbatim: snapshot.labels.openToUpdate),
          accent: colors.accent
        )
        .widgetURL(GuidanceWidgetConstants.settingsDeepLinkURL)
      } else if let activeAlert = snapshot.activeAlert {
        // While audio plays, the entire widget is the Stop control: tapping
        // anywhere runs the stop intent. No dedicated button, no Settings link.
        Button(intent: StopGuidanceAudioIntent()) {
          WidgetStopContent(activeAlert: activeAlert, labels: snapshot.labels, size: size, colors: colors)
        }
        .buttonStyle(.plain)
        .invalidatableContent()
      } else {
        WidgetContentView(snapshot: snapshot, size: size, date: entry.date)
          .widgetURL(GuidanceWidgetConstants.settingsDeepLinkURL)
      }
    }
    .environment(\.locale, locale)
    .environment(\.layoutDirection, snapshot.layoutDirectionIsRTL ? .rightToLeft : .leftToRight)
    // Honor a pinned theme appearance (Always Dark/Light) so the system colors
    // match the themed background; .system passes through unchanged.
    .guidanceColorScheme(snapshot.resolvedTheme.forcedColorScheme)
    .containerBackground(for: .widget) {
      GuidanceWidgetBackground(tone: snapshot.backgroundTone(at: entry.date), colors: colors)
    }
  }
}

private extension WidgetFamily {
  /// Maps the WidgetKit family to the app-defined size the shared content uses.
  var guidanceSize: GuidanceWidgetSize {
    switch self {
    case .systemSmall: .small
    case .systemMedium: .medium
    case .systemLarge: .large
    default: .small
    }
  }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
  GuidancePrayerWidget()
} timeline: {
  GuidancePrayerWidgetEntry(date: .now, snapshot: .sample())
}

#Preview("Medium", as: .systemMedium) {
  GuidancePrayerWidget()
} timeline: {
  GuidancePrayerWidgetEntry(date: .now, snapshot: .sample())
}

#Preview("Large", as: .systemLarge) {
  GuidancePrayerWidget()
} timeline: {
  GuidancePrayerWidgetEntry(date: .now, snapshot: .sample())
}
