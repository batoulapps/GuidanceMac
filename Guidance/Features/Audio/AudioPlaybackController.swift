import AVFoundation
import Adhan
import AppKit
import Foundation
import OSLog

enum AudioPlaybackSource: Equatable {
  case prayerAlert
  case dua
  case preview
}

struct AudioPlaybackContext: Equatable {
  var prayer: Prayer?
  var source: AudioPlaybackSource
  var slot: PrayerNotificationSoundSlot?
  var prayerTime: Date?
  var prayerAlertOffsetMinutes: Int?

  init(
    prayer: Prayer? = nil,
    source: AudioPlaybackSource,
    slot: PrayerNotificationSoundSlot? = nil,
    prayerTime: Date? = nil,
    prayerAlertOffsetMinutes: Int? = nil
  ) {
    self.prayer = prayer
    self.source = source
    self.slot = slot
    self.prayerTime = prayerTime
    self.prayerAlertOffsetMinutes = prayerAlertOffsetMinutes
  }
}

enum AudioPlaybackResource {
  case url(URL)
  case data(Data)
}

struct AudioPlaybackRequest {
  var resource: AudioPlaybackResource
  var volume: Float
  var context: AudioPlaybackContext

  init(resource: AudioPlaybackResource, volume: Float, context: AudioPlaybackContext) {
    self.resource = resource
    self.volume = volume
    self.context = context
  }

  init(url: URL, volume: Float, context: AudioPlaybackContext) {
    self.init(resource: .url(url), volume: volume, context: context)
  }

  init(data: Data, volume: Float, context: AudioPlaybackContext) {
    self.init(resource: .data(data), volume: volume, context: context)
  }
}

enum AudioPlaybackState: Equatable {
  case idle
  case playing(AudioPlaybackContext)
}

@MainActor @Observable
final class AudioPlaybackController: NSObject, AVAudioPlayerDelegate {
  var state: AudioPlaybackState = .idle {
    didSet {
      guard oldValue != state else { return }
      // Post `self` as the object so observers can scope to a specific
      // controller. The Settings sound-preview uses a separate controller; the
      // widget snapshot must only react to the prayer-alert controller's state.
      NotificationCenter.default.post(name: .guidanceAudioPlaybackStateDidChange, object: self)
    }
  }

  private var audioPlayer: AVAudioPlayer?
  private var currentPlayerID: ObjectIdentifier?
  private var followUpRequest: AudioPlaybackRequest?

  func play(_ request: AudioPlaybackRequest, followUp: AudioPlaybackRequest? = nil) {
    stop()
    ExternalAudioPauser.pauseIfNeeded(for: request.context)

    followUpRequest = followUp
    startPlayback(request)
  }

  func stop() {
    audioPlayer?.delegate = nil
    audioPlayer?.stop()
    clearPlayback()
  }

  func cancelFollowUp() {
    followUpRequest = nil
  }

  func setVolume(_ volume: Float) {
    audioPlayer?.volume = max(0, min(volume, 1))
  }

  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    let playerID = ObjectIdentifier(player)
    Task { @MainActor in
      self.handleFinishedPlaying(playerID: playerID, successfully: flag)
    }
  }

  nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
    let playerID = ObjectIdentifier(player)
    let message = error?.localizedDescription ?? "Unknown decode error"
    Task { @MainActor in
      self.handleDecodeError(message, playerID: playerID)
    }
  }

  @discardableResult
  private func startPlayback(_ request: AudioPlaybackRequest) -> Bool {
    do {
      let player =
        switch request.resource {
        case let .url(url):
          try AVAudioPlayer(contentsOf: url)
        case let .data(data):
          try AVAudioPlayer(data: data)
        }
      player.volume = max(0, min(request.volume, 1))
      player.delegate = self
      player.prepareToPlay()

      audioPlayer = player
      currentPlayerID = ObjectIdentifier(player)

      if player.play() {
        state = .playing(request.context)
        return true
      }

      AppLog.audio.error("Audio player refused to play")
      clearPlayback()
      return false
    } catch {
      AppLog.audio.error(
        "Failed to start audio playback: \(error.localizedDescription, privacy: .public)"
      )
      clearPlayback()
      return false
    }
  }

  private func handleFinishedPlaying(playerID: ObjectIdentifier, successfully: Bool) {
    guard currentPlayerID == playerID else { return }

    guard successfully else {
      AppLog.audio.error("Audio playback finished unsuccessfully")
      clearPlayback()
      return
    }

    guard let nextRequest = followUpRequest else {
      clearPlayback()
      return
    }

    audioPlayer?.delegate = nil
    audioPlayer = nil
    currentPlayerID = nil
    followUpRequest = nil

    startPlayback(nextRequest)
  }

  private func handleDecodeError(_ message: String, playerID: ObjectIdentifier) {
    guard currentPlayerID == playerID else { return }

    AppLog.audio.error("Audio playback decode error: \(message, privacy: .public)")
    clearPlayback()
  }

  private func clearPlayback() {
    audioPlayer?.delegate = nil
    audioPlayer = nil
    currentPlayerID = nil
    followUpRequest = nil
    state = .idle
  }
}

private enum ExternalAudioPauser {
  private static let playbackBundleIdentifiers = [
    "com.apple.Music",
    "com.apple.iTunes",
  ]

  static func pauseIfNeeded(for context: AudioPlaybackContext) {
    guard context.source == .prayerAlert else { return }

    for bundleIdentifier in playbackBundleIdentifiers
    where !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    {
      pause(bundleIdentifier: bundleIdentifier)
    }
  }

  private static func pause(bundleIdentifier: String) {
    let source = "tell application id \"\(bundleIdentifier)\" to pause"
    var scriptError: NSDictionary?
    NSAppleScript(source: source)?.executeAndReturnError(&scriptError)
  }
}
