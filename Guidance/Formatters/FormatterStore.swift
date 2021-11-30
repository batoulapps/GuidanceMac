//
//  FormatterStore.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/23/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation
import Then

func Localized(_ key: String, comment: String? = nil) -> String {
    return NSLocalizedString(key, comment: comment ?? "")
}

func Arabic(_ key: String, comment: String? = nil) -> String {
    guard let path = Bundle.main.path(forResource: "ar", ofType: "lproj"), let bundle = Bundle(path: path) else {
        return Localized(key)
    }
    return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
}

class FormatterStore {
    static var shared = FormatterStore()
    
    static func reload() {
        shared = FormatterStore()
    }

    fileprivate let gregorianCalendar = Calendar(identifier: .gregorian)
    fileprivate let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    fileprivate let weekdayPlaceholder = "\u{200B}"
    
    fileprivate lazy var numberFormatter = NumberFormatter().then {
        $0.numberStyle = .decimal
    }
    
    fileprivate lazy var positiveNumberFormatter = NumberFormatter().then {
        $0.numberStyle = .decimal
        $0.positivePrefix = $0.plusSign
    }
    
    fileprivate lazy var angleFormatter = NumberFormatter().then {
        $0.numberStyle = .decimal
        $0.maximumFractionDigits = 1
        $0.minimumFractionDigits = 1
    }
    
    fileprivate lazy var minuteCountdownFormatter = DateComponentsFormatter().then {
        $0.allowedUnits = [.hour, .minute]
        $0.unitsStyle = .short
        if Preferences.arabicOverride {
            var cal = Calendar(identifier: .gregorian)
            cal.locale = FormatterStore.arabicOverrideLocale()
            $0.calendar = cal
        }
    }

    fileprivate lazy var fullCountdownFormatter = DateComponentsFormatter().then {
        $0.allowedUnits = [.hour, .minute, .second]
        $0.unitsStyle = .spellOut
        if Preferences.arabicOverride {
            var cal = Calendar(identifier: .gregorian)
            cal.locale = FormatterStore.arabicOverrideLocale()
            $0.calendar = cal
        }
    }

    fileprivate lazy var minuteFormatter = DateComponentsFormatter().then {
        $0.allowedUnits = [.minute]
        $0.unitsStyle = .full
        if Preferences.arabicOverride {
            var cal = Calendar(identifier: .gregorian)
            cal.locale = FormatterStore.arabicOverrideLocale()
            $0.calendar = cal
        }
    }
    
    fileprivate lazy var secondCountdownFormatter = DateComponentsFormatter().then {
        $0.allowedUnits = [.minute, .second]
        $0.unitsStyle = .short
        if Preferences.arabicOverride {
            var cal = Calendar(identifier: .gregorian)
            cal.locale = FormatterStore.arabicOverrideLocale()
            $0.calendar = cal
        }
    }
    
    fileprivate lazy var hijriDateFormatter = DateFormatter().then {
        $0.calendar = Calendar.hijri
        let formatString = DateFormatter.dateFormat(fromTemplate: "EEEE, MMMM d, yyyy", options: 0, locale: Locale.autoupdatingCurrent)
        $0.dateFormat = formatString?.replacingOccurrences(of: "EEEE", with: weekdayPlaceholder)
    }

    fileprivate lazy var weekdayFormatter = DateFormatter().then {
        $0.calendar = Calendar.gregorian
        $0.dateFormat = "EEEE"
    }

    fileprivate lazy var calendarDateFormatter = DateFormatter().then {
        $0.calendar = Calendar.gregorian
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "EE, MMMM d", options: 0, locale: Locale.autoupdatingCurrent)
    }

    fileprivate lazy var calendarMonthFormatter = DateFormatter().then {
        $0.calendar = Calendar.gregorian
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: Locale.autoupdatingCurrent)
    }

    fileprivate lazy var hijriArabicMonthFormatter = DateFormatter().then {
        $0.calendar = Calendar.hijri
        $0.dateFormat = "MMMM"
        $0.locale = Locale(identifier: "ar")
    }

    fileprivate lazy var hijriLocalMonthFormatter = DateFormatter().then {
        $0.calendar = Calendar.hijri
        $0.dateFormat = "MMMM"
    }
    
    fileprivate lazy var shortHijriDateFormatter = DateFormatter().then {
        $0.calendar = Calendar.hijri
        $0.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM d", options: 0, locale: Locale.autoupdatingCurrent)
    }
    
    private var prayerFormatter = PrayerFormatter(timeZoneIdentifier: AppDefaults.timeZone)
    
    fileprivate var currentPrayerFormatter: PrayerFormatter {
        if prayerFormatter.timeZoneIdentifier != AppDefaults.timeZone {
            prayerFormatter = PrayerFormatter(timeZoneIdentifier: AppDefaults.timeZone)
        }
        
        return prayerFormatter
    }
    
    fileprivate static func arabicOverrideLocale() -> Locale {
        var localeComponents: [String : String] = [NSLocale.Key.languageCode.rawValue : "ar", "numbers": "latn"]
        if let regionCode = Locale.current.regionCode {
            localeComponents[NSLocale.Key.countryCode.rawValue] = regionCode
        }
        return Locale(identifier: Locale.identifier(fromComponents: localeComponents))
    }
}

