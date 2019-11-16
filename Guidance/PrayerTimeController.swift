//
//  PrayerTimeController.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/16/19.
//  Copyright © 2019 Batoul Apps. All rights reserved.
//

import Foundation
import AppKit
import Adhan

protocol PrayerTimeControllerDelegate: AnyObject {
    func didUpdateStatus()
}

class PrayerTimeController {
    weak var delegate: PrayerTimeControllerDelegate?

    private var timer: Timer?

    // MARK: - Public interface

    func beginUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(handleTimer(timer:)), userInfo: nil, repeats: true)
        timer?.tolerance = 1
        timer?.fire()
    }

    // MARK: - Private interface

    @objc private func handleTimer(timer: Timer) {
        if timer.isValid {
            timer.fireDate = nextFireDate()
        }
        delegate?.didUpdateStatus()
    }

    private func nextFireDate() -> Date {
        let fraction = modf(Date.timeIntervalSinceReferenceDate / 60).1
        let currentSecond = fraction * 60
        return Date(timeIntervalSinceNow: 60.5 - currentSecond)
    }
}
