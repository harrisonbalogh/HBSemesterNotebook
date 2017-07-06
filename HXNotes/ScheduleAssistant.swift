//
//  ScheduleAssistant.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/5/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class ScheduleAssistant: NSObject {
    
    override init() {
        super.init()
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Start minute checks
        let minuteComponent = calendar.component(.minute, from: Date())
        self.perform(#selector(SidebarViewController.notifyHour), with: nil, afterDelay: Double(60 - minuteComponent) * 60)
        // Start hour checks
        let hourComponent = calendar.component(.hour, from: Date())
        self.perform(#selector(SidebarViewController.notifyHour), with: nil, afterDelay: Double(60 - hourComponent) * 60)
        
    }
    
    
    /// Do not call this method. A perform() is called and reset on this notifyHour selector.
    func notifyHour() {
        
        print("Hour")
        
//        lectureCheck()
        
        // Place code above. The following resets timer. Do not alter.
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let dateComponent = calendar.component(.minute, from: Date())
        self.perform(#selector(SidebarViewController.notifyHour), with: nil, afterDelay: Double(60 - dateComponent) * 60)
    }
    
    /// Do not call this method. A perform() is called and reset on this notifyMinute selector.
    func notifyMinute() {
        
        print("Minute")
        
//        lectureCheck()
        
        // Place code above. The following resets timer. Do not alter.
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let dateComponent = calendar.component(.second, from: Date())
        self.perform(#selector(SidebarViewController.notifyMinute), with: nil, afterDelay: Double(60 - dateComponent))
    }
    
}
