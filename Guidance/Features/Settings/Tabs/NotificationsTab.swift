import Adhan
import AppKit
import SwiftUI
import UserNotifications

private enum DhuhrNotificationScope: String, Hashable {
  case otherDays
  case friday
}

struct NotificationsContent: View {
  @Bindable var prefs = Preferences.shared
  @State private var selectedPrayer: Prayer = .fajr
  @State private var previewController = AudioPlaybackController()
  @State private var notificationSettings: UNNotificationSettings?
  @State private var dhuhrNotificationScope: DhuhrNotificationScope = .otherDays
  @State private var permissionRequestInFlight = false
  @State private var permissionRequestFailed = false

  private var authorizationStatus: UNAuthorizationStatus? {
    notificationSettings?.authorizationStatus
  }

  private var config: Binding<PrayerNotificationConfig> {
    Binding(
      get: {
        if isEditingJumuahConfig {
          return prefs.jumuahConfig
        }
        return prefs.config(for: selectedPrayer)
      },
      set: {
        if isEditingJumuahConfig {
          prefs.setJumuahConfig($0)
        } else {
          prefs.setConfig($0, for: selectedPrayer)
        }
      }
    )
  }

  private var isEditingJumuahConfig: Bool {
    selectedPrayer == .dhuhr && prefs.jumuahOverrideEnabled && dhuhrNotificationScope == .friday
  }

  private var volume: Binding<Double> {
    Binding(
      get: { Double(prefs.alertVolume) },
      set: { prefs.alertVolume = Int($0.rounded()) }
    )
  }

