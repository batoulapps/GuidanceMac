import Adhan
import Foundation
import OSLog
import UserNotifications

@MainActor
final class PrayerAlertScheduler: NSObject, UNUserNotificationCenterDelegate {
  private static let notificationTimeZone = TimeZone(secondsFromGMT: 0)!
  private static let maxScheduledRequests = 60
  private static let dueAudioLeeway: TimeInterval = 1.5
  private static let missedPrayerTimeAudioGraceInterval: TimeInterval = 5 * 60
  private static let missedReminderAudioGraceInterval: TimeInterval = 2 * 60
  private static let handledEventIdentifierRetention: TimeInterval = 3 * 60 * 60
  private static let deliveredNotificationRetention: TimeInterval = 2 * 24 * 60 * 60

  private let preferences = Preferences.shared
  private let center = UNUserNotificationCenter.current()
  private let audioPlaybackController: AudioPlaybackController
  private var pendingEvents: [PrayerAlertEvent] = []
  private var handledEventIdentifiers: [String: Date] = [:]
  nonisolated(unsafe) private var nextAlertTimer: Timer?
  private var notificationUpdateTask: Task<Void, Never>?
  private var authorizationRequestTask: Task<UNAuthorizationStatus, Never>?

  init(audioPlaybackController: AudioPlaybackController = AudioPlaybackController()) {
    self.audioPlaybackController = audioPlaybackController
    super.init()

    center.delegate = self

    Task { @MainActor in
      await removeOldDeliveredGuidanceNotifications()
    }
  }

  deinit {
    nextAlertTimer?.invalidate()
    notificationUpdateTask?.cancel()
    authorizationRequestTask?.cancel()
  }

  func scheduleNotifications(for prayerTimesList: [PrayerTimes], formattedTime: (Date) -> String) {
    guard !prayerTimesList.isEmpty else {
      pendingEvents = []
      nextAlertTimer?.invalidate()
      replaceScheduledNotifications(with: [], validDeliveredNotifications: [:])
      return
    }

    let events =
      prayerTimesList
      .flatMap { prayerTimes in
        Prayer.allCases.flatMap {
          self.events(for: $0, prayerTimes: prayerTimes, formattedTime: formattedTime)
        }
      }
      .sorted { $0.time < $1.time }

    let now = Date()
    pruneHandledEventIdentifiers(now: now)

    pendingEvents = events.filter { event in
      guard !hasHandled(event) else { return false }
      return event.time > now || isAudioCatchUpEligible(event, now: now)
    }

    let validDeliveredNotifications = Dictionary(
      events.map { ($0.identifier, DeliveredNotificationSnapshot(event: $0)) },
      uniquingKeysWith: { first, _ in first }
    )

    replaceScheduledNotifications(
      with: pendingEvents,
      validDeliveredNotifications: validDeliveredNotifications
    )
    armNextAlertTimer()

    // Catch up on missed audio after launch, wake, or a recalculation that
    // lands just after a prayer event.
    checkPendingAlerts(now: now)
  }

  func checkPendingAlerts(now: Date = Date()) {
    pruneHandledEventIdentifiers(now: now)

    guard !pendingEvents.isEmpty else {
      nextAlertTimer?.invalidate()
      return
    }

    let dueEvents = pendingEvents.filter { event in
      !hasHandled(event) && isDueForAudioProcessing(event, now: now)
    }

    let dueOrExpiredEvents = pendingEvents.filter { event in
      event.time.timeIntervalSince(now) <= Self.dueAudioLeeway
    }

    if !dueOrExpiredEvents.isEmpty {
      for event in dueOrExpiredEvents {
        handledEventIdentifiers[event.identifier] = now
      }
      let identifiers = Set(dueOrExpiredEvents.map(\.identifier))
      pendingEvents.removeAll { identifiers.contains($0.identifier) }
    }

    deliverImmediateNotificationsIfNeeded(for: dueEvents, now: now)
    playBestAudioEventIfNeeded(from: dueEvents)

    armNextAlertTimer()
  }

  private func hasHandled(_ event: PrayerAlertEvent) -> Bool {
    handledEventIdentifiers[event.identifier] != nil
  }

