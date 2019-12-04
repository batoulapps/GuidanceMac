//
//  PrayerTimeView.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/18/19.
//  Copyright © 2019 Batoul Apps. All rights reserved.
//

import Cocoa
import Adhan

class PrayerTimeView: NSView {

    static let rowWidth: CGFloat = 200
    static let rowHeight: CGFloat = 21
    static let rowPadding: CGFloat = 21
    static var menuItemFrame: NSRect {
        NSRect(x: 0, y: 0, width: rowWidth, height: rowHeight * CGFloat(Prayer.allCases.count))
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let attributes: [NSAttributedString.Key : Any] = [
            .font: NSFont.menuFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ]

        for (index, prayer) in Prayer.allCases.enumerated() {
            prayer.name.draw(in: nameRect(row: index), withAttributes: attributes)
        }
    }

    func nameRect(row: Int) -> NSRect {
        let nameWidth = (PrayerTimeView.rowWidth - (PrayerTimeView.rowPadding * 2)) / 2
        let nameHeight = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowPadding
        let yPos = PrayerTimeView.menuItemFrame.height - (nameHeight * CGFloat(row + 1))
        return NSRect(x: xPos, y: yPos, width: nameWidth, height: nameHeight)
    }
}
