import XCTest

@testable import Guidance

/// Contract for the single shared timer formatter used by the menu bar and every
/// widget size. Guards the three tiers (seconds / minutes / clock h:mm), the
/// floor (not ceil) boundary behavior, the count-up "+" prefix, localized digits,
/// and the optional FSI/PDI bidi wrap.
///
/// NOTE: this project does not yet define a unit-test target (only `Guidance` and
/// `GuidanceWidgetsExtension` exist), so these cases are not run by
/// `xcodebuild test` today; they are the canonical home for the formatter
/// contract and will join the suite once a test target is wired. The same
/// assertions were validated standalone on the Foundation runtime during
/// development.
final class RelativeDurationFormatterTests: XCTestCase {
  private let en = Locale(identifier: "en")

  /// Arabic with the Arabic-Indic numbering system applied, mirroring how the app
  /// (`Locale.app`) and the widget (`GuidanceWidgetSnapshot.resolvedLocale`) build
  /// the locale they hand the formatter.
  private var ar: Locale {
    var c = Locale.Components(locale: Locale(identifier: "ar"))
    c.numberingSystem = Locale.NumberingSystem("arab")
    return Locale(components: c)
  }

  private func down(_ s: TimeInterval, _ loc: Locale) -> String {
    RelativeDurationFormatter.string(seconds: s, direction: .down, locale: loc)
  }
  private func up(_ s: TimeInterval, _ loc: Locale) -> String {
    RelativeDurationFormatter.string(seconds: s, direction: .up, locale: loc)
  }

  func testEnglishTiersAndBoundaries() {
    XCTAssertEqual(down(0, en), "0s")
    XCTAssertEqual(down(1, en), "1s")
    XCTAssertEqual(down(59, en), "59s")
    XCTAssertEqual(down(60, en), "1m")        // 60s crosses into the minutes tier
    XCTAssertEqual(down(61, en), "1m")        // floors, never rounds up
    XCTAssertEqual(down(3599, en), "59m")
    XCTAssertEqual(down(3600, en), "1:00")    // clock tier, minutes zero-padded
    XCTAssertEqual(down(3661, en), "1:01")
    XCTAssertEqual(down(10_140, en), "2:49")  // 2h49m
  }

  func testCountUpPrefix() {
    XCTAssertEqual(up(45, en), "+45s")
    XCTAssertEqual(up(16 * 60, en), "+16m")
    XCTAssertEqual(up(10_140, en), "+2:49")
  }

  func testArabicDigitsUnitsAndPrefix() {
    XCTAssertEqual(down(49 * 60, ar), "٤٩د")
    XCTAssertEqual(down(10_140, ar), "٢:٤٩")
    XCTAssertEqual(down(3600, ar), "١:٠٠")
    XCTAssertEqual(up(45, ar), "+٤٥ث")
  }

  func testNegativeIntervalClampsToZero() {
    XCTAssertEqual(down(-5, en), "0s")
  }

  func testBidiIsolationWrap() {
    XCTAssertEqual(
      RelativeDurationFormatter.string(seconds: 3600, direction: .down, locale: en, bidiIsolated: true),
      "\u{2068}1:00\u{2069}")
  }
}
