//
//  HXTestBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseTestBox: NSView {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with test: Test, owner: CoursePageViewController) -> CourseTestBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseTestBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseTestBox}).first as? CourseTestBox {
            newBox.initialize(with: test, owner: owner)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTest: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    
    weak var test: Test!
    weak var owner: CoursePageViewController!
    
    func initialize(with test: Test, owner: CoursePageViewController) {
        labelTest.stringValue = test.title!
        if test.date == nil {
            labelDate.stringValue = ""
        } else {
            let day = Calendar.current.component(.day, from: test.date!)
            let month = Calendar.current.component(.month, from: test.date!)
            let year = Calendar.current.component(.year, from: test.date!)
            let weekday = Calendar.current.component(.weekday, from: test.date!)
            let minuteOfDay = Calendar.current.component(.hour, from: test.date!) * 60 + Calendar.current.component(.minute, from: test.date!)
            let weekdayToday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            if weekdayToday == weekday && minuteOfDayToday < minuteOfDay {
                labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
            } else {
                labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
            }
        }
        
        self.test = test
        self.owner = owner
    }
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        owner.notifyReveal(testBox: self)
    }
}
