import SwiftUI

struct LanguagePicker: View {
  @Bindable var prefs = Preferences.shared
  @State private var isPopoverOpen = false

  private var displayLocale: Locale { prefs.appLanguage.locale }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      triggerButton
      previewRow
    }
    .padding(.vertical, 2)
  }

  // MARK: - Trigger

  private var triggerButton: some View {
    Button {
      isPopoverOpen.toggle()
    } label: {
      HStack(spacing: 12) {
        LanguageGlyphBadge(language: prefs.appLanguage, isSelected: true)

        VStack(alignment: .leading, spacing: 1) {
          Text(triggerTitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
          Text(triggerSubtitle)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.up.chevron.down")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(cardBackground)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .popover(isPresented: $isPopoverOpen, arrowEdge: .bottom) {
      LanguagePopoverContent(
        prefs: prefs,
        displayLocale: displayLocale,
        onSelect: handleSelect
      )
    }
  }

  // MARK: - Preview row

  private var previewRow: some View {
    HStack(alignment: .center, spacing: 10) {
      Text(captionText)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)
      Spacer(minLength: 8)
      MenuBarPreview(language: prefs.appLanguage)
    }
    .padding(.top, 2)
  }

  // MARK: - Shared chrome

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .fill(Color(nsColor: .controlBackgroundColor))
      .overlay(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
      )
  }

  // MARK: - Trigger labels

  private var triggerTitle: String {
    if prefs.appLanguage == .system {
      return localizedString("settings.general.language.system", locale: displayLocale)
    }
    return prefs.appLanguage.nativeName
  }

  private var triggerSubtitle: String {
    switch prefs.appLanguage {
    case .system:
      return systemFollowingSummary
    default:
      let translated = prefs.appLanguage.translatedName(in: displayLocale)
      if translated == prefs.appLanguage.nativeName {
        return languageActiveCaption
      }
      return "\(translated) · \(languageActiveCaption)"
    }
  }

  private var languageActiveCaption: String {
    guard prefs.appLanguage != .system else { return "" }
    return localizedString(dynamicKey: prefs.appLanguage.captionKey, locale: displayLocale)
  }

  private var systemFollowingSummary: String {
    let format = localizedString("settings.general.language.caption.system", locale: displayLocale)
    return String(format: format, locale: displayLocale, systemLanguageDisplayName)
  }

  private var systemLanguageDisplayName: String {
    // Reuse `.system`'s locale resolver - it reads the global preferences scope
    // via CFPreferences, bypassing this app's container `AppleLanguages`
    // override so we surface the *real* macOS system language even when the
    // user has the app forced to a different one.
    let systemLocale = AppLanguage.system.locale
    let code = systemLocale.language.languageCode?.identifier ?? "en"
    return displayLocale.localizedString(forLanguageCode: code) ?? code
  }

  // MARK: - Caption (under preview)

  private var captionText: String {
    if prefs.appLanguage == .system {
      return systemFollowingSummary
    }
    return localizedString(dynamicKey: prefs.appLanguage.captionKey, locale: displayLocale)
  }

  // MARK: - Actions

  private func handleSelect(_ language: AppLanguage) {
    prefs.appLanguage = language
    isPopoverOpen = false
  }
}

// MARK: - Popover content

private struct LanguagePopoverContent: View {
  @Bindable var prefs: Preferences
  let displayLocale: Locale
  let onSelect: (AppLanguage) -> Void

  @State private var searchText = ""
  @FocusState private var isSearchFocused: Bool

