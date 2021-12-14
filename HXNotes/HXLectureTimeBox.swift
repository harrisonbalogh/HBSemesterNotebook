//
//  HXLectureTimeBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/23/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXLectureTimeBox: NSView {
    
    /// Return a new instance of a HXCourseEditBox based on the nib template.
    static func instance(from timeSlot: TimeSlot, with owner: Any) -> HXLectureTimeBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "HXLectureTimeBox"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureTimeBox}).first as? HXLectureTimeBox {
            newBox.initialize(from: timeSlot, with: owner)
            return newBox
        }
        return nil
    }

    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var dayLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    
    weak var timeSlot: TimeSlot!
    var owner: Any!
    
    func initialize(from timeSlot: TimeSlot, with owner: Any) {
        
        let weekday = Calendar.current.component(.weekday, from: Date())
        let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
        
        if Int(timeSlot.weekday) == weekday && Int(timeSlot.startMinute) > minuteOfDay {
            dayLabel.stringValue = "Today"
        } else {
            let ENGLISH_DAYS = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            dayLabel.stringValue = ENGLISH_DAYS[Int(timeSlot.weekday)]
        }
        
        timeLabel.stringValue = HXTimeFormatter.formatTime(timeSlot.startMinute)
        
        self.owner = owner
        self.timeSlot = timeSlot
    }
    
    func select() {
        box.fillColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        box.borderWidth = 2
    }
    
    func deselect() {
        box.fillColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 0)
        box.borderWidth = 1
    }
    
    @IBAction func action_select(_ sender: NSButton) {
        if let owner = owner as? WorkAdderLectureController {
            if owner.workBox.work!.completed {
                return
            }
            owner.notifyLectureTimeSelected(self)
        } else if let owner = owner as? TestAdderViewController {
            if owner.testBox.test!.completed {
                return
            }
            owner.notifyLectureTimeSelected(self)
        }
        select()
    }
}
