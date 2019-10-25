//
//  Formatter.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 10/29/16.
//  Copyright © 2016 Batoul Apps. All rights reserved.
//

import Cocoa

class Formatter: NSObject {
    fileprivate var _store = FormatterStore(locale: Localizer.locale(), timezone: TimeZone(identifier: BASwifty.currentTimeZoneIdentifier())!)
    
    fileprivate var store: FormatterStore {
        if _store.locale.identifier != Localizer.locale().identifier || _store.timezone.identifier != BASwifty.currentTimeZoneIdentifier() {
            self.reload()
        }
        
        return _store
    }
    
    static let shared = Formatter()
    
    func reload() {
        _store = FormatterStore(locale: Localizer.locale(), timezone: TimeZone(identifier: BASwifty.currentTimeZoneIdentifier())!)
    }
    
    @objc class func gregorianCalendar() -> Calendar {
        return Formatter.shared.store.gregorianCalendar
    }
    
    @objc class func hijriCalendar() -> Calendar {
        return Formatter.shared.store.hijriCalendar
    }
    
    @objc class func formattedTime(date: Date) -> String {
        return Formatter.shared.store.timeFormatter.string(from: date)
    }
    
    @objc class func formattedPeriod(date: Date) -> String {
        return Formatter.shared.store.periodFormatter.string(from: date)
    }
    
    @objc class func formattedHijriDay(date: Date) -> String {
        return Formatter.shared.store.hijriDayFormatter.string(from: date)
    }
    
    @objc class func formattedHijriMonth(date: Date) -> String {
        return Formatter.shared.store.hijriMonthFormatter.string(from: date)
    }
    
    @objc class func formattedHijriYear(date: Date) -> String {
        return Formatter.shared.store.hijriYearFormatter.string(from: date)
    }
    
    @objc class func formattedInteger(int: Int) -> String {
        return Formatter.shared.store.intFormatter.string(from: NSNumber(integerLiteral: int)) ?? ""
    }
}

fileprivate class FormatterStore {
    fileprivate let locale: Locale
    fileprivate let timezone: TimeZone
    
    fileprivate let gregorianCalendar = Calendar(identifier: .gregorian)
    fileprivate let hijriCalendar: Calendar = {
        if #available(OSX 10.10, *) {
            return Calendar(identifier: .islamicUmmAlQura)
        }
        return Calendar(identifier: .islamic)
    }()
    
    fileprivate init(locale: Locale, timezone: TimeZone) {
        self.locale = locale
        self.timezone = timezone
    }
    
    lazy var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm a", options: 0, locale: Locale.current)
        f.locale = self.locale
        f.timeZone = self.timezone
        return f
    }()
    
    lazy var hijriDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd"
        f.locale = self.locale
        f.timeZone = self.timezone
        f.calendar = self.hijriCalendar
        return f
    }()
    
    lazy var hijriMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        f.locale = self.locale
        f.timeZone = self.timezone
        f.calendar = self.hijriCalendar
        return f
    }()
    
    lazy var hijriYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY"
        f.locale = self.locale
        f.timeZone = self.timezone
        f.calendar = self.hijriCalendar
        return f
    }()
    
    lazy var intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = self.locale
        f.numberStyle = .decimal
        return f
    }()
    
    lazy var periodFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "a"
        f.locale = self.locale
        return f
    }()
}
