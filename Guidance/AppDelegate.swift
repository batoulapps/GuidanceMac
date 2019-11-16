//
//  AppDelegate.swift
//  Guidance
//
//  Created by Ameir Al-Zoubi on 11/16/19.
//  Copyright © 2019 Batoul Apps. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, PrayerTimeControllerDelegate {

    lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    lazy var menu = NSMenu(title: "Guidance")
    lazy var prayerTimeController = PrayerTimeController()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        prayerTimeController.delegate = self
        prayerTimeController.beginUpdates()

        configureMenu()
        statusItem.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Internal

    private func configureMenu() {
        menu.removeAllItems()

        menu.addItem(.separator())

        let prefItem = NSMenuItem(title: "Preferences...", action: #selector(openPrefs(sender:)), keyEquivalent: ",")
        prefItem.keyEquivalentModifierMask = .command
        menu.addItem(prefItem)

        let aboutItem = NSMenuItem(title: "About Guidance", action: #selector(openAbout(sender:)), keyEquivalent: "")
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Guidance", action: #selector(quitApp(sender:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)
    }

    func updateStatusItem() {
        statusItem.button?.image = NSImage(named: "menuBar")
        statusItem.button?.imagePosition = .imageLeft

        // TODO use real prayer times
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        statusItem.button?.attributedTitle = NSAttributedString(string: formatter.string(from: Date()))
    }

    // MARK: - Menu Actions

    @objc func openPrefs(sender: NSMenuItem) {
        NSLog("open prefs...")
    }

    @objc func openAbout(sender: NSMenuItem) {
        if #available(OSX 10.13, *) {
            let credits = NSMutableAttributedString(string: "Prayer times are calculated using Adhan\n", attributes: [.font: NSFont.systemFont(ofSize: 11)])
            credits.append(NSAttributedString(string: "github.com/batoulapps/adhan", attributes: [.link: NSURL(string: "https://github.com/batoulapps/adhan")!]))
            NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        } else {
            NSApp.orderFrontStandardAboutPanel(sender)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp(sender: NSMenuItem) {
        NSApp.terminate(sender)
    }

    // MARK: - PrayerTimeControllerDelegate

    func didUpdateStatus() {
        updateStatusItem()
    }
}

