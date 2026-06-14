import Foundation

@MainActor
extension PrayerManager {
  /// Builds and stores the current widget snapshot. Pass `reload: true` to also
  /// ask WidgetKit to refresh the timeline (use this when state meaningfully
  /// changes - recalculation, audio start/stop, settings/language/location).
  /// Pass `reload: false` for the per-minute tick so the stored snapshot stays
  /// fresh without spending the refresh budget. (The countdown itself is a
  /// static minute-resolution string advanced by the timeline entries, not a
  /// live ticking style - so it never churns seconds on the real widget.)
  func publishWidgetSnapshot(reload: Bool = false) {
    guard
      let snapshot = GuidanceWidgetSnapshotBuilder(
        preferences: preferences,
        prayerTimes: prayerTimes,
        tomorrowPrayerTimes: tomorrowPrayerTimes,
        currentPrayer: currentPrayer,
        nextPrayer: nextPrayer,
        audioState: audioPlaybackController.state
      ).build()
    else { return }

    GuidanceWidgetStore.publishSnapshot(snapshot, reload: reload)
  }

  /// Builds the current widget snapshot from live state for in-app rendering (the
  /// menu-bar dropdown), without publishing to the cross-process store. Returns
  /// nil when there are no prayer times yet (no location / still calculating).
  func currentWidgetSnapshot(now: Date = Date()) -> GuidanceWidgetSnapshot? {
    GuidanceWidgetSnapshotBuilder(
      preferences: preferences,
      prayerTimes: prayerTimes,
      tomorrowPrayerTimes: tomorrowPrayerTimes,
      currentPrayer: currentPrayer,
      nextPrayer: nextPrayer,
      audioState: audioPlaybackController.state,
      now: now
    ).build()
  }
}