  private func pruneHandledEventIdentifiers(now: Date) {
    let cutoff = now.addingTimeInterval(-Self.handledEventIdentifierRetention)
    handledEventIdentifiers = handledEventIdentifiers.filter { $0.value >= cutoff }
  }

  private func isDueForAudioProcessing(_ event: PrayerAlertEvent, now: Date) -> Bool {
    let delta = event.time.timeIntervalSince(now)
    guard delta <= Self.dueAudioLeeway else { return false }

    if delta >= 0 {
      return true
    }

    return isAudioCatchUpEligible(event, now: now)
  }

  private func isAudioCatchUpEligible(_ event: PrayerAlertEvent, now: Date) -> Bool {
    let lateBy = now.timeIntervalSince(event.time)
    guard lateBy >= 0 else { return false }

    switch event.kind {
    case .prayerTime:
      return lateBy <= Self.missedPrayerTimeAudioGraceInterval
    case .preReminder:
      // A "before prayer" reminder should not play after the actual prayer time.
      return lateBy <= Self.missedReminderAudioGraceInterval && now < event.prayerTime
    case .postReminder:
      return lateBy <= Self.missedReminderAudioGraceInterval
    }
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let identifier = notification.request.identifier

    guard identifier.hasPrefix(PrayerAlertEvent.identifierPrefix) else {
      completionHandler([.banner, .list, .sound])
      return
    }

    Task { @MainActor in
      self.checkPendingAlerts()
    }

    completionHandler([.banner, .list, .sound])
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let identifier = response.notification.request.identifier

    guard identifier.hasPrefix(PrayerAlertEvent.identifierPrefix) else {
      completionHandler()
      return
    }

    // v2: tapping the banner stops the adhan that's playing. Mirror that
    // so users can hush a long adhan with one click on the notification.
    Task { @MainActor in
      self.audioPlaybackController.stop()
      self.center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    completionHandler()
  }

  private func events(
    for prayer: Prayer,
    prayerTimes: PrayerTimes,
    formattedTime: (Date) -> String
  ) -> [PrayerAlertEvent] {
    let prayerTime = prayerTimes.time(for: prayer)
    let locale = Locale.app
    let config = preferences.config(for: prayer, on: prayerTime).sanitized()
    let prayerName = prayer.localizedName(on: prayerTime, locale: locale)
    let timeText = formattedTime(prayerTime)
    var events: [PrayerAlertEvent] = []

    if config.alertEnabled {
      let format = localizedString("notification.atTime", locale: locale)
      events.append(
        PrayerAlertEvent(
          prayer: prayer,
          kind: .prayerTime,
          prayerTime: prayerTime,
          time: prayerTime,
          sound: config.alertSound,
          offsetMinutes: nil,
          title: prayerName,
          message: String(format: format, locale: locale, prayerName, timeText)
        )
      )
    }

    if config.preReminderEnabled {
      let offset = PrayerNotificationConfig.clampedOffset(
        config.preReminderOffset,
        fallback: PrayerNotificationConfig.defaultConfig(for: prayer).preReminderOffset
      )
      let reminderTime = prayerTime.addingTimeInterval(-TimeInterval(offset) * 60)
      let format = localizedString("notification.preReminder.offset", locale: locale)
      let offsetText = offset.localizedDigits(locale: locale).bidiIsolated

      events.append(
        PrayerAlertEvent(
          prayer: prayer,
          kind: .preReminder,
          prayerTime: prayerTime,
          time: reminderTime,
          sound: config.preReminderSound,
          offsetMinutes: offset,
          title: prayerName,
          message: String(format: format, locale: locale, prayerName, offsetText)
        )
      )
    }

    if config.postReminderEnabled {
      let offset = PrayerNotificationConfig.clampedOffset(
        config.postReminderOffset,
        fallback: PrayerNotificationConfig.defaultConfig(for: prayer).postReminderOffset
      )
      let reminderTime = prayerTime.addingTimeInterval(TimeInterval(offset) * 60)
      let format = localizedString("notification.postReminder.offset", locale: locale)
      let offsetText = offset.localizedDigits(locale: locale).bidiIsolated

      events.append(
        PrayerAlertEvent(
          prayer: prayer,
          kind: .postReminder,
          prayerTime: prayerTime,
          time: reminderTime,
          sound: config.postReminderSound,
          offsetMinutes: offset,
          title: prayerName,
          message: String(format: format, locale: locale, prayerName, offsetText)
        )
      )
    }

    return events
  }

  private func armNextAlertTimer() {
    nextAlertTimer?.invalidate()

    guard let nextEvent = pendingEvents.first else { return }

    let fireDate = max(
      Date().addingTimeInterval(0.25),
      nextEvent.time.addingTimeInterval(0.15)
    )

    let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
      Task { @MainActor in
        self?.checkPendingAlerts()
      }
    }

    timer.tolerance = 0.75
    RunLoop.main.add(timer, forMode: .common)
    nextAlertTimer = timer
  }

