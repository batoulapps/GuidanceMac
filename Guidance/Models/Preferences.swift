//
//  Preferences.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/27/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation
import Adhan

func UserText(_ key: String, comment: String? = nil) -> String {
    return Preferences.arabicOverride ? Arabic(key) : Localized(key)
}

struct Preferences {
    
    enum Madhab: Int, Codable {
        case shafi
        case hanafi
    }
    
    enum Method: Int, Codable {
        case egyptian
        case karachi
        case northAmerica
        case muslimWorldLeague
        case ummAlQurra
        case dubai
        case moonsightingCommittee
        case custom
        case kuwait
        case qatar
        case singapore
        case tehran
        
        var name: String {
            switch self {
            case .egyptian:
                return Localized("Egyptian General Authority")
            case .karachi:
                return Localized("Islamic University, Karachi")
            case .northAmerica:
                return Localized("North America")
            case .muslimWorldLeague:
                return Localized("Muslim World League")
            case .ummAlQurra:
                return Localized("Umm Al-Qura")
            case .dubai:
                return Localized("Dubai")
            case .moonsightingCommittee:
                return Localized("Moonsighting Committee")
            case .custom:
                return Localized("Custom Method")
            case .kuwait:
                return Localized("Kuwait")
            case .qatar:
                return Localized("Qatar")
            case .singapore:
                return Localized("JAKIM")
            case .tehran:
                return Localized("Tehran")
            }
        }
        
        var hasIntervalIsha: Bool {
            let params = CalculationMethod.methodForPreference(self).params
            return params.ishaInterval > 0
        }
        
        static func methodForCountry(_ country: String) -> Method {
            let defaultMethods: [Method : [String]] = [
                .egyptian : ["EG", "SD", "SS", "LY", "DZ", "LB", "SY", "IL", "MA", "PS", "IQ", "TR"],
                .karachi : ["PK", "IN", "BD", "AF", "JO"],
                .ummAlQurra : ["SA"],
                .dubai : ["AE"],
                .moonsightingCommittee : ["US", "CA", "UK", "GB"],
                .kuwait : ["KW"],
                .qatar : ["BH", "OM", "YE", "QA"],
                .singapore : ["SG", "ID", "MY"],
                .tehran : ["IR"]
            ]
            
            for (method, countries) in defaultMethods {
                if countries.contains(AppDefaults.country) {
                    return method
                }
            }
            
            return .muslimWorldLeague
        }

        static func sorted() -> [Method] {
            return [
                .muslimWorldLeague,
                .egyptian,
                .karachi,
                .moonsightingCommittee,
                .ummAlQurra,
                .qatar,
                .dubai,
                .kuwait,
                .singapore,
                .tehran,
                .northAmerica
            ]
        }
    }
    
    enum HighLatitudeRule: Int, Codable, CaseIterable {
        case middleOfTheNight
        case seventhOfTheNight
        case angleBased

        var name: String {
            switch self {
            case .middleOfTheNight:
                return Localized("Middle of the Night")
            case .seventhOfTheNight:
                return Localized("Seventh of the Night")
            case .angleBased:
                return Localized("Twilight Angle")
            }
        }
    }

    enum AlertType: Int, Codable {
        case afasy = 2
        case yusufIslam = 3
        case makkah = 4
        case istanbul = 5
        case aqsa = 6
        case fajr = 7
        
        case othmanAlEbraheem = 8
        case othmanAlEbraheem2 = 9
        case afasy2 = 10
        case saadAlGhamidi = 11

        static var fullAdhans: [AlertType] {
            return [.afasy, .afasy2, .othmanAlEbraheem, .othmanAlEbraheem2, .makkah, .istanbul, .saadAlGhamidi, .yusufIslam]
        }
        
        var name: String {
            switch self {
            case .afasy:
                return Localized("Mishary Alafasy 1")
            case .afasy2:
                return Localized("Mishary Alafasy 2")
            case .makkah:
                return Localized("Makkah")
            case .istanbul:
                return Localized("Istanbul")
            case .yusufIslam:
                return Localized("Yusuf Islam")
            case .othmanAlEbraheem:
                return Localized("Othman Al-Ebraheem 1")
            case .othmanAlEbraheem2:
                return Localized("Othman Al-Ebraheem 2")
            case .saadAlGhamidi:
                return Localized("Saad Al Ghamdi")
            case .fajr:
                return Localized("Fajr Adhan")
            case .aqsa:
                return Localized("Al-Aqsa")
            }
        }
    }

    static func updateMethodForCurrentLocation() {
        AppDefaults.method = Method.methodForCountry(AppDefaults.country)
    }
    
    static func updateHighLatitudeRuleForCurrentLocation() {
        if AppDefaults.latitude > 48 {
            AppDefaults.highLatitudeRule = .seventhOfTheNight
        } else {
            AppDefaults.highLatitudeRule = .middleOfTheNight
        }
    }
    
    static var nativeArabic: Bool {
        return Localized("lang") == "ar"
    }
    
    static var arabicOverride: Bool {
        return AppDefaults.useArabicNames && nativeArabic == false
    }
}
