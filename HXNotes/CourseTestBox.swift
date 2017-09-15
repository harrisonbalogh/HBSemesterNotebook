//
//  HXTestBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseTestBox: NSView {
    
    var selectionDelegate: SelectionDelegate?
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with test: Test) -> CourseTestBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseTestBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseTestBox}).first as? CourseTestBox {
            newBox.initialize(with: test)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTest: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    
    weak var test: Test!
    
    func initialize(with test: Test) {
        labelTest.stringValue = test.title!
        if test.date == nil {
            labelDate.stringValue = "Undated"
        } else {
            let day = Calendar.current.component(.day, from: test.date!)
            let month = Calendar.current.component(.month, from: test.date!)
            let dayToday = Calendar.current.component(.day, from: Date())
            let monthToday = Calendar.current.component(.month, from: Date())
            let year = Calendar.current.component(.year, from: test.date!)
            let minuteOfDay = Calendar.current.component(.hour, from: test.date!) * 60 + Calendar.current.component(.minute, from: test.date!)
            let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            if monthToday == month && dayToday == day && minuteOfDayToday < minuteOfDay && !test.completed {
                labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
            } else {
                labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
            }
        }
        
        if test.completed {
            labelTest.textColor = NSColor.lightGray
            labelDate.textColor = NSColor.lightGray
            buttonDetails.alphaValue = 0.6
            if !test.customTitle {
                labelTest.stringValue = "Untitled Test"
            }
        }
        
        self.test = test
    }
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        selectionDelegate?.isEditing(testBox: self)
    }
}
