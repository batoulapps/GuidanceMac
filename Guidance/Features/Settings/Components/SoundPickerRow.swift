import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SoundPickerRow: View {
  @Binding var sound: AdhanSound

  let isPreviewing: Bool
  let isSilentMode: Bool
  let onPreviewToggle: () -> Void
  let onSoundChanged: () -> Void

  private var soundSelection: Binding<AdhanSound> {
    Binding(
      get: { sound },
      set: { newValue in
        guard sound != newValue else { return }
        sound = newValue
        onSoundChanged()
      }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Picker("settings.notif.sound", selection: soundSelection) {
          Section("settings.notif.sound.adhan") {
            ForEach(AdhanSound.adhanSounds, id: \.self) { option in
              Text(option.displayName).tag(option)
            }
          }

          if case let .custom(file) = sound {
            Section("settings.notif.sound.custom") {
              Text(file.fileName).tag(sound)
            }
          }

          Section {
            Text(AdhanSound.system.displayName).tag(AdhanSound.system)
            Text(AdhanSound.none.displayName).tag(AdhanSound.none)
          }
        }

        Button {
          chooseCustomSound()
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
        .help(Text(localizedString(customButtonHelpKey, locale: .app)))

        Button {
          onPreviewToggle()
        } label: {
          Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
        }
        .buttonStyle(.borderless)
        .disabled(!sound.canPreview && !isPreviewing)
        .help(Text(localizedString(previewHelpKey, locale: .app)))
      }
      .disabled(isSilentMode)

      if sound.isCustomUnavailable {
        Label {
          Text(localizedString("settings.notif.sound.custom.unavailable", locale: .app))
        } icon: {
          Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var previewHelpKey: String.LocalizationValue {
    isPreviewing ? "settings.notif.preview.stop" : "settings.notif.preview.play"
  }

  private var customButtonHelpKey: String.LocalizationValue {
    if case .custom = sound {
      return "settings.notif.sound.custom.change"
    }
    return "settings.notif.sound.custom.choose"
  }

  private func chooseCustomSound() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = Self.allowedAudioContentTypes

    guard panel.runModal() == .OK, let url = panel.url else { return }

    do {
      sound = .custom(try CustomAdhanFile(fileURL: url))
      onSoundChanged()
    } catch {
      NSSound.beep()
    }
  }

  private static var allowedAudioContentTypes: [UTType] {
    ["m4a", "mp3", "wav"].compactMap { UTType(filenameExtension: $0) }
  }
}
