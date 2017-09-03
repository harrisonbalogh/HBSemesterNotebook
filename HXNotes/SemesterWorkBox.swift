//
//  HXWorkBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterWorkBox: NSView {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with work: Work, owner: SemesterPageViewController) -> SemesterWorkBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("SemesterWorkBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SemesterWorkBox}).first as? SemesterWorkBox {
            newBox.initialize(with: work, owner: owner)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelWork: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var boxFill: NSBox!
    
    weak var work: Work!
    weak var owner: SemesterPageViewController!
    
    func initialize(with work: Work, owner: SemesterPageViewController) {
        labelWork.stringValue = work.title!
        if work.date == nil {
            labelDate.stringValue = ""
        } else {
            let day = Calendar.current.component(.day, from: work.date!)
            let month = Calendar.current.component(.month, from: work.date!)
            let year = Calendar.current.component(.year, from: work.date!)
            let weekday = Calendar.current.component(.weekday, from: work.date!)
            let minuteOfDay = Calendar.current.component(.hour, from: work.date!) * 60 + Calendar.current.component(.minute, from: work.date!)
            let weekdayToday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            if weekdayToday == weekday && minuteOfDayToday < minuteOfDay {
                labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
            } else {
                labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
            }
        }
        
        self.work = work
        self.owner = owner
    }
    
    @IBAction func action_select(_ sender: NSButton) {
        boxFill.fillColor = NSColor.lightGray
        self.needsDisplay = true
        owner.notifySelected(work: work)
    }
    
}
