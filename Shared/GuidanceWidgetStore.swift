import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// App Group transport. Two jobs:
/// 1. The app writes the latest `GuidanceWidgetSnapshot`; the widget reads it.
/// 2. The widget's Stop button writes a one-shot command flag and posts a Darwin
///    notification; the running app observes it and stops playback.
///
/// `nonisolated` so `requestStopAudio()` is callable from the widget's
/// `nonisolated` `AppIntent.perform()` even when the app target compiles this
/// file under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
nonisolated enum GuidanceWidgetStore {
  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: GuidanceWidgetConstants.appGroupID)
  }

  // MARK: - Snapshot

  @discardableResult
  static func saveSnapshot(_ snapshot: GuidanceWidgetSnapshot) -> Bool {
    do {
      let data = try JSONEncoder.guidanceWidget.encode(snapshot)
      // No `synchronize()`: Apple documents it as unnecessary, and it can't make a
      // write reach another process any sooner. The extension reading back its own
      // write (the Stop optimistic clear) is immediate in-process; the app->widget
      // hop is mediated by cfprefsd, which a flush would not speed up.
      defaults?.set(data, forKey: GuidanceWidgetConstants.snapshotDefaultsKey)
      return true
    } catch {
      #if DEBUG
      print("GuidanceWidgetStore failed to encode snapshot: \(error)")
      #endif
      return false
    }
  }

  /// Saves the snapshot, and asks WidgetKit to refresh only when `reload` is set
  /// AND the rendered content actually changed. Re-publishing identical content
  /// (per-activation recalculations, the post-stop confirmation the extension's
  /// optimistic write already covered) is skipped on purpose: from a menu-bar
  /// agent the app is not "foreground", so reload requests are deferred and
  /// coalesced by macOS, and firing redundant ones risks the rate limiter
  /// dropping a reload that *does* matter. `generatedAt` is ignored in the
  /// comparison - it is build-time metadata nothing renders.
  static func publishSnapshot(_ snapshot: GuidanceWidgetSnapshot, reload: Bool) {
    let previous = reload ? loadSnapshot() : nil
    guard saveSnapshot(snapshot), reload else { return }
    if let previous, previous.hasSameContent(as: snapshot) { return }
    reloadPrayerTimesWidgetTimelines()
  }

  static func loadSnapshot() -> GuidanceWidgetSnapshot? {
    guard let data = defaults?.data(forKey: GuidanceWidgetConstants.snapshotDefaultsKey) else {
      return nil
    }
    return try? JSONDecoder.guidanceWidget.decode(GuidanceWidgetSnapshot.self, from: data)
  }

  // MARK: - Stop command

  static func requestStopAudio() {
    clearActiveAlertForStop()
    defaults?.set(UUID().uuidString, forKey: GuidanceWidgetConstants.stopAudioCommandDefaultsKey)
    postStopAudioDarwinNotification()
    reloadPrayerTimesWidgetTimelines()
  }

  /// Consumes the pending stop command, if any. Returns `true` when one was set.
  @discardableResult
  static func takeStopAudioCommand() -> Bool {
    guard defaults?.string(forKey: GuidanceWidgetConstants.stopAudioCommandDefaultsKey) != nil else {
      return false
    }
    defaults?.removeObject(forKey: GuidanceWidgetConstants.stopAudioCommandDefaultsKey)
    return true
  }

  static func reloadPrayerTimesWidgetTimelines() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadTimelines(ofKind: GuidanceWidgetConstants.prayerTimesWidgetKind)
    #endif
  }

  private static func clearActiveAlertForStop() {
    guard let snapshot = loadSnapshot() else { return }
    saveSnapshot(snapshot.clearingActiveAlert())
  }

  private static func postStopAudioDarwinNotification() {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(GuidanceWidgetConstants.stopAudioDarwinNotification as CFString),
      nil,
      nil,
      true
    )
  }
}

private extension JSONEncoder {
  nonisolated static var guidanceWidget: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

private extension JSONDecoder {
  nonisolated static var guidanceWidget: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
