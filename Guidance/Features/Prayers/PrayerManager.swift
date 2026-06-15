import Adhan
import AppKit
import Foundation
import OSLog

@Observable
final class PrayerManager {
  var yesterdayPrayerTimes: PrayerTimes?
  var prayerTimes: PrayerTimes?
  var tomorrowPrayerTimes: PrayerTimes?
  var currentPrayer: Prayer?
  var nextPrayer: Prayer?
  var statusBarText: String = ""

  let preferences = Preferences.shared
  let locationManager = LocationManager()
  let reachability = ReachabilityMonitor()
  let audioPlaybackController: AudioPlaybackController

  private let alertScheduler: PrayerAlertScheduler
  private var timer: Timer?
  /// A lightweight 1-second timer that refreshes ONLY the menu-bar text while it
  /// shows a sub-minute value (the last minute before a prayer, the first minute
  /// of a count-up). It never touches alerts or the widget snapshot - those stay
  /// on the aligned 60-second `timer` - and it stops itself once the value is no
  /// longer sub-minute, so the per-second cadence lasts only the ~60s it matters.
  private var secondTimer: Timer?
  private var notificationObservers: [NSObjectProtocol] = []
  private var currentDay: DateComponents

  init(audioPlaybackController: AudioPlaybackController = AudioPlaybackController()) {
    self.audioPlaybackController = audioPlaybackController
    alertScheduler = PrayerAlertScheduler(audioPlaybackController: audioPlaybackController)

    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: Preferences.shared.storedTimeZone) ?? .current
    currentDay = cal.dateComponents([.year, .month, .day], from: Date())
    calculatePrayerTimes()
    startTimer()
    observeNotifications()

    GuidanceWidgetCommandObserver.shared.start(
      stopAudio: { [weak self] in
        self?.audioPlaybackController.stop()
      },
      publishWidgetSnapshot: { [weak self] in
        self?.publishWidgetSnapshot(reload: true)
      })

    // When the network returns, re-run any pending reverse-geocode so a stale
    // city label (from a failed geocode while offline) self-heals. Prayer times
    // are unaffected either way - they come from stored coordinates.
    reachability.onBecameSatisfied = { [weak self] in
      self?.locationManager.retryPendingGeocodeOnReconnect()
    }
    reachability.start()