  private var filteredLanguages: [AppLanguage] {
    AppLanguage.concreteCases.filter {
      $0.matches(searchQuery: searchText, in: displayLocale)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      searchField
      Divider()

      ScrollView {
        VStack(spacing: 0) {
          LanguageRow(
            language: .system,
            title: localizedString("settings.general.language.system", locale: displayLocale),
            subtitle: systemSubtitle,
            isSelected: prefs.appLanguage == .system,
            action: { onSelect(.system) }
          )

          Divider()
            .padding(.horizontal, 8)

          if filteredLanguages.isEmpty {
            Text("settings.general.language.search.noResults")
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 18)
          } else {
            ForEach(filteredLanguages, id: \.self) { lang in
              LanguageRow(
                language: lang,
                title: lang.nativeName,
                subtitle: subtitle(for: lang),
                isSelected: prefs.appLanguage == lang,
                action: { onSelect(lang) }
              )
            }
          }
        }
        .padding(4)
      }
    }
    .frame(width: 340)
    .frame(maxHeight: 360)
    .environment(\.layoutDirection, displayLocale.preferredLayoutDirection)
    .environment(\.locale, displayLocale)
    .background(.regularMaterial)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        isSearchFocused = true
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.tertiary)

      TextField(
        localizedString("settings.general.language.searchPlaceholder", locale: displayLocale),
        text: $searchText
      )
      .textFieldStyle(.plain)
      .multilineTextAlignment(.leading)
      .font(.system(size: 12))
      .focused($isSearchFocused)
      .onSubmit(submitFirstMatch)

      if !searchText.isEmpty {
        Button {
          searchText = ""
          isSearchFocused = true
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 12))
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 9)
    .contentShape(Rectangle())
    .onTapGesture { isSearchFocused = true }
  }

  private func subtitle(for language: AppLanguage) -> String? {
    let translated = language.translatedName(in: displayLocale)
    return translated == language.nativeName ? nil : translated
  }

  private var systemSubtitle: String {
    let format = localizedString("settings.general.language.caption.system", locale: displayLocale)
    let systemName = systemLanguageDisplayName
    return String(format: format, locale: displayLocale, systemName)
  }

  private var systemLanguageDisplayName: String {
    // Reuse `.system`'s locale resolver - it reads the global preferences scope
    // via CFPreferences, bypassing this app's container `AppleLanguages`
    // override so we surface the *real* macOS system language even when the
    // user has the app forced to a different one.
    let systemLocale = AppLanguage.system.locale
    let code = systemLocale.language.languageCode?.identifier ?? "en"
    return displayLocale.localizedString(forLanguageCode: code) ?? code
  }

  private func submitFirstMatch() {
    if let first = filteredLanguages.first {
      onSelect(first)
    }
  }
}

// MARK: - LanguageRow

private struct LanguageRow: View {
  let language: AppLanguage
  let title: String
  let subtitle: String?
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        LanguageGlyphBadge(language: language, isSelected: isSelected)

        VStack(alignment: .leading, spacing: 1) {
          Text(title)
            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(.primary)
          if let subtitle, !subtitle.isEmpty {
            Text(subtitle)
              .font(.system(size: 10))
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }

        Spacer(minLength: 8)

        if isSelected {
          Image(systemName: "checkmark")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 5)
      .background(rowBackground)
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .animation(.easeOut(duration: 0.1), value: isHovered)
    .animation(.snappy(duration: 0.18), value: isSelected)
  }

  @ViewBuilder
  private var rowBackground: some View {
    if isSelected {
      Color.accentColor.opacity(0.10)
    } else if isHovered {
      Color.secondary.opacity(0.08)
    } else {
      Color.clear
    }
  }
}

// MARK: - LanguageGlyphBadge

private struct LanguageGlyphBadge: View {
  let language: AppLanguage
  let isSelected: Bool

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 7, style: .continuous)
        .fill(backgroundColor)
        .overlay(
          RoundedRectangle(cornerRadius: 7, style: .continuous)
            .strokeBorder(borderColor, lineWidth: 1)
        )
      glyphContent
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
    }
    .frame(width: 32, height: 32)
    .environment(\.layoutDirection, .leftToRight)
  }

  @ViewBuilder
  private var glyphContent: some View {
    if language == .system {
      Image(systemName: "gearshape")
        .font(.system(size: 15, weight: .light))
    } else {
      Text(verbatim: language.glyphText)
        .font(language.glyphFontName.map { .custom($0, size: 17) } ?? .system(size: 17))
    }
  }

  private var backgroundColor: Color {
    isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06)
  }

  private var borderColor: Color {
    isSelected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.15)
  }
}
