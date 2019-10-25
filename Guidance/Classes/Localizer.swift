//
//  Localizer.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 10/30/16.
//  Copyright © 2016 Batoul Apps. All rights reserved.
//

import Cocoa

class Localizer: NSObject {
    
    @objc static let shared = Localizer()
    
    @objc static let languageDidChangeNotification = "languageDidChange"
    static let arabicLocaleIdentifier = "ar"
    
    @objc var nativeArabic = Locale.isNativeArabic()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(localeDidChange), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }
    
    @objc func localeDidChange() {
        nativeArabic = Locale.isNativeArabic()
        Formatter.shared.reload()
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
    
    @objc class func bundle() -> Bundle {
        var currentBundle = Bundle.main
        if Localizer.displayArabic(), let path = Bundle.main.path(forResource: arabicLocaleIdentifier, ofType: "lproj"), let arabicBundle = Bundle(path: path) {
            currentBundle = arabicBundle
        }
        return currentBundle
    }
    
    @objc class func locale() -> Locale {
        if Localizer.displayArabic() {
            return Locale(identifier: Localizer.arabicLocaleIdentifier)
        }
        return Locale.current
    }
    
    @objc class func displayArabic() -> Bool {
        return Localizer.shared.nativeArabic || BASwifty.forceArabic()
    }
    
    @objc class func displayRightToLeft() -> Bool {
        if let languageCode = Localizer.locale().languageCode {
            return Locale.characterDirection(forLanguage: languageCode) == .rightToLeft
        }
        
        return false
    }
}

extension Locale {
    static func isNativeArabic() -> Bool {
        guard let preferredLanguage = Locale.preferredLanguages.first else { return false }
        return preferredLanguage.range(of: Localizer.arabicLocaleIdentifier) != nil
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name(Localizer.languageDidChangeNotification)
}
