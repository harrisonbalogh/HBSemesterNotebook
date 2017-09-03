//
//  HXWorkBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseWorkBox: NSView {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with work: Work, owner: CoursePageViewController) -> CourseWorkBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseWorkBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseWorkBox}).first as? CourseWorkBox {
            newBox.initialize(with: work, owner: owner)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelWork: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    
    weak var work: Work!
    weak var owner: CoursePageViewController!
    
    func initialize(with work: Work, owner: CoursePageViewController) {
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
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        owner.notifyReveal(workBox: self)
    }
}
