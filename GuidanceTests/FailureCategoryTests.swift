import XCTest

@testable import Guidance

/// Locks the failure taxonomy that drives the whole surfacing policy: if these
/// mappings drift, transient failures could start interrupting the user (or
/// terminal ones could go silent).
final class FailureCategoryTests: XCTestCase {
  func testLocationFailureCategoryMapping() {
    XCTAssertEqual(LocationFailure.denied.category, .terminal)
    XCTAssertEqual(LocationFailure.restricted.category, .terminal)
    XCTAssertEqual(LocationFailure.network.category, .transient)
    XCTAssertEqual(LocationFailure.unavailable.category, .transient)
  }

  func testPrayerCalcFailureIsTerminal() {
    XCTAssertEqual(
      PrayerCalcFailure.timesUnavailable(latitude: 0, longitude: 0).category, .terminal)
  }

  func testEveryLocationFailureLogsADistinctCause() {
    let causes: [LocationFailure] = [.denied, .restricted, .network, .unavailable]
    let messages = causes.map(\.logMessage)
    XCTAssertEqual(
      Set(messages).count, causes.count, "Each location failure should log a distinct cause")
  }
}
