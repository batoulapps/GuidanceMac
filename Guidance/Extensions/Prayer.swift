//
//  Prayer.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/19/19.
//  Copyright © 2019 Batoul Apps. All rights reserved.
//

import Foundation
import Adhan

extension Prayer {
    var name: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .sunrise:
            return "Sunrise"
        case .dhuhr:
            return "Dhuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        }
    }
}