    if preferences.useCurrentLocation {
      locationManager.startUpdating()
    }
  }

  // MARK: - Timer

  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.handleTick()
      }
    }
    timer?.tolerance = 5
    alignTimerToNextMinute()
    refreshSecondTimer()
  }

  private func handleTick() {
    let cal = prayerCalendar
    let today = cal.dateComponents([.year, .month, .day], from: Date())
    if today.day != currentDay.day || today.month != currentDay.month
      || today.year != currentDay.year
    {
      currentDay = today
      calculatePrayerTimes()
    }
    updateCurrentPrayer()
    alertScheduler.checkPendingAlerts()
    alignTimerToNextMinute()
    refreshSecondTimer()
  }

  private func alignTimerToNextMinute() {
    let currentSecond = Date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60)
    let delta = max(0.5, 60.5 - currentSecond)
    timer?.fireDate = Date().addingTimeInterval(delta)
  }

  /// True while the menu-bar status shows a sub-minute value - the last minute
  /// before the next prayer, or the first minute of a count-up - so the seconds
  /// ("45s") need a per-second refresh. False unless the menu bar is showing a
  /// "time until" countdown at all (clock-time / hidden never tick).
  private var needsSecondTick: Bool {
    guard preferences.displayNextPrayer,
      preferences.nextPrayerDisplayType == .timeUntil
    else { return false }
    let now = Date()
    if let countUp = menuBarCountUp, now.timeIntervalSince(countUp.time) < 60 { return true }
    guard nextPrayer != .sunrise, let next = nextPrayerTime else { return false }
    let delta = next.timeIntervalSince(now)
    return delta > 0 && delta <= 60
  }

  /// Starts or stops the 1-second menu-bar refresh based on `needsSecondTick`.
  /// Driven from each minute tick (and launch). The block refreshes only the
  /// status text and self-invalidates the moment the window closes, so a tinted
  /// label re-rasterizes per second only during that bounded ~60s.
  private func refreshSecondTimer() {
    guard needsSecondTick else {
      secondTimer?.invalidate()
      secondTimer = nil
      return
    }
    guard secondTimer == nil else { return }
    let tick = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        self.updateStatusBarText()
        if !self.needsSecondTick {
          self.secondTimer?.invalidate()
          self.secondTimer = nil
        }
      }
    }
    tick.tolerance = 0.15
    RunLoop.main.add(tick, forMode: .common)
    secondTimer = tick
  }

  // MARK: - Notifications

  private func observeNotifications() {
    let nc = NotificationCenter.default
    notificationObservers.append(
      nc.addObserver(forName: .locationDidUpdate, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in
          FailureReporter.shared.clearNotice(.location)
          self?.calculatePrayerTimes()
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: .locationDidFail, object: nil, queue: .main) { note in
        let failure = note.object as? LocationFailure ?? .unavailable
        Task { @MainActor in
          // Routes by the app-wide policy: transient/background stays silent and
          // self-heals; terminal (denied/restricted) surfaces non-modally via the
          // menu-bar badge, the popover, and the Location settings tab.
          FailureReporter.shared.report(failure, waiting: false, domain: .location)
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: .guidancePreferencesDidChange, object: nil, queue: .main) {
        [weak self] note in
        let raw = note.userInfo?[PreferenceRefresh.userInfoKey] as? Int ?? 0
        Task { @MainActor in
          self?.applyPreferenceRefresh(PreferenceRefresh(rawValue: raw))
        }
      })
    notificationObservers.append(
      // Scope to this manager's own audio controller so previewing a sound in
      // Settings (a separate controller) can't trigger spurious widget reloads.
      nc.addObserver(
        forName: .guidanceAudioPlaybackStateDidChange, object: audioPlaybackController,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          self?.publishWidgetSnapshot(reload: true)
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: .startLocationUpdate, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in
          self?.locationManager.startUpdating()
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: .stopLocationUpdate, object: nil, queue: .main) { [weak self] _ in
        Task { @MainActor in
          self?.locationManager.stopUpdating()
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: NSNotification.Name.NSSystemClockDidChange, object: nil, queue: .main)
      { [weak self] _ in
        Task { @MainActor in
          self?.refreshAfterPossibleMissedAlert()
        }
      })
    notificationObservers.append(
      nc.addObserver(
        forName: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil, queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          self?.refreshAfterPossibleMissedAlert()
        }
      })
    notificationObservers.append(
      nc.addObserver(forName: NSApplication.willBecomeActiveNotification, object: nil, queue: .main)
      { [weak self] _ in
        Task { @MainActor in
          self?.refreshAfterPossibleMissedAlert()
        }
      })
    notificationObservers.append(
      NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          self?.refreshAfterPossibleMissedAlert()
        }
      })
  }

  private func refreshAfterPossibleMissedAlert() {
    alertScheduler.checkPendingAlerts()
    calculatePrayerTimes()
  }

  private func applyNotificationRuntimePreferences() {
    let volume = Float(max(0, min(preferences.alertVolume, 100))) / 100.0
    audioPlaybackController.setVolume(volume)

    if preferences.silentMode {
      audioPlaybackController.stop()
      return
    }

    if !preferences.duaEnabled {
      audioPlaybackController.cancelFollowUp()

      if case let .playing(context) = audioPlaybackController.state,
        context.source == .dua
      {
        audioPlaybackController.stop()
      }
    }
  }

  // MARK: - Calculation

  func calculatePrayerTimes() {
    let coords = Coordinates(latitude: preferences.latitude, longitude: preferences.longitude)
    let cal = prayerCalendar
    let now = Date()
    let todayComponents = cal.dateComponents([.year, .month, .day], from: now)
    currentDay = todayComponents

    guard
      let today = cal.date(from: todayComponents),
      let yesterday = cal.date(byAdding: .day, value: -1, to: today),
      let tomorrow = cal.date(byAdding: .day, value: 1, to: today)
    else { return }

    let yesterdayComponents = cal.dateComponents([.year, .month, .day], from: yesterday)
    let tomorrowComponents = cal.dateComponents([.year, .month, .day], from: tomorrow)

    let yesterdayParameters = calculationParameters(for: yesterday)
    let todayParameters = calculationParameters(for: today)
    let tomorrowParameters = calculationParameters(for: tomorrow)

    let yesterdayTimes = PrayerTimes(
      coordinates: coords,
      date: yesterdayComponents,
      calculationParameters: yesterdayParameters
    )
    let todayTimes = PrayerTimes(
      coordinates: coords,
      date: todayComponents,
      calculationParameters: todayParameters
    )
    let tomorrowTimes = PrayerTimes(
      coordinates: coords,
      date: tomorrowComponents,
      calculationParameters: tomorrowParameters
    )

    // Adhan's PrayerTimes init is failable (e.g. an extreme high latitude with
    // no resolvable transit). Keep the last good times rather than blanking the
    // UI; surface a one-time notice only if there were never any times to show.
    if let todayTimes {
      prayerTimes = todayTimes
      FailureReporter.shared.clearNotice(.prayerCalc)
    } else {
      let hadTimes = prayerTimes != nil
      let lat = preferences.latitude
      let lng = preferences.longitude
      AppLog.prayer.error(
        "PrayerTimes unavailable for (\(lat, privacy: .public), \(lng, privacy: .public))")
      if !hadTimes {
        FailureReporter.shared.report(
          PrayerCalcFailure.timesUnavailable(latitude: lat, longitude: lng),
          waiting: false, domain: .prayerCalc)
      }
    }
    if let yesterdayTimes { yesterdayPrayerTimes = yesterdayTimes }
    if let tomorrowTimes { tomorrowPrayerTimes = tomorrowTimes }

    alertScheduler.scheduleNotifications(
      for: [yesterdayPrayerTimes, prayerTimes, tomorrowPrayerTimes].compactMap(\.self),
      formattedTime: formattedTime(for:)
    )

    updateCurrentPrayer()
    publishWidgetSnapshot(reload: true)
  }

  private func calculationParameters(for date: Date) -> CalculationParameters {
    var params = preferences.calculationMethod.params
    params.madhab = preferences.madhab
    params.highLatitudeRule = preferences.highLatitudeRule

    params.adjustments = PrayerAdjustments(
      fajr: preferences.fajrAdjustment,
      sunrise: preferences.shuruqAdjustment,
      dhuhr: preferences.dhuhrAdjustment,
      asr: preferences.asrAdjustment,
      maghrib: preferences.maghribAdjustment,
      isha: preferences.ishaAdjustment
    )

    if params.method == .other {
      params.fajrAngle = preferences.customFajrAngle
      params.ishaAngle = preferences.customIshaAngle
    }

    applyDelayedIshaIfNeeded(to: &params, on: date)
    return params
  }

  private func applyDelayedIshaIfNeeded(to params: inout CalculationParameters, on date: Date) {
    guard params.ishaInterval > 0, preferences.delayedIshaInRamadan else { return }

    var hijriCal = Calendar(identifier: .islamicUmmAlQura)
    hijriCal.timeZone = storedTimeZone
    let adjustedDate = displayFormatter.adjustedHijriDate(for: date)
    if hijriCal.component(.month, from: adjustedDate) == 9 {
      params.ishaInterval = 120
    }
  }

  private func updateCurrentPrayer() {
    let now = Date()
    currentPrayer = prayerTimes?.currentPrayer(at: now)
    nextPrayer = prayerTimes?.nextPrayer(at: now)
    updateStatusBarText()
    publishWidgetSnapshot(reload: false)
  }

  // MARK: - Preference-driven refresh

  /// The single consumer of `.guidancePreferencesDidChange`. Each effect does
  /// the minimum work it needs, and the cheap effects are never gated behind the
  /// expensive ones - in particular the language re-geocode runs detached, so a
  /// slow / throttled / offline reverse-geocode can't stall the visible widget +
  /// menu-bar refresh (the bug where switching language left the widgets stale).
  private func applyPreferenceRefresh(_ effects: PreferenceRefresh) {
    if effects.contains(.audioRuntime) {
      applyNotificationRuntimePreferences()
    }
    if effects.contains(.localization) {
      // The AppleLanguages override is applied in `Preferences`; here we only
      // refresh the geocoded city label in the new language. Detached so it
      // never blocks the refresh below. When it returns, the `city` didSet posts
      // its own `.display`, so the label updates on its own.
      let locale = preferences.appLanguage.locale
      Task { await self.locationManager.refreshGeocodedLabels(in: locale) }
    }
    if effects.contains(.prayerTimes) {
      calculatePrayerTimes()
    } else if !effects.isDisjoint(with: [.display, .localization]) {
      refreshDisplayOnly()
    }
  }

  /// Rebuild the widget snapshot + menu-bar text from the current prayer times,
  /// without recomputing them - for display-only changes (menu-bar format,
  /// location label, hijri offset, widget theme, language strings).
  private func refreshDisplayOnly() {
    updateStatusBarText()
    publishWidgetSnapshot(reload: true)
  }

  // MARK: - Status Bar

  private func updateStatusBarText() {
    guard preferences.displayNextPrayer else {
      statusBarText = ""
      return
    }

    let now = Date()

    // Iqama count-up: for 15 minutes after an alerted prayer fires, lead with
    // that prayer's elapsed time ("Dhuhr +12m") before handing back to the next
    // prayer's countdown - matching the widgets. Countdown style only; Sunrise
    // excluded (see `menuBarCountUp`).
    if let countUp = menuBarCountUp {
      let name = nameComponent(for: countUp.prayer)
      let elapsed = displayFormatter.countUp(from: countUp.time, to: now)
      statusBarText = joinStatus(name, elapsed)
      return
    }

    let prayer = nextPrayer
    let time: Date? = {
      if let p = prayer {
        return prayerTimes?.time(for: p)
      }
      return tomorrowPrayerTimes?.fajr
    }()

    let displayPrayer = prayer ?? .fajr
    let name = nameComponent(for: displayPrayer)

    let timeComponent: String = {
      guard let time else { return "" }
      switch preferences.nextPrayerDisplayType {
      case .timeUntil:
        return displayFormatter.countdown(from: now, to: time)
      case .timeOfPrayer:
        return displayFormatter.compactTime(for: time)
      case .none:
        return ""
      }
    }()

    statusBarText = joinStatus(name, timeComponent)
  }

  private func nameComponent(for prayer: Prayer) -> String {
    switch preferences.nextPrayerDisplayName {
    case .full: return prayer.localizedName
    case .abbreviation: return prayer.abbreviation
    case .none: return ""
    }
  }

  private func joinStatus(_ name: String, _ time: String) -> String {
    if name.isEmpty && time.isEmpty { return "" }
    if name.isEmpty { return time }
    if time.isEmpty { return name }
    return "\(name) \(time)"
  }

  // MARK: - Formatting

  func formattedTime(for date: Date) -> String {
    displayFormatter.fullTime(for: date)
  }

  // MARK: - Hijri Date

  var hijriDay: String {
    displayFormatter.hijriDay()
  }

  var hijriMonth: String {
    displayFormatter.hijriMonth()
  }

  var hijriYear: String {
    displayFormatter.hijriYear()
  }

  private var prayerCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = storedTimeZone
    return calendar
  }

  private var storedTimeZone: TimeZone {
    TimeZone(identifier: preferences.storedTimeZone) ?? .current
  }

  private var displayFormatter: PrayerDisplayFormatter {
    PrayerDisplayFormatter(timeZone: storedTimeZone, hijriOffset: preferences.hijriOffset)
  }
}

