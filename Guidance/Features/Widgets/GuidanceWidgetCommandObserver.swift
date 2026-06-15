import Foundation

/// Lives in the app. Listens for the Darwin notification posted by the widget's
/// Stop button and runs the supplied stop closure on the main actor. Because the
/// app is guaranteed to be running whenever audio is playing, this is all the
/// "stop" plumbing the widget needs.
@MainActor
final class GuidanceWidgetCommandObserver {
  static let shared = GuidanceWidgetCommandObserver()

  private var isObserving = false
  private var stopAudio: (() -> Void)?
  private var publishWidgetSnapshot: (() -> Void)?

  private init() {}

  func start(stopAudio: @escaping () -> Void, publishWidgetSnapshot: @escaping () -> Void) {
    self.stopAudio = stopAudio
    self.publishWidgetSnapshot = publishWidgetSnapshot
    guard !isObserving else { return }
    isObserving = true

    let observer = Unmanaged.passUnretained(self).toOpaque()
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      observer,
      { _, observer, _, _, _ in
        guard let observer else { return }
        let commandObserver = Unmanaged<GuidanceWidgetCommandObserver>
          .fromOpaque(observer)
          .takeUnretainedValue()
        Task { @MainActor in
          commandObserver.handleStopAudioCommand()
        }
      },
      GuidanceWidgetConstants.stopAudioDarwinNotification as CFString,
      nil,
      .deliverImmediately
    )
  }

  private func handleStopAudioCommand() {
    // Stop on the Darwin notification itself. We deliberately do NOT gate on the
    // App-Group command flag: the widget's intent runs in the *extension*
    // process, so a flag it just wrote isn't reliably visible here yet
    // (cross-process UserDefaults sync lag) - gating on it made Stop silently
    // no-op. The notification name is app-specific, so acting on it is safe; we
    // still clear any pending flag for housekeeping.
    GuidanceWidgetStore.takeStopAudioCommand()
    stopAudio?()
    // Publish after stopping so the app-side snapshot confirms the optimistic
    // extension update and covers stale command delivery.
    publishWidgetSnapshot?()
  }
}
