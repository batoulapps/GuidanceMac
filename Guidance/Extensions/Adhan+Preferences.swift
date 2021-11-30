//
//  Adhan+Preferences.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/30/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation
import Adhan

extension Prayer {
    var voiceOverName: String {
        switch self {
        case .fajr:
            return Arabic("Fajr")
        case .sunrise:
            return localizedName(allowArabicOveride: true)
        case .dhuhr:
            return Arabic("Dhuhr")
        case .asr:
            return Arabic("Asr")
        case .maghrib:
            return Arabic("Maghrib")
        case .isha:
            return Arabic("Isha")
        }
    }

    func localizedName(allowArabicOveride: Bool = true) -> String {
        let forceArabic = allowArabicOveride && Preferences.arabicOverride
        switch self {
        case .fajr:
            return forceArabic ? "\(Arabic("Fajr"))\u{200F}" : Localized("Fajr")
        case .sunrise:
            return forceArabic ? "\(Arabic("Sunrise"))\u{200F}" : Localized("Sunrise")
        case .dhuhr:
            return forceArabic ? "\(Arabic("Dhuhr"))\u{200F}" : Localized("Dhuhr")
        case .asr:
            return forceArabic ? "\(Arabic("Asr"))\u{200F}" : Localized("Asr")
        case .maghrib:
            return forceArabic ? "\(Arabic("Maghrib"))\u{200F}" : Localized("Maghrib")
        case .isha:
            return forceArabic ? "\(Arabic("Isha"))\u{200F}" : Localized("Isha")
        }
    }
    
    func localizedShortName(allowArabicOveride: Bool = true) -> String {
        let forceArabic = allowArabicOveride && Preferences.arabicOverride
        switch self {
        case .fajr:
            return forceArabic ? "\(Arabic("FAJR"))\u{200F}" : Localized("FAJR")
        case .sunrise:
            return forceArabic ? "\(Arabic("RISE"))\u{200F}" : Localized("RISE")
        case .dhuhr:
            return forceArabic ? "\(Arabic("DUHR"))\u{200F}" : Localized("DUHR")
        case .asr:
            return forceArabic ? "\(Arabic("ASR"))\u{200F}" : Localized("ASR")
        case .maghrib:
            return forceArabic ? "\(Arabic("MGRB"))\u{200F}" : Localized("MGRB")
        case .isha:
            return forceArabic ? "\(Arabic("ISHA"))\u{200F}" : Localized("ISHA")
        }
    }

    var adjustmentValue: Int {
        switch self {
        case .fajr:
            return AppDefaults.fajrAdjustment
        case .sunrise:
            return AppDefaults.sunriseAdjustment
        case .dhuhr:
            return AppDefaults.dhuhrAdjustment
        case .asr:
            return AppDefaults.asrAdjustment
        case .maghrib:
            return AppDefaults.maghribAdjustment
        case .isha:
            return AppDefaults.ishaAdjustment
        }
    }
}

extension PrayerTimes {
    static func userPrayerTimes(for date: Date = Date()) -> PrayerTimes? {
        return PrayerTimes(coordinates: Coordinates.userCoordinates(),
                           date: Calendar.gregorian.dateComponents([.year, .month, .day], from: date),
                           calculationParameters: CalculationParameters.userCalculationParameters(for: date))
    }
}

extension CalculationParameters {
    static func userCalculationParameters(for date: Date) -> CalculationParameters {
        var params = CalculationMethod.userCalculationMethod().params
        if params.method == .other {
            params.fajrAngle = AppDefaults.customFajrAngle
            params.ishaAngle = AppDefaults.customIshaAngle
        }
        
        params.madhab = Madhab.userMadhab()
        params.highLatitudeRule = HighLatitudeRule.userHighLatitudeRule()
        params.adjustments = PrayerAdjustments.userPrayerAdjustments()
        
        if params.ishaInterval > 0 && AppDefaults.delayedIshaInRamadan {
            if Calendar.hijri.component(.month, from: Calendar.userHijriDate(for: date)) == 9 {
                params.ishaInterval = 120
            }
        }
        
        return params
    }
}

extension CalculationMethod {
    static func userCalculationMethod() -> CalculationMethod {
        return methodForPreference(AppDefaults.method)
    }
    
    static func methodForPreference(_ method: Preferences.Method) -> CalculationMethod {
        switch method {
        case .egyptian:
            return .egyptian
        case .karachi:
            return .karachi
        case .northAmerica:
            return .northAmerica
        case .muslimWorldLeague:
            return .muslimWorldLeague
        case .ummAlQurra:
            return .ummAlQura
        case .dubai:
            return .dubai
        case .moonsightingCommittee:
            return .moonsightingCommittee
        case .custom:
            return .other
        case .kuwait:
            return .kuwait
        case .qatar:
            return .qatar
        case .singapore:
            return .singapore
        case .tehran:
            return .tehran
        }
    }
}

extension Madhab {
    static func userMadhab() -> Madhab {
        switch AppDefaults.madhab {
        case .shafi:
            return .shafi
        case .hanafi:
            return .hanafi
        }
    }
}

extension HighLatitudeRule {
    static func userHighLatitudeRule() -> HighLatitudeRule {
        switch AppDefaults.highLatitudeRule {
        case .middleOfTheNight:
            return .middleOfTheNight
        case .seventhOfTheNight:
            return .seventhOfTheNight
        case .angleBased:
            return .twilightAngle
        }
    }
}

extension PrayerAdjustments {
    static func userPrayerAdjustments() -> PrayerAdjustments {
        return PrayerAdjustments(fajr: AppDefaults.fajrAdjustment,
                                 sunrise: AppDefaults.sunriseAdjustment,
                                 dhuhr: AppDefaults.dhuhrAdjustment,
                                 asr: AppDefaults.asrAdjustment,
                                 maghrib: AppDefaults.maghribAdjustment,
                                 isha: AppDefaults.ishaAdjustment)
    }
}

extension Coordinates {
    static func userCoordinates() -> Coordinates {
        return Coordinates(latitude: AppDefaults.latitude, longitude: AppDefaults.longitude)
    }
}
