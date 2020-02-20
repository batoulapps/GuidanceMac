//
//  PrayerTimes.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 12/7/19.
//  Copyright © 2019 Batoul Apps. All rights reserved.
//

import Foundation
import Adhan

extension PrayerTimes {
    static func userPrayerTimes(for date: Date = Date()) -> PrayerTimes? {
        let calendar = Calendar(identifier: .gregorian)
        let coordinates = Coordinates(latitude: 40.781340, longitude: -73.966568)
        let calculationParameters = CalculationMethod.muslimWorldLeague.params
        return PrayerTimes(coordinates: coordinates,
                           date: calendar.dateComponents([.year, .month, .day], from: date),
                           calculationParameters: calculationParameters)
    }
}
