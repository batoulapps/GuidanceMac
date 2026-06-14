import Foundation

extension Int {
  func localizedDigits(minDigits: Int = 1, locale: Locale = .app) -> String {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.minimumIntegerDigits = minDigits
    formatter.usesGroupingSeparator = false
    return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
  }
}

extension String {
  var bidiIsolated: String {
    "\u{2068}\(self)\u{2069}"
  }
}