  private func replaceScheduledNotifications(
    with events: [PrayerAlertEvent],
    validDeliveredNotifications: [String: DeliveredNotificationSnapshot]
  ) {
    let requests =
      events
      .compactMap(notificationRequest(for:))
      .prefix(Self.maxScheduledRequests)
      .map { $0 }
    let previousTask = notificationUpdateTask

    previousTask?.cancel()
    notificationUpdateTask = Task {
      @MainActor [weak self, previousTask, requests, validDeliveredNotifications] in
      await previousTask?.value
      guard !Task.isCancelled else { return }
      await self?.performScheduledNotificationReplacement(
        requests,
        validDeliveredNotifications: validDeliveredNotifications
      )
    }
  }

  private func performScheduledNotificationReplacement(
    _ requests: [UNNotificationRequest],
    validDeliveredNotifications: [String: DeliveredNotificationSnapshot]
  ) async {
    guard await notificationAuthorizationAllowsScheduling(shouldRequest: !requests.isEmpty) else {
      await removeAllScheduledGuidanceNotifications(
        validDeliveredNotifications: validDeliveredNotifications)
      return
    }
    guard !Task.isCancelled else { return }

    let desiredIdentifiers = Set(requests.map(\.identifier))
    let pendingRequests = await center.pendingNotificationRequests()
    guard !Task.isCancelled else { return }

    let staleIdentifiers =
      pendingRequests
      .map(\.identifier)
      .filter { $0.hasPrefix(PrayerAlertEvent.identifierPrefix) }
      .filter { !desiredIdentifiers.contains($0) }

    if !staleIdentifiers.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
    }

    await removeStaleDeliveredGuidanceNotifications(validNotifications: validDeliveredNotifications)

    for request in requests {
      guard !Task.isCancelled else { return }

      do {
        // Same identifiers replace existing pending requests, so settings,
        // time, and language changes do not leave a remove/add gap.
        try await center.add(request)
      } catch {
        if Task.isCancelled { return }
        AppLog.notifications.error(
          "Failed to schedule notification \(request.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
      }
    }
  }

  private func removeAllScheduledGuidanceNotifications(
    validDeliveredNotifications: [String: DeliveredNotificationSnapshot]? = nil
  ) async {
    let pendingRequests = await center.pendingNotificationRequests()
    guard !Task.isCancelled else { return }

    let staleIdentifiers =
      pendingRequests
      .map(\.identifier)
      .filter { $0.hasPrefix(PrayerAlertEvent.identifierPrefix) }

    if !staleIdentifiers.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
    }

