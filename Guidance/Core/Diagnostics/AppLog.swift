import Foundation
import OSLog

/// Central unified-logging facility: one subsystem (the bundle id - the same
/// string the per-feature loggers used before, so existing Console filters keep
/// working) and a fixed set of category loggers. `Logger` is `Sendable`, so
/// these are safe to reference from any isolation.
enum AppLog {
  private static let subsystem = Bundle.main.bundleIdentifier ?? "Guidance"

  static let location = Logger(subsystem: subsystem, category: "Location")
  static let prayer = Logger(subsystem: subsystem, category: "Prayer")
  static let preferences = Logger(subsystem: subsystem, category: "Preferences")
  static let migration = Logger(subsystem: subsystem, category: "Migration")
  static let notifications = Logger(subsystem: subsystem, category: "Notifications")
  static let audio = Logger(subsystem: subsystem, category: "Audio")

  /// Emits a failure's diagnostic line (plus its underlying error, if any) to
  /// the given category logger.
  static func log(_ failure: some AppFailure, to logger: Logger) {
    if let underlying = failure.underlyingError {
      logger.error(
        "\(failure.logMessage, privacy: .public): \(underlying.localizedDescription, privacy: .public)"
      )
    } else {
      logger.error("\(failure.logMessage, privacy: .public)")
    }
  }
}
