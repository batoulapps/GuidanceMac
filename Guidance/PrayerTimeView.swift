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

    var prayerTimes: PrayerTimes? {
        didSet {
            updatePrayerTimes()
        }
    }
    
    var location: String = "" {
        didSet {
            updateLocation()
        }
    }
    
    var hijriDate: Date = Date() {
        didSet {
            updateHijriDate()
        }
    }

    static var menuItemFrame: NSRect {
        NSRect(x: 0, y: 0, width: rowWidth, height: rowHeight * CGFloat(Prayer.allCases.count) + 50)
    }

    private static let rowWidth: CGFloat = 200
    private static let rowHeight: CGFloat = 23
    private static let rowPadding: CGFloat = 16
    
    private static var textWidth: CGFloat {
        rowWidth - (rowPadding * 2)
    }
    
    private let formatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .none
        d.timeStyle = .short
        return d
    }()
    
    private let nameLabels = Prayer.allCases.map { _ in NSTextField() }
    private let timeLabels = Prayer.allCases.map { _ in NSTextField() }
    private let dateLabel = NSTextField()
    private let locationLabel = NSTextField()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        for nameLabel in nameLabels {
            styleLabel(nameLabel)
            nameLabel.alignment = .left
        }
        
        for timeLabel in timeLabels {
            styleLabel(timeLabel)
            timeLabel.alignment = .right
        }
        
        for (index, prayer) in Prayer.allCases.enumerated() {
            let nameLabel = nameLabels[index]
            nameLabel.frame = nameRect(row: index)
            nameLabel.stringValue = prayer.localizedName()
            addSubview(nameLabel)
            
            let timeLabel = timeLabels[index]
            timeLabel.frame = timeRect(row: index)
            addSubview(timeLabel)
        }
        
        styleLabel(dateLabel)
        dateLabel.frame = dateRect()
        dateLabel.font = NSFont.boldSystemFont(ofSize: 13)
        dateLabel.alphaValue = 0.7
        addSubview(dateLabel)
        
        styleLabel(locationLabel)
        locationLabel.frame = locationRect()
        locationLabel.font = NSFont.menuFont(ofSize: 12)
        locationLabel.alphaValue = 0.8
        
        addSubview(locationLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func styleLabel(_ label: NSTextField) {
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.font = NSFont.menuFont(ofSize: 14)
        label.textColor = NSColor.textColor
    }
    
    private func updatePrayerTimes() {
        for (index, prayer) in Prayer.allCases.enumerated() {
            let nameLabel = nameLabels[index]
            nameLabel.stringValue = prayer.localizedName()
            
            let timeLabel = timeLabels[index]
            let time: String = {
                guard let prayerTime = prayerTimes?.time(for: prayer) else {
                    return "-:-"
                }
                return formatter.string(from: prayerTime)
            }()
            timeLabel.stringValue = time
            addSubview(timeLabel)
        }
    }
    
    private func updateLocation() {
        let locationString = NSMutableAttributedString()
        if #available(macOS 11.0, *) {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = NSImage(systemSymbolName: "location.fill", accessibilityDescription: "Location")
            

            locationString.append(NSAttributedString(attachment: imageAttachment))
            locationString.append(NSAttributedString(string: " "))
        }
        locationString.append(NSAttributedString(string: location))
        locationLabel.attributedStringValue = locationString
    }
    
    private func updateHijriDate() {
        dateLabel.stringValue = "Ramadan 2, 1453"
    }

    private func nameRect(row: Int) -> NSRect {
        let width = PrayerTimeView.textWidth / 2
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowPadding
        let yPos = PrayerTimeView.menuItemFrame.height - (height * CGFloat(row + 1))
        return NSRect(x: xPos, y: yPos - 28, width: width, height: height)
    }

    private func timeRect(row: Int) -> NSRect {
        let width = PrayerTimeView.textWidth / 2
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowWidth / 2
        let yPos = PrayerTimeView.menuItemFrame.height - (height * CGFloat(row + 1))
        return NSRect(x: xPos, y: yPos - 28, width: width, height: height)
    }
    
    private func dateRect() -> NSRect {
        let width = PrayerTimeView.textWidth
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowPadding
        let yPos = PrayerTimeView.menuItemFrame.height - PrayerTimeView.rowHeight
        return NSRect(x: xPos, y: yPos - 3, width: width, height: height)
    }
    
    private func locationRect() -> NSRect {
        let width = PrayerTimeView.textWidth
        let height = PrayerTimeView.rowHeight
        let xPos = PrayerTimeView.rowPadding
        let yPos: CGFloat = -4
        return NSRect(x: xPos, y: yPos, width: width, height: height)
    }
}