enum MenuBarStatusTone {
  case normal
  case imminent
  case playingPreReminderAudio
  case playingPrayerAudio
  case playingPostReminderAudio
}

extension PrayerManager {
  var menuBarStatusTone: MenuBarStatusTone {
    if case let .playing(context) = audioPlaybackController.state {
      switch context.slot {
      case .preReminder:
        return .playingPreReminderAudio
      case .alert:
        return .playingPrayerAudio
      case .postReminder:
        return .playingPostReminderAudio
      case nil:
        return .playingPrayerAudio
      }
    }

    // Iqama count-up window: green, reusing the playing-adhan tone so the menu
    // bar matches the widget. Countdown style only (see `menuBarCountUp`).
    if menuBarCountUp != nil { return .playingPrayerAudio }

    // Imminent red in the 15 min before the next prayer - but never before
    // Sunrise, which is not an alerted prayer.
    if nextPrayer == .sunrise { return .normal }
    guard let nextPrayerTime else {
      return .normal
    }

    let timeUntilPrayer = nextPrayerTime.timeIntervalSince(Date())
    return timeUntilPrayer >= 0 && timeUntilPrayer <= 15 * 60.0 ? .imminent : .normal
  }

  /// The just-fired alerted prayer leading the 15-minute count-up, with its time,
  /// or nil. Countdown style only (clock-time style is unaffected); Sunrise
  /// excluded since it is not an alerted prayer (no green count-up after it).
  var menuBarCountUp: (prayer: Prayer, time: Date)? {
    guard preferences.nextPrayerDisplayType == .timeUntil else { return nil }
    guard let current = currentPrayer, current != .sunrise,
      let time = prayerTimes?.time(for: current)
    else { return nil }
    let elapsed = Date().timeIntervalSince(time)
    // `< 15m` (not `<=`) so the count-up ends exactly at the 15-minute mark,
    // matching the widget's `focus(at:)` boundary.
    return (elapsed >= 0 && elapsed < 15 * 60) ? (current, time) : nil
  }

  private var nextPrayerTime: Date? {
    if let nextPrayer {
      return prayerTimes?.time(for: nextPrayer)
    }
    return tomorrowPrayerTimes?.fajr
  }
}
