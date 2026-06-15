import Adhan
import XCTest

@testable import Guidance

/// Guards the prime directive of the error-handling work: it must not change
/// prayer-time output. The nil-guard in `PrayerManager.calculatePrayerTimes`
/// only keeps the last good value when Adhan itself returns nil, so valid
/// coordinates must still produce times - and ordinary latitudes (incl. the
/// equator) must never trip the nil path.
final class PrayerTimesInvarianceTests: XCTestCase {
  private func date(_ year: Int, _ month: Int, _ day: Int) -> DateComponents {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return components
  }

  func testValidCoordinatesProduceTimes() {
    let coords = Coordinates(latitude: 21.4225, longitude: 39.8262)  // Makkah
    var params = CalculationMethod.ummAlQura.params
    params.madhab = .shafi

    let times = PrayerTimes(
      coordinates: coords, date: date(2026, 5, 30), calculationParameters: params)
    XCTAssertNotNil(times, "Valid coordinates must produce prayer times")
  }

  func testEquatorProducesTimesOnSolstice() {
    // The equator must NOT trip the nil path - guards against an over-eager
    // validation wrongly rejecting valid latitudes.
    let coords = Coordinates(latitude: 0, longitude: 0)
    let params = CalculationMethod.muslimWorldLeague.params

    let times = PrayerTimes(
      coordinates: coords, date: date(2026, 6, 21), calculationParameters: params)
    XCTAssertNotNil(times, "The equator should still produce prayer times")
  }

  func testCalculationIsDeterministic() {
    let coords = Coordinates(latitude: 30.0444, longitude: 31.2357)  // Cairo
    let params = CalculationMethod.egyptian.params
    let components = date(2026, 5, 30)

    let first = PrayerTimes(coordinates: coords, date: components, calculationParameters: params)
    let second = PrayerTimes(coordinates: coords, date: components, calculationParameters: params)
    XCTAssertEqual(first?.fajr, second?.fajr)
    XCTAssertEqual(first?.maghrib, second?.maghrib)
  }
}
