//
//  DefaultKey.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/27/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation

enum DefaultKey: String {
    
    case autoDetectLocation = "kBAUserDefaultsAutoLocation"
    case latitude = "kBAUserDefaultsLatitude"
    case longitude = "kBAUserDefaultsLongitude"
    case city = "kBAUserDefaultsLocationCity"
    case state = "kBAUserDefaultsLocationState"
    case country = "kBAUserDefaultsLocationCountry"
    case timeZone = "kBAUserDefaultsTimeZone"

    // MARK: Calculation

    case autoDetectMethod = "kBAUserDefaultsAutoDetectMethod"
    case autoDetectHighLatRule = "kBAUserDefaultsAutoDetectHighLatitudeRule"
    case madhab = "kBAUserDefaultsMadhab"
    case method = "kBAUserDefaultsMethod"
    case highLatitudeRule = "kBAUserDefaultsHighLatitudeRule"
    case fajrAdjustment = "kBAUserDefaultsAdjustmentFajr"
    case sunriseAdjustment = "kBAUserDefaultsAdjustmentShuruq"
    case dhuhrAdjustment = "kBAUserDefaultsAdjustmentDhuhr"
    case asrAdjustment = "kBAUserDefaultsAdjustmentAsr"
    case maghribAdjustment = "kBAUserDefaultsAdjustmentMaghrib"
    case ishaAdjustment = "kBAUserDefaultsAdjustmentIsha"
    case customFajrAngle = "kBAUserDefaultsCustomFajrAngle"
    case customIshaAngle = "kBAUserDefaultsCustomIshaAngle"
    case hijriOffset = "kBAUserDefaultsHijriOffset"
    case delayedIshaInRamadan = "kBAUserDefaultsDelayedIshaInRamadan"

    // MARK: Notifications

    case fajrReminderAlertEnabled = "kBAUserDefaultsAlertFajrReminderEnabled"
    case fajrAlertEnabled = "kBAUserDefaultsAlertFajrEnabled"
    case sunriseReminderAlertEnabled = "kBAUserDefaultsAlertShuruqReminderEnabled"
    case dhuhrAlertEnabled = "kBAUserDefaultsAlertDhuhrEnabled"
    case asrAlertEnabled = "kBAUserDefaultsAlertAsrEnabled"
    case maghribAlertEnabled = "kBAUserDefaultsAlertMaghribEnabled"
    case ishaAlertEnabled = "kBAUserDefaultsAlertIshaEnabled"

    // MARK: Reminders

    case dhuhrReminderEnabled = "kBAUserDefaultsDhuhrReminderEnabled"
    case asrReminderEnabled = "kBAUserDefaultsAsrReminderEnabled"
    case maghribReminderEnabled = "kBAUserDefaultsMaghribReminderEnabled"
    case ishaReminderEnabled = "kBAUserDefaultsIshaReminderEnabled"

    // MARK: Alert Sound

    case fajrReminderAlertType = "kBAUserDefaultsAlertFajrReminderSound"
    case fajrAlertType = "kBAUserDefaultsAlertFajrSound"
    case sunriseReminderAlertType = "kBAUserDefaultsAlertShuruqReminderSound"
    case dhuhrAlertType = "kBAUserDefaultsAlertDhuhrSound"
    case asrAlertType = "kBAUserDefaultsAlertAsrSound"
    case maghribAlertType = "kBAUserDefaultsAlertMaghribSound"
    case ishaAlertType = "kBAUserDefaultsAlertIshaSound"

    // MARK: Reminder Offset

    case fajrReminderOffset = "kBAUserDefaultsAlertFajrReminderOffset"
    case sunriseReminderOffset = "kBAUserDefaultsAlertShuruqReminderOffset"
    case dhuhrReminderOffset = "kBAUserDefaultsAlertDhuhrReminderOffset"
    case asrReminderOffset = "kBAUserDefaultsAlertAsrReminderOffset"
    case maghribReminderOffset = "kBAUserDefaultsAlertMaghribReminderOffset"
    case ishaReminderOffset = "kBAUserDefaultsAlertIshaReminderOffset"

    // MARK: Reminder Sound

    case dhuhrReminderSound = "kBAUserDefaultsAlertDhuhrReminderSound"
    case asrReminderSound = "kBAUserDefaultsAlertAsrReminderSound"
    case maghribReminderSound = "kBAUserDefaultsAlertMaghribReminderSound"
    case ishaReminderSound = "kBAUserDefaultsAlertIshaReminderSound"

    // MARK: Custom Sounds
    
    case fajrCustomSound = "kBAUserDefaultsAlertFajrCustomSound"
    case dhuhrCustomSound = "kBAUserDefaultsAlertDhuhrCustomSound"
    case asrCustomSound = "kBAUserDefaultsAlertAsrCustomSound"
    case maghribCustomSound = "kBAUserDefaultsAlertMaghribCustomSound"
    case ishaCustomSound = "kBAUserDefaultsAlertIshaCustomSound"
    
    // MARK: Display

    case useArabicNames = "kBAUserDefaultsForceArabic"
    case displayNextPrayer = "kBAUserDefaultsDisplayNextPrayer"
    case displayNextPrayerType = "kBAUserDefaultsDisplayNextPrayerType"
    case displayNextPrayerName = "kBAUserDefaultsDisplayNextPrayerName"
    case displayIcon = "kBAUserDefaultsDisplayIcon"

    // MARK: Misc.

    case playDua = "kBAUserDefaultsDua"
    case silentMode = "kBAUserDefaultsSilentMode"
    case alertVolume = "kBAUserDefaultsAlertVolume"
    case prefsVersion = "kBAUserDefaultsVersion"
}
