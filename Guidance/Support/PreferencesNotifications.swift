import Foundation

extension Notification.Name {
  /// One or more preferences changed. The `userInfo` carries the union of
  /// `PreferenceRefresh` effects (raw `Int` under `PreferenceRefresh.userInfoKey`).
  /// `PrayerManager` is the sole consumer; it applies the minimum work each
  /// effect requires. Emitted automatically from `Preferences` didSets.
  static let guidancePreferencesDidChange = Notification.Name("guidancePreferencesDidChange")

  static let guidanceAudioPlaybackStateDidChange =
    Notification.Name("guidanceAudioPlaybackStateDidChange")
}

/// What a preference change requires downstream. Each state-affecting preference
/// declares its effects in `Preferences` (right where it persists), so the
/// "does this need a refresh?" decision lives with the data instead of in
/// whichever view happens to toggle it - adding a setting can no longer silently
/// skip a refresh.
struct PreferenceRefresh: OptionSet, Sendable {
  let rawValue: Int

  /// Re-render the widget snapshot + menu bar only (no recompute): menu-bar
  /// format, location label, hijri offset, widget theme.
  static let display = PreferenceRefresh(rawValue: 1 << 0)
  /// Recompute prayer times (calc method / madhab / angles / adjustments /
  /// location / time zone) and reschedule notifications. Implies `display`.
  static let prayerTimes = PreferenceRefresh(rawValue: 1 << 1)
  /// Apply volume / du'ā' / silent to the live audio player.
  static let audioRuntime = PreferenceRefresh(rawValue: 1 << 2)
  /// Language changed: re-geocode the city label in the new locale. Implies
  /// `display` (every widget/menu string is rebuilt from the new language).
  static let localization = PreferenceRefresh(rawValue: 1 << 3)

  static let userInfoKey = "effects"
}

/// Imperative full refresh, for non-preference triggers (e.g. a notification
/// authorization that was just granted). Preference *changes* emit automatically
/// from `Preferences`, so prefer mutating the preference over calling this.
func notifyChange() {
  Preferences.shared.requestRefresh(.prayerTimes)
}

/// Imperative audio-runtime refresh. Kept for symmetry with `notifyChange()`;
/// preference changes that affect audio emit `.audioRuntime` automatically.
func notifyNotificationRuntimePreferenceChange() {
  Preferences.shared.requestRefresh(.audioRuntime)
}
