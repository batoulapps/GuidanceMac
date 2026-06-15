import SwiftUI

/// An inline, non-interruptive failure notice that mirrors the Label idiom used
/// across the settings tabs (notification permission, login item, custom sound).
/// Mount it inside a `Form`/`Section`; the caller supplies an already-localized
/// message so it re-localizes correctly when the app language changes.
struct InlineNoticeLabel: View {
  let message: String

  var body: some View {
    Label {
      Text(message)
    } icon: {
      Image(systemName: "exclamationmark.triangle.fill")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}
