import Foundation

extension Notification.Name {
  static let locationDidUpdate = Notification.Name("locationDidUpdate")
  static let locationDidFail = Notification.Name("locationDidFail")
  static let startLocationUpdate = Notification.Name("startLocationUpdate")
  static let stopLocationUpdate = Notification.Name("stopLocationUpdate")
}
