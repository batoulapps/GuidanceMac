//
//  PrayerFormatter.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/23/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation

struct PrayerFormatter {
    let timeZoneIdentifier: String
    let formatter: DateFormatter
    let shortFormatter: DateFormatter
    let periodFormatter: DateFormatter
    
    init(timeZoneIdentifier: String) {
        formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
        
        shortFormatter = DateFormatter()
        var timeFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: Locale.autoupdatingCurrent) ?? "h:mm"
        timeFormat = timeFormat.replacingOccurrences(of: "a", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        shortFormatter.dateFormat = timeFormat
        shortFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
        
        periodFormatter = DateFormatter()
        periodFormatter.dateFormat = "a"
        periodFormatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
        
        self.timeZoneIdentifier = formatter.timeZone.identifier
    }
}