    if let validDeliveredNotifications {
      await removeStaleDeliveredGuidanceNotifications(validNotifications: validDeliveredNotifications)
    } else {
      await removeOldDeliveredGuidanceNotifications()
    }
  }

  private func removeOldDeliveredGuidanceNotifications() async {
    await removeStaleDeliveredGuidanceNotifications(validNotifications: nil)
  }

  private func removeStaleDeliveredGuidanceNotifications(
    validNotifications: [String: DeliveredNotificationSnapshot]?
  ) async {
    let cutoffDate = Date().addingTimeInterval(-Self.deliveredNotificationRetention)
    let delivered = await center.deliveredNotifications()
    guard !Task.isCancelled else { return }

    let staleDeliveredGuidanceIDs =
      delivered
      .filter { $0.request.identifier.hasPrefix(PrayerAlertEvent.identifierPrefix) }
      .filter {
        shouldRemoveDeliveredNotification(
          $0,
          cutoffDate: cutoffDate,
          validNotifications: validNotifications
        )
      }
      .map(\.request.identifier)

    if !staleDeliveredGuidanceIDs.isEmpty {
      center.removeDeliveredNotifications(withIdentifiers: staleDeliveredGuidanceIDs)
    }
  }

  private func shouldRemoveDeliveredNotification(
    _ notification: UNNotification,
    cutoffDate: Date,
    validNotifications: [String: DeliveredNotificationSnapshot]?
  ) -> Bool {
    if notification.date < cutoffDate { return true }

    guard let validNotifications else { return false }

    let identifier = notification.request.identifier
    guard let expected = validNotifications[identifier] else { return true }

    let content = notification.request.content
    return content.title != expected.title || content.body != expected.body
  }

  private func deliverImmediateNotificationsIfNeeded(
    for events: [PrayerAlertEvent], now: Date
  ) {
    let candidates = events.filter { $0.time <= now.addingTimeInterval(Self.dueAudioLeeway) }
    guard !candidates.isEmpty else { return }

    Task { @MainActor [weak self, candidates] in
      await self?.deliverImmediateNotificationsIfNeeded(for: candidates)
    }
  }

  private func deliverImmediateNotificationsIfNeeded(for events: [PrayerAlertEvent]) async {
    guard await notificationAuthorizationAllowsScheduling(shouldRequest: !events.isEmpty) else {
      return
    }

    let pendingIdentifiers = Set((await center.pendingNotificationRequests()).map(\.identifier))
    let deliveredIdentifiers = Set(
      (await center.deliveredNotifications()).map { $0.request.identifier })

    for event in events
    where !pendingIdentifiers.contains(event.identifier)
      && !deliveredIdentifiers.contains(event.identifier)
    {
      do {
        try await center.add(immediateNotificationRequest(for: event))
      } catch {
        AppLog.notifications.error(
          "Failed to deliver catch-up notification \(event.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
      }
    }
  }

  private func notificationAuthorizationAllowsScheduling(shouldRequest: Bool) async -> Bool {
    let settings = await center.notificationSettings()
    guard shouldRequest, settings.authorizationStatus == .notDetermined else {
      return notificationsCanDeliver(settings.authorizationStatus)
    }

    if let authorizationRequestTask {
      return notificationsCanDeliver(await authorizationRequestTask.value)
    }

    let task = Task { @MainActor [weak self] in
      guard let self else { return UNAuthorizationStatus.denied }
      do {
        _ = try await self.center.requestAuthorization(options: [.alert, .sound])
      } catch {
        AppLog.notifications.error(
          "Failed to request notification authorization: \(error.localizedDescription, privacy: .public)"
        )
      }

      return await self.center.notificationSettings().authorizationStatus
    }

    authorizationRequestTask = task
    let status = await task.value
    authorizationRequestTask = nil
    return notificationsCanDeliver(status)
  }

  private func notificationsCanDeliver(_ status: UNAuthorizationStatus) -> Bool {
    switch status {
    case .authorized, .provisional:
      return true
    case .denied, .notDetermined:
      return false
    @unknown default:
      return false
    }
  }

  private func notificationRequest(for event: PrayerAlertEvent) -> UNNotificationRequest? {
    guard event.time > Date().addingTimeInterval(Self.dueAudioLeeway) else { return nil }

    let content = notificationContent(for: event)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.notificationTimeZone
    var components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: event.time)
    components.calendar = calendar
    components.timeZone = Self.notificationTimeZone
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    return UNNotificationRequest(identifier: event.identifier, content: content, trigger: trigger)
  }

  private func immediateNotificationRequest(for event: PrayerAlertEvent) -> UNNotificationRequest {
    UNNotificationRequest(
      identifier: event.identifier,
      content: notificationContent(for: event),
      trigger: nil
    )
  }

  private func notificationContent(for event: PrayerAlertEvent) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = event.title
    content.body = event.message
    content.threadIdentifier = "guidance-prayers"
    content.userInfo = [
      "prayer": event.prayer.settingsKey,
      "kind": event.kind.rawValue,
      "offsetMinutes": event.offsetMinutes ?? 0,
    ]
    content.interruptionLevel = event.kind.interruptionLevel
    content.relevanceScore = event.kind.relevanceScore

    if event.sound == .system && !preferences.silentMode {
      content.sound = .default
    }

    return content
  }

  private func playBestAudioEventIfNeeded(from events: [PrayerAlertEvent]) {
    guard
      let event = events
        .filter(usesAppAudio)
        .max(by: audioEventHasLowerPrecedence)
    else { return }

    playAudioIfNeeded(for: event)
  }

  private func usesAppAudio(_ event: PrayerAlertEvent) -> Bool {
    guard !preferences.silentMode else { return false }
    return event.sound != .system && event.sound != .none
  }

  private func audioEventHasLowerPrecedence(
    _ lhs: PrayerAlertEvent,
    _ rhs: PrayerAlertEvent
  ) -> Bool {
    if lhs.time != rhs.time {
      return lhs.time < rhs.time
    }

    return lhs.kind.audioPriority < rhs.kind.audioPriority
  }

  private func playAudioIfNeeded(for event: PrayerAlertEvent) {
    guard !preferences.silentMode else { return }
    guard event.sound != .system && event.sound != .none else { return }
    guard
      let resource = event.sound.audioPlaybackResource(refreshCustomFile: {
        self.updateCustomSound($0, for: event)
      })
    else { return }

    let request = AudioPlaybackRequest(
      resource: resource,
      volume: alertVolume,
      context: AudioPlaybackContext(
        prayer: event.prayer,
        source: .prayerAlert,
        slot: event.kind.soundSlot,
        prayerTime: event.prayerTime,
        prayerAlertOffsetMinutes: event.offsetMinutes
      )
    )
    audioPlaybackController.play(request, followUp: duaRequest(for: event))
  }

  private func updateCustomSound(_ customFile: CustomAdhanFile, for event: PrayerAlertEvent) {
    var config = preferences.config(for: event.prayer, on: event.prayerTime).sanitized()
    let slot = event.kind.soundSlot
    guard config.sound(for: slot) == event.sound else { return }
    config.setSound(.custom(customFile), for: slot)
    preferences.setConfig(config, for: event.prayer, on: event.prayerTime)
  }

  private func duaRequest(for event: PrayerAlertEvent) -> AudioPlaybackRequest? {
    guard event.kind == .prayerTime else { return nil }
    guard !preferences.silentMode, preferences.duaEnabled else { return nil }
    guard let duaURL = Bundle.main.url(forResource: "Dua", withExtension: "m4a") else { return nil }

    return AudioPlaybackRequest(
      url: duaURL,
      volume: alertVolume,
      context: AudioPlaybackContext(
        prayer: event.prayer,
        source: .dua,
        slot: event.kind.soundSlot,
        prayerTime: event.prayerTime,
        prayerAlertOffsetMinutes: event.offsetMinutes
      )
    )
  }

  private var alertVolume: Float {
    Float(max(0, min(preferences.alertVolume, 100))) / 100.0
  }
}

