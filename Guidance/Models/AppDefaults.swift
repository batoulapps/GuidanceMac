//
//  AppDefaults.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/27/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation

enum AppDefaults {

    // MARK: Location

    @StoredDefault(key: .autoDetectLocation, defaultValue: true)
    static var autoDetectLocation: Bool

    @StoredDefault(key: .latitude, defaultValue: 21.4167)
    static var latitude: Double

    @StoredDefault(key: .longitude, defaultValue: 39.8167)
    static var longitude: Double

    @StoredDefault(key: .city, defaultValue: "Makkah")
    static var city: String

    @StoredDefault(key: .state, defaultValue: "Makkah")
    static var state: String

    @StoredDefault(key: .country, defaultValue: "SA")
    static var country: String

    @StoredDefault(key: .timeZone, defaultValue: "Asia/Riyadh")
    static var timeZone: String

    // MARK: Calculation

    @StoredDefault(key: .autoDetectMethod, defaultValue: true)
    static var autoDetectMethod: Bool

    @StoredDefault(key: .autoDetectHighLatRule, defaultValue: true)
    static var autoDetectHighLatRule: Bool

    @StoredDefaultEnum(key: .madhab, defaultValue: .shafi)
    static var madhab: Preferences.Madhab

    @StoredDefaultEnum(key: .method, defaultValue: .muslimWorldLeague)
    static var method: Preferences.Method

    @StoredDefaultEnum(key: .highLatitudeRule, defaultValue: .middleOfTheNight)
    static var highLatitudeRule: Preferences.HighLatitudeRule

    @StoredDefault(key: .fajrAdjustment, defaultValue: 0)
    static var fajrAdjustment: Int

    @StoredDefault(key: .sunriseAdjustment, defaultValue: 0)
    static var sunriseAdjustment: Int

    @StoredDefault(key: .dhuhrAdjustment, defaultValue: 0)
    static var dhuhrAdjustment: Int

    @StoredDefault(key: .asrAdjustment, defaultValue: 0)
    static var asrAdjustment: Int

    @StoredDefault(key: .maghribAdjustment, defaultValue: 0)
    static var maghribAdjustment: Int

    @StoredDefault(key: .ishaAdjustment, defaultValue: 0)
    static var ishaAdjustment: Int

    @StoredDefault(key: .customFajrAngle, defaultValue: 18.0)
    static var customFajrAngle: Double

    @StoredDefault(key: .customIshaAngle, defaultValue: 18.0)
    static var customIshaAngle: Double

    @StoredDefault(key: .hijriOffset, defaultValue: 0)
    static var hijriOffset: Int

    @StoredDefault(key: .delayedIshaInRamadan, defaultValue: true)
    static var delayedIshaInRamadan: Bool

    // MARK: Notifications

    @StoredDefault(key: .fajrReminderAlertEnabled, defaultValue: false)
    static var fajrReminderAlertEnabled: Bool

    @StoredDefault(key: .fajrAlertEnabled, defaultValue: false)
    static var fajrAlertEnabled: Bool

    @StoredDefault(key: .sunriseReminderAlertEnabled, defaultValue: false)
    static var sunriseReminderAlertEnabled: Bool

    @StoredDefault(key: .dhuhrAlertEnabled, defaultValue: false)
    static var dhuhrAlertEnabled: Bool

    @StoredDefault(key: .asrAlertEnabled, defaultValue: false)
    static var asrAlertEnabled: Bool

    @StoredDefault(key: .maghribAlertEnabled, defaultValue: false)
    static var maghribAlertEnabled: Bool

    @StoredDefault(key: .ishaAlertEnabled, defaultValue: false)
    static var ishaAlertEnabled: Bool

    // MARK: Reminders

    @StoredDefault(key: .dhuhrReminderEnabled, defaultValue: false)
    static var dhuhrReminderEnabled: Bool

    @StoredDefault(key: .asrReminderEnabled, defaultValue: false)
    static var asrReminderEnabled: Bool

    @StoredDefault(key: .maghribReminderEnabled, defaultValue: false)
    static var maghribReminderEnabled: Bool

    @StoredDefault(key: .ishaReminderEnabled, defaultValue: false)
    static var ishaReminderEnabled: Bool

    // MARK: Alert Sound

    @StoredDefaultEnum(key: .fajrReminderAlertType, defaultValue: .afasy)
    static var fajrReminderAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .fajrAlertType, defaultValue: .afasy)
    static var fajrAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .sunriseReminderAlertType, defaultValue: .afasy)
    static var sunriseReminderAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .dhuhrAlertType, defaultValue: .afasy)
    static var dhuhrAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .asrAlertType, defaultValue: .afasy)
    static var asrAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .maghribAlertType, defaultValue: .afasy)
    static var maghribAlertType: Preferences.AlertType

    @StoredDefaultEnum(key: .ishaAlertType, defaultValue: .afasy)
    static var ishaAlertType: Preferences.AlertType

    // MARK: Reminder Offset

    @StoredDefault(key: .fajrReminderOffset, defaultValue: 30)
    static var fajrReminderOffset: Int

    @StoredDefault(key: .sunriseReminderOffset, defaultValue: 30)
    static var sunriseReminderOffset: Int

    @StoredDefault(key: .dhuhrReminderOffset, defaultValue: 30)
    static var dhuhrReminderOffset: Int

    @StoredDefault(key: .asrReminderOffset, defaultValue: 30)
    static var asrReminderOffset: Int

    @StoredDefault(key: .maghribReminderOffset, defaultValue: 30)
    static var maghribReminderOffset: Int

    @StoredDefault(key: .ishaReminderOffset, defaultValue: 30)
    static var ishaReminderOffset: Int

    // MARK: Reminder Sound

    @StoredDefaultEnum(key: .dhuhrReminderSound, defaultValue: .afasy)
    static var dhuhrReminderSound: Preferences.AlertType

    @StoredDefaultEnum(key: .asrReminderSound, defaultValue: .afasy)
    static var asrReminderSound: Preferences.AlertType

    @StoredDefaultEnum(key: .maghribReminderSound, defaultValue: .afasy)
    static var maghribReminderSound: Preferences.AlertType

    @StoredDefaultEnum(key: .ishaReminderSound, defaultValue: .afasy)
    static var ishaReminderSound: Preferences.AlertType

    // MARK: Display

    @StoredDefault(key: .useArabicNames, defaultValue: false)
    static var useArabicNames: Bool

    // MARK: Misc.

    @StoredDefault(key: .playDua, defaultValue: true)
    static var playDua: Bool
}