extension Calendar {
    static var gregorian: Calendar {
        return FormatterStore.shared.gregorianCalendar
    }
    
    static var hijri: Calendar {
        return FormatterStore.shared.hijriCalendar
    }
}

extension Date {
    func formattedCalendarDate() -> String {
        return FormatterStore.shared.calendarDateFormatter.string(from: self)
    }

    func formattedCalendarMonth() -> String {
        return FormatterStore.shared.calendarMonthFormatter.string(from: self)
    }

    func formattedPrayerTime() -> String {
        return FormatterStore.shared.currentPrayerFormatter.formatter.string(from: self)
    }
    
    func formattedShortPrayerTime() -> String {
        return FormatterStore.shared.currentPrayerFormatter.shortFormatter.string(from: self)
    }
    
    func formattedPeriodPrayerTime() -> String {
        return FormatterStore.shared.currentPrayerFormatter.periodFormatter.string(from: self)
    }
    
    func formattedHijriDate(actualDate: Date) -> String {
        let hijriString = FormatterStore.shared.hijriDateFormatter.string(from: self)
        let weekdayString = FormatterStore.shared.weekdayFormatter.string(from: actualDate)
        return hijriString.replacingOccurrences(of: FormatterStore.shared.weekdayPlaceholder, with: weekdayString)
    }

    func voiceOverHijriDate() -> String {
        let formattedDate = FormatterStore.shared.hijriDateFormatter.string(from: self)
        let localMonth = FormatterStore.shared.hijriLocalMonthFormatter.string(from: self)
        let arabicMonth = FormatterStore.shared.hijriArabicMonthFormatter.string(from: self)
        return formattedDate.replacingOccurrences(of: localMonth, with: arabicMonth)
    }
    
    func formattedShortHijriDate() -> String {
        return FormatterStore.shared.shortHijriDateFormatter.string(from: self)
    }
    
    func formattedMinuteCountdown(until: Date) -> String {
        let components = Calendar.gregorian.dateComponents([.hour, .minute, .second], from: self, to: until)
        return FormatterStore.shared.minuteCountdownFormatter.string(from: components) ?? ""
    }
    
    func formattedSecondCountdown(until: Date) -> String {
        return FormatterStore.shared.secondCountdownFormatter.string(from: self, to: until) ?? ""
    }
    
    func formattedVariableCountdown(until: Date, secondThreshold: TimeInterval = 600) -> String {
        if until.timeIntervalSince(self) >= secondThreshold {
            return self.formattedMinuteCountdown(until: until)
        } else {
            return self.formattedSecondCountdown(until: until)
        }
    }

    func formattedFullCountdown(until: Date) -> String {
        return FormatterStore.shared.fullCountdownFormatter.string(from: self, to: until) ?? ""
    }
}

extension DateComponents {
    func formattedMinutes() -> String {
        return FormatterStore.shared.minuteFormatter.string(from: self) ?? ""
    }
}

extension Int {
    func formatted() -> String {
        return FormatterStore.shared.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    func formattedPositive() -> String {
        if self == 0 {
            return FormatterStore.shared.numberFormatter.string(from: NSNumber(value: self)) ?? ""
        }
        return FormatterStore.shared.positiveNumberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension Double {
    func formattedAngle() -> String {
        return FormatterStore.shared.angleFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension String {
    func formattedTimeZone() -> String {
        return (self.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ")) ?? self
    }
}

extension TimeZone {
    func formattedIdentifier() -> String {
        return identifier.formattedTimeZone()
    }
}
