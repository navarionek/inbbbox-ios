//
//  SettingsSpec.swift
//  Inbbbox
//
//  Created by Lukasz Pikor on 24.03.2016.
//  Copyright © 2016 Netguru Sp. z o.o. All rights reserved.
//

import Quick
import Nimble

@testable import Inbbbox

class SettingsSpec: QuickSpec {
    
    var didReceiveStreamSourceNotification = false
    var didReceiveNotificationsNotification = false
    
    override func spec() {
        NotificationCenter.default.addObserver(self, selector: #selector(streamNotification(_:)), name: NSNotification.Name(rawValue: InbbboxNotificationKey.UserDidChangeStreamSourceSettings.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationsNotification(_:)), name: NSNotification.Name(rawValue: InbbboxNotificationKey.UserDidChangeNotificationsSettings.rawValue), object: nil)
        
        describe("when changing settings") {
            Settings.StreamSource.Debuts = true
            Settings.Reminder.Enabled = false
            
            it("should receive notification") {
                expect(self.didReceiveStreamSourceNotification).to(beTrue())
                expect(self.didReceiveNotificationsNotification).to(beTrue())
            }
        }
        
        describe("when all stream sources are off") {
            Settings.StreamSource.Debuts = false
            Settings.StreamSource.Following = false
            Settings.StreamSource.NewToday = false
            Settings.StreamSource.PopularToday = false
            
            it("property indicating all sources are off should be true") {
                expect(Settings.areAllStreamSourcesOff()).to(beTrue())
            }
        }
    }
    
    dynamic func streamNotification(_ notification: Notification) {
        didReceiveStreamSourceNotification = true
    }
    
    dynamic func notificationsNotification(_ notification: Notification) {
        didReceiveNotificationsNotification = true
    }
}
