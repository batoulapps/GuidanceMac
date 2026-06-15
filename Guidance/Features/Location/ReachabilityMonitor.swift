import Foundation
import Network

/// Watches network reachability and fires `onBecameSatisfied` on the
/// offline -> online rising edge, so a pending reverse-geocode can be retried
/// once (approach B) rather than polling on a timer. `NWPathMonitor` delivers on
/// a background queue, so every state read/write and the callback hop to the
/// main actor. Edge-triggered: a flaky link that flips satisfied->unsatisfied->
/// satisfied fires once per rising edge, never a hot loop.
@MainActor
final class ReachabilityMonitor {
  private(set) var isOnline = true  // optimistic until the first path update
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "com.batoulapps.GuidanceMac.reachability")
  private var started = false

  /// Invoked on the main actor each time the path flips unsatisfied -> satisfied.
  var onBecameSatisfied: (@MainActor () -> Void)?

  func start() {
    guard !started else { return }
    started = true
    monitor.pathUpdateHandler = { [weak self] path in
      let satisfied = path.status == .satisfied
      Task { @MainActor in
        guard let self else { return }
        let wasOnline = self.isOnline
        self.isOnline = satisfied
        if satisfied && !wasOnline {
          self.onBecameSatisfied?()
        }
      }
    }
    monitor.start(queue: queue)
  }

  func stop() {
    monitor.cancel()
    started = false
  }
}
