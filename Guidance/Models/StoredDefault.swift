//
//  StoredDefault.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/27/21.
//  Copyright © 2021 Batoul Apps. All rights reserved.
//

import Foundation

@propertyWrapper
struct StoredDefault<T> {
    let key: DefaultKey
    let defaultValue: T

    init(key: DefaultKey, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            sharedUserDefaults.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            sharedUserDefaults.set(newValue, forKey: key.rawValue)
            postNotification(key)
        }
    }
}

@propertyWrapper
struct StoredDefaultEnum<T: RawRepresentable> {
    let key: DefaultKey
    let defaultValue: T

    init(key: DefaultKey, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            guard let rawValue = sharedUserDefaults.object(forKey: key.rawValue) as? T.RawValue else {
                return defaultValue
            }

            return T(rawValue: rawValue) ?? defaultValue
        }
        set {
            sharedUserDefaults.set(newValue.rawValue, forKey: key.rawValue)
            postNotification(key)
        }
    }
}

fileprivate func postNotification(_ key: DefaultKey) {
    NotificationQueue.default.enqueue(Notification(name: .prefsDidChange, object: key, userInfo: nil), postingStyle: .asap, coalesceMask: .onName, forModes: nil)
}

fileprivate let sharedUserDefaults: UserDefaults = UserDefaults.standard

extension Notification.Name {
    static let prefsDidChange = Notification.Name("prefsDidChange")
}
