//
//  Calendar.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/30/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation

extension Calendar {
    static func userHijriDate(for date: Date = Date()) -> Date {
        return Calendar.hijri.date(byAdding: DateComponents(day: AppDefaults.hijriOffset), to: date) ?? date
    }
}

extension Date {
    func nextDay() -> Date {
        return Calendar.gregorian.date(byAdding: .day, value: 1, to: self) ?? Date()
    }
}
