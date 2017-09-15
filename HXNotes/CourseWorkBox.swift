//
//  HXWorkBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseWorkBox: NSView {
    
    var selectionDelegate: SelectionDelegate?
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with work: Work) -> CourseWorkBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseWorkBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseWorkBox}).first as? CourseWorkBox {
            newBox.initialize(with: work)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelWork: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    @IBOutlet weak var toggleCompleted: NSButton!
    
    weak var work: Work!
    
    func initialize(with work: Work) {
        labelWork.stringValue = work.title!
        if work.date == nil {
            labelDate.stringValue = "Undated"
        } else {
            let day = Calendar.current.component(.day, from: work.date!)
            let month = Calendar.current.component(.month, from: work.date!)
            let dayToday = Calendar.current.component(.day, from: Date())
            let monthToday = Calendar.current.component(.month, from: Date())
            let year = Calendar.current.component(.year, from: work.date!)
            let minuteOfDay = Calendar.current.component(.hour, from: work.date!) * 60 + Calendar.current.component(.minute, from: work.date!)
            let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            if month == monthToday && dayToday == day && minuteOfDayToday < minuteOfDay && !work.completed {
                labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
            } else {
                labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
            }
        }
        
        if work.completed {
            toggleCompleted.state = NSOnState
            toggleCompleted.alphaValue = 0.6
            labelWork.textColor = NSColor.lightGray
            labelDate.textColor = NSColor.lightGray
            buttonDetails.alphaValue = 0.6
            if !work.customTitle {
                labelWork.stringValue = "Untitled Work"
            }
        }
        
        self.work = work
    }
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        selectionDelegate?.isEditing(workBox: self)
    }
    @IBAction func action_complete(_ sender: NSButton) {
        
        if !work.completed {
            work.completed = true
            toggleCompleted.alphaValue = 0.6
            labelWork.textColor = NSColor.lightGray
            labelDate.textColor = NSColor.lightGray
            buttonDetails.alphaValue = 0.6
            if !work.customTitle {
                labelWork.stringValue = "Untitled Work"
            }
        } else {
            work.completed = false
            toggleCompleted.alphaValue = 1
            labelWork.textColor = NSColor.labelColor
            labelDate.textColor = NSColor.keyboardFocusIndicatorColor
            buttonDetails.alphaValue = 1
            labelWork.stringValue = work.title!
        }
        
        selectionDelegate?.isEditing(workBox: nil)
    }
    
}
