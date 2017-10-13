//
//  HXTestBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterTestBox: NSView {
    
    var selectionDelegate: SelectionDelegate?
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with test: Test) -> SemesterTestBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("SemesterTestBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SemesterTestBox}).first as? SemesterTestBox {
            newBox.initialize(with: test)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTest: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var boxFill: NSBox!
    
    weak var test: Test!
    
    var recallDate = ""
    
    func initialize(with test: Test) {
        labelTest.stringValue = test.title!
        if test.date == nil {
            labelDate.stringValue = "Undated"
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
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.trackingAreas.forEach({self.removeTrackingArea($0)})
        
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .cursorUpdate, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand().set()
    }
    
    override func mouseEntered(with event: NSEvent) {
        selectionDelegate?.testWasHovered(test)
        hoverVisuals(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        hoverVisuals(false)
    }
    
    func hoverVisuals(_ visible: Bool) {
        if visible {
            if recallDate == "" {
                recallDate = labelDate.stringValue
            }
            labelDate.stringValue = "Go to " + test.course!.title!
        } else {
            if recallDate != "" {
                labelDate.stringValue = recallDate
                recallDate = ""
            }
        }
    }
    
    @IBAction func action_select(_ sender: NSButton) {
        selectionDelegate?.testWasSelected(test)
    }
}
