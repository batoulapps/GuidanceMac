import AppKit
import MapKit
import SwiftUI

struct LocationContent: View {
  @Bindable var prefs = Preferences.shared
  @State private var locationSearch = LocationSearchService()
  @FocusState private var isSearchFocused: Bool

  private let timeZoneChoices = TimeZone.knownTimeZoneIdentifiers
    .map(TimeZoneChoice.init(identifier:))
    .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

  var body: some View {
    @Bindable var search = locationSearch

    Section("settings.location.detection") {
      Toggle("settings.location.useCurrent", isOn: $prefs.useCurrentLocation)

      if let notice = FailureReporter.shared.currentNotice, notice.domain == .location {
        InlineNoticeLabel(message: notice.message)
        if notice.category == .terminal {
          Button("settings.location.openSystemSettings") {
            openLocationSystemSettings()
          }
        }
      }
    }
    .onChange(of: prefs.useCurrentLocation) {
      if prefs.useCurrentLocation {
        NotificationCenter.default.post(name: .startLocationUpdate, object: nil)
        locationSearch.cancel()
        isSearchFocused = false
      } else {
        NotificationCenter.default.post(name: .stopLocationUpdate, object: nil)
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
      if prefs.useCurrentLocation {
        NotificationCenter.default.post(name: .startLocationUpdate, object: nil)
      }
    }

    if !prefs.useCurrentLocation {
      Section("settings.location.search") {
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.tertiary)
            .font(.system(size: 12))

          TextField(
            localizedString("settings.location.searchPlaceholder", locale: .app),
            text: $search.searchText
          )
          .textFieldStyle(.plain)
          .multilineTextAlignment(.leading)
          .focused($isSearchFocused)

          if locationSearch.isSearching || locationSearch.isResolving {
            ProgressView()
              .controlSize(.small)
          } else if !locationSearch.searchText.isEmpty {
            Button {
              locationSearch.cancel()
              isSearchFocused = true
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture { isSearchFocused = true }

        ForEach(locationSearch.completions.prefix(5), id: \.self) { completion in
          Button {
            Task { await locationSearch.selectCompletion(completion) }
          } label: {
            VStack(alignment: .leading, spacing: 2) {
              Text(completion.title)
              if !completion.subtitle.isEmpty {
                Text(completion.subtitle)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }

        if let error = locationSearch.errorMessage {
          Label(error, systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
      .onChange(of: locationSearch.searchText) {
        locationSearch.updateCompleter()
      }
      // Drop a stale search error message when the language changes - it was
      // built against the old locale and would otherwise sit there frozen.
      .onChange(of: prefs.appLanguage) { locationSearch.errorMessage = nil }
    }

    Section("settings.location.current") {
      LabeledContent("settings.location.city", value: prefs.city)
      LabeledContent("settings.location.region") {
        Text(
          [prefs.state, prefs.countryName]
            .filter { !$0.isEmpty }
            .joined(separator: ", "))
      }
      LabeledContent("settings.location.coordinates") {
        // Coordinates are inherently LTR ("31.1342, 29.9792"); force the
        // direction so the comma doesn't migrate to the wrong side under Arabic.
        Text(String(format: "%.4f, %.4f", prefs.latitude, prefs.longitude))
          .environment(\.layoutDirection, .leftToRight)
      }
      LabeledContent("settings.location.timeZone") {
        if prefs.useCurrentLocation {
          // IANA identifiers like "America/New_York" must stay LTR regardless of
          // the surrounding paragraph direction.
          Text(prefs.storedTimeZone)
            .environment(\.layoutDirection, .leftToRight)
        } else {
          Picker("", selection: $prefs.storedTimeZone) {
            ForEach(timeZoneChoices) { choice in
              Text(choice.title).tag(choice.identifier)
            }
          }
          .labelsHidden()
          .environment(\.layoutDirection, .leftToRight)
        }
      }
    }
  }

  private func openLocationSystemSettings() {
    let urlStrings = [
      "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices",
      "x-apple.systempreferences:com.apple.preference.security",
    ]
    for urlString in urlStrings {
      guard let url = URL(string: urlString) else { continue }
      if NSWorkspace.shared.open(url) { return }
    }
  }
}

private struct TimeZoneChoice: Identifiable {
  let identifier: String
  let title: String

  nonisolated var id: String { identifier }

  nonisolated init(identifier: String) {
    self.identifier = identifier
    title =
      identifier
      .split(separator: "/")
      .last
      .map { $0.replacingOccurrences(of: "_", with: " ") }
      ?? identifier
  }
}
