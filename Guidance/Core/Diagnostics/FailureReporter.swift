import Foundation
import Observation
import OSLog

/// A failure worth surfacing to the user once. UI reads
/// `FailureReporter.shared.currentNotice`.
struct FailureNotice: Identifiable, Sendable {
  let id = UUID()
  let domain: NoticeDomain
  let category: FailureCategory
  let messageKey: String.LocalizationValue

  /// Re-resolved on each access so it follows live app-language changes.
  @MainActor var message: String { localizedString(messageKey, locale: .app) }
}

/// Which UI surface a notice belongs to, so a settings tab can show only its own
/// domain while the popover and menu bar react app-wide.
enum NoticeDomain: Sendable {
  case location
  case prayerCalc
}

/// The one place that decides how a failure reaches the user. It logs every
/// failure, then routes by (category x is-the-user-waiting): a transient
/// background failure stays silent and self-heals; a terminal failure always
/// surfaces - but never as a modal. Mirrors the `Preferences.shared` singleton
/// shape, observed by SwiftUI.
@MainActor
@Observable
final class FailureReporter {
  static let shared = FailureReporter()
  private init() {}

  /// The single notice currently worth showing. `nil` = nothing to show.
  private(set) var currentNotice: FailureNotice?

  /// Stable identity of the current notice's cause, so the same failure posted
  /// repeatedly (e.g. `denied` fired by two delegate callbacks) surfaces once.
  private var currentCauseKey: String?

  /// Logs the failure, then applies the surfacing policy.
  /// - Parameter waiting: is a user actively waiting for this result
  ///   (foreground / user-initiated) vs background/automatic?
  func report(_ failure: some AppFailure, waiting: Bool, domain: NoticeDomain) {
    AppLog.log(failure, to: logger(for: domain))

    switch (failure.category, waiting) {
    case (.cosmetic, _), (.transient, false):
      break  // log only; a transient background failure self-heals
    case (.transient, true), (.terminal, _):
      let key = failure.logMessage
      guard key != currentCauseKey else { return }
      currentCauseKey = key
      currentNotice = FailureNotice(
        domain: domain, category: failure.category, messageKey: failure.messageKey)
    }
  }

  /// Clears the notice for a domain once its condition recovers (e.g. location
  /// resolved, permission granted).
  func clearNotice(_ domain: NoticeDomain) {
    guard currentNotice?.domain == domain else { return }
    currentNotice = nil
    currentCauseKey = nil
  }

  private func logger(for domain: NoticeDomain) -> Logger {
    switch domain {
    case .location: AppLog.location
    case .prayerCalc: AppLog.prayer
    }
  }
}
