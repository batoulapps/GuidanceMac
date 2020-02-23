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

    var prayerTimes: PrayerTimes?

    static var menuItemFrame: NSRect {
        NSRect(x: 0, y: 0, width: rowWidth, height: rowHeight * CGFloat(Prayer.allCases.count))
    }

    private static let rowWidth: CGFloat = 200
    private static let rowHeight: CGFloat = 21
    private static let rowPadding: CGFloat = 21
    private static let baseAttributes: [NSAttributedString.Key : Any] = [
        .font: NSFont.menuFont(ofSize: 14),
        .foregroundColor: NSColor.textColor
    ]

    let formatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .none
        d.timeStyle = .short
        return d
    }()

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let nameAttr = nameAttributes()
        let timeAttr = timeAttributes()

        for (index, prayer) in Prayer.allCases.enumerated() {
            let time: NSString = {
                guard let prayerTime = prayerTimes?.time(for: prayer) else {
                    return "-:-"
                }
                return formatter.string(from: prayerTime) as NSString
            }()
            prayer.name.draw(in: nameRect(row: index), withAttributes: nameAttr)
            time.draw(in: timeRect(row: index), withAttributes: timeAttr)
        }
    }

    private func nameAttributes() -> [NSAttributedString.Key : Any] {
        var attributes = PrayerTimeView.baseAttributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        attributes[.paragraphStyle] = paragraphStyle
        return attributes;
    }

    private func timeAttributes() -> [NSAttributedString.Key : Any] {
        var attributes = PrayerTimeView.baseAttributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        attributes[.paragraphStyle] = paragraphStyle
        return attributes;
    }

    private func nameRect(row: Int) -> NSRect {
        let width = (PrayerTimeView.rowWidth - (PrayerTimeView.rowPadding * 2)) / 2
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowPadding
        let yPos = PrayerTimeView.menuItemFrame.height - (height * CGFloat(row + 1))
        return NSRect(x: xPos, y: yPos, width: width, height: height)
    }

    private func timeRect(row: Int) -> NSRect {
        let width = (PrayerTimeView.rowWidth - (PrayerTimeView.rowPadding * 2)) / 2
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowWidth / 2
        let yPos = PrayerTimeView.menuItemFrame.height - (height * CGFloat(row + 1))
        return NSRect(x: xPos, y: yPos, width: width, height: height)
    }
}