  var body: some View {
    Section("settings.notif.global") {
      Toggle("settings.notif.silent", isOn: $prefs.silentMode)
      Toggle("settings.notif.dua", isOn: $prefs.duaEnabled)
        .disabled(prefs.silentMode)

      HStack {
        Slider(value: volume, in: 0...100, step: 1)
          .disabled(prefs.silentMode)
        Text(
          String(
            format: localizedString("settings.notif.volume.label", locale: .app),
            locale: .app,
            prefs.alertVolume.localizedDigits().bidiIsolated
          )
        )
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .frame(width: 44, alignment: .trailing)
      }

      Button("settings.notif.openSystemSettings") {
        openNotificationSettings()
      }

      if let permissionMessage {
        Label {
          Text(localizedString(permissionMessage, locale: .app))
        } icon: {
          Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.secondary)
      }
    }
    .onChange(of: prefs.silentMode) {
      // Refresh (audio + display) is emitted by the `silentMode` didSet; this
      // only stops a running in-Settings preview.
      if prefs.silentMode {
        previewController.stop()
      }
    }
    .onChange(of: prefs.alertVolume) {
      previewController.setVolume(Float(prefs.alertVolume) / 100.0)
    }
    .task {
      await requestAuthorizationIfNeeded()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
      Task {
        await refreshAuthorizationStatus(rescheduleOnGrant: true)
      }
    }

    Section {
      Picker("settings.notif.prayer", selection: $selectedPrayer) {
        ForEach(Prayer.allCases, id: \.self) { prayer in
          Text(prayer.settingsLocalizedName).tag(prayer)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
    }
    .onChange(of: prefs.notificationSettings) {
      // The `notificationSettings` didSet emits the reschedule + republish; here
      // we only (re)request authorization if a newly-enabled alert needs it.
      Task {
        await requestAuthorizationIfNeeded()
      }
    }

    if selectedPrayer == .dhuhr {
      Section("settings.notif.jumuah.section") {
        Toggle("settings.notif.jumuah.toggle", isOn: $prefs.jumuahOverrideEnabled)

        if prefs.jumuahOverrideEnabled {
          Picker("settings.notif.jumuah.section", selection: $dhuhrNotificationScope) {
            Text("settings.notif.jumuah.switch.otherDays")
              .tag(DhuhrNotificationScope.otherDays)
            Text("settings.notif.jumuah.switch.friday")
              .tag(DhuhrNotificationScope.friday)
          }
          .pickerStyle(.segmented)
          .labelsHidden()
        }
      }
      .onChange(of: prefs.jumuahOverrideEnabled) {
        if prefs.jumuahOverrideEnabled {
          dhuhrNotificationScope = .friday
        } else {
          dhuhrNotificationScope = .otherDays
        }
        previewController.stop()
        Task { await requestAuthorizationIfNeeded() }
      }
      .onChange(of: dhuhrNotificationScope) {
        previewController.stop()
      }
    }

    Section("settings.notif.alert") {
      Toggle("settings.notif.alert.toggle", isOn: config.alertEnabled)
      if config.alertEnabled.wrappedValue {
        SoundPickerRow(
          sound: config.alertSound,
          isPreviewing: isPreviewing(slot: .alert),
          isSilentMode: prefs.silentMode,
          onPreviewToggle: { togglePreview(sound: config.alertSound.wrappedValue, slot: .alert) },
          onSoundChanged: { stopPreviewIfNeeded(slot: .alert) }
        )
      }
    }
    .onChange(of: selectedPrayer) {
      previewController.stop()
      if selectedPrayer != .dhuhr {
        dhuhrNotificationScope = .otherDays
      }
    }

    Section("settings.notif.pre") {
      Toggle("settings.notif.pre.toggle", isOn: config.preReminderEnabled)
      if config.preReminderEnabled.wrappedValue {
        Stepper(
          value: config.preReminderOffset,
          in: 1...120
        ) {
          Text(
            String(
              format: localizedString("settings.notif.pre.stepper", locale: .app),
              locale: .app,
              config.preReminderOffset.wrappedValue.localizedDigits().bidiIsolated
            )
          )
        }
        SoundPickerRow(
          sound: config.preReminderSound,
          isPreviewing: isPreviewing(slot: .preReminder),
          isSilentMode: prefs.silentMode,
          onPreviewToggle: {
            togglePreview(sound: config.preReminderSound.wrappedValue, slot: .preReminder)
          },
          onSoundChanged: { stopPreviewIfNeeded(slot: .preReminder) }
        )
      }
    }

    Section("settings.notif.post") {
      Toggle("settings.notif.post.toggle", isOn: config.postReminderEnabled)
      if config.postReminderEnabled.wrappedValue {
        Stepper(
          value: config.postReminderOffset,
          in: 1...120
        ) {
          Text(
            String(
              format: localizedString("settings.notif.post.stepper", locale: .app),
              locale: .app,
              config.postReminderOffset.wrappedValue.localizedDigits().bidiIsolated
            )
          )
        }
        SoundPickerRow(
          sound: config.postReminderSound,
          isPreviewing: isPreviewing(slot: .postReminder),
          isSilentMode: prefs.silentMode,
          onPreviewToggle: {
            togglePreview(sound: config.postReminderSound.wrappedValue, slot: .postReminder)
          },
          onSoundChanged: { stopPreviewIfNeeded(slot: .postReminder) }
        )
      }
    }
  }

  private var permissionMessage: String.LocalizationValue? {
    if permissionRequestFailed {
      return "settings.notif.permission.error"
    }

    guard let settings = notificationSettings else { return nil }

    switch settings.authorizationStatus {
    case .denied:
      return "settings.notif.permission.denied"

    case .notDetermined:
      return nil

    case .authorized, .provisional:
      if settings.alertSetting == .disabled || settings.notificationCenterSetting == .disabled {
        return "settings.notif.permission.unknown"
      }

      if hasSystemSoundNotifications && settings.soundSetting == .disabled {
        return "settings.notif.permission.unknown"
      }

      return nil

    @unknown default:
      return "settings.notif.permission.unknown"
    }
  }

  private var hasSystemSoundNotifications: Bool {
    notificationConfigsForPermission.contains { config in
      return
        (config.alertEnabled && config.alertSound == .system)
        || (config.preReminderEnabled && config.preReminderSound == .system)
        || (config.postReminderEnabled && config.postReminderSound == .system)
    }
  }

  private var hasEnabledNotifications: Bool {
    notificationConfigsForPermission.contains { config in
      config.alertEnabled || config.preReminderEnabled || config.postReminderEnabled
    }
  }

  private var notificationConfigsForPermission: [PrayerNotificationConfig] {
    var configs = Prayer.allCases.map { prefs.config(for: $0) }
    if prefs.jumuahOverrideEnabled {
      configs.append(prefs.jumuahConfig)
    }
    return configs
  }

  private func isPreviewing(slot: PrayerNotificationSoundSlot) -> Bool {
    guard case let .playing(context) = previewController.state else { return false }
    return context.source == .preview && context.prayer == selectedPrayer && context.slot == slot
  }

  private func stopPreviewIfNeeded(slot: PrayerNotificationSoundSlot) {
    if isPreviewing(slot: slot) {
      previewController.stop()
    }
  }

  private func togglePreview(sound: AdhanSound, slot: PrayerNotificationSoundSlot) {
    if isPreviewing(slot: slot) {
      previewController.stop()
      return
    }

    if sound == .system {
      NSSound.beep()
      return
    }

    guard
      let resource = sound.audioPlaybackResource(refreshCustomFile: {
        setSound(.custom($0), for: slot)
      })
    else { return }

    previewController.play(
      AudioPlaybackRequest(
        resource: resource,
        volume: Float(prefs.alertVolume) / 100.0,
        context: AudioPlaybackContext(prayer: selectedPrayer, source: .preview, slot: slot)
      )
    )
  }

  private func setSound(_ sound: AdhanSound, for slot: PrayerNotificationSoundSlot) {
    var updatedConfig = config.wrappedValue
    updatedConfig.setSound(sound, for: slot)
    config.wrappedValue = updatedConfig
  }

  @MainActor
  private func requestAuthorizationIfNeeded() async {
    guard !permissionRequestInFlight, hasEnabledNotifications else {
      await refreshAuthorizationStatus(rescheduleOnGrant: false)
      return
    }

    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    let wasDelivering = notificationsCanDeliver(authorizationStatus)
    applyNotificationSettings(settings)

    guard settings.authorizationStatus == .notDetermined else { return }

    permissionRequestInFlight = true
    permissionRequestFailed = false
    defer { permissionRequestInFlight = false }

    do {
      _ = try await center.requestAuthorization(options: [.alert, .sound])
    } catch {
      permissionRequestFailed = true
    }

    let updatedSettings = await center.notificationSettings()
    applyNotificationSettings(updatedSettings)

    if !wasDelivering && notificationsCanDeliver(updatedSettings.authorizationStatus) {
      notifyChange()
    }
  }

  @MainActor
  private func refreshAuthorizationStatus(rescheduleOnGrant: Bool) async {
    let wasDelivering = notificationsCanDeliver(authorizationStatus)
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    applyNotificationSettings(settings)

    if rescheduleOnGrant && !wasDelivering && notificationsCanDeliver(settings.authorizationStatus) {
      notifyChange()
    }
  }

  // A prior `requestAuthorization` throw stays in `permissionRequestFailed`
  // forever otherwise, since the request-flow guards return early once the
  // status leaves `.notDetermined`. Observing any resolved state means the
  // system has an authoritative answer, so let the normal status message win.
  private func applyNotificationSettings(_ settings: UNNotificationSettings) {
    notificationSettings = settings
    if settings.authorizationStatus != .notDetermined {
      permissionRequestFailed = false
    }
  }

  private func notificationsCanDeliver(_ status: UNAuthorizationStatus?) -> Bool {
    switch status {
    case .authorized, .provisional:
      return true
    case .denied, .notDetermined, nil:
      return false
    @unknown default:
      return false
    }
  }

  private func openNotificationSettings() {
    let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.batoulapps.GuidanceMac"
    let urlStrings = [
      "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleIdentifier)",
      "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
      "x-apple.systempreferences:com.apple.preference.notifications",
    ]

    for urlString in urlStrings {
      guard let url = URL(string: urlString) else { continue }
      if NSWorkspace.shared.open(url) {
        return
      }
    }
  }
}