private enum PrayerAlertKind: String {
  case prayerTime
  case preReminder
  case postReminder

  var soundSlot: PrayerNotificationSoundSlot {
    switch self {
    case .prayerTime: .alert
    case .preReminder: .preReminder
    case .postReminder: .postReminder
    }
  }

  var audioPriority: Int {
    switch self {
    case .prayerTime: 3
    case .preReminder: 2
    case .postReminder: 1
    }
  }

  // The pre-reminder shares the prayer time's time-sensitive level so it can
  // break through Focus before the prayer. Post-reminder stays standard since
  // the prayer window is already closing by then.
  var interruptionLevel: UNNotificationInterruptionLevel {
    switch self {
    case .prayerTime, .preReminder: .timeSensitive
    case .postReminder: .active
    }
  }

  var relevanceScore: Double {
    switch self {
    case .prayerTime: 1.0
    case .preReminder: 0.7
    case .postReminder: 0.5
    }
  }
}

private struct PrayerAlertEvent {
  nonisolated static let identifierPrefix = "guidance.prayer."

  let prayer: Prayer
  let kind: PrayerAlertKind
  let prayerTime: Date
  let time: Date
  let sound: AdhanSound
  let offsetMinutes: Int?
  let title: String
  let message: String

  var identifier: String {
    "\(Self.identifierPrefix)\(prayer.settingsKey).\(kind.rawValue).\(Int(time.timeIntervalSince1970))"
  }
}

private struct DeliveredNotificationSnapshot: Equatable {
  let title: String
  let body: String

  init(event: PrayerAlertEvent) {
    title = event.title
    body = event.message
  }
}
