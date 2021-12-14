//
//  MenuBarLectureItem.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MenuBarLectureItem: NSView {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with timeSlot: TimeSlot) -> MenuBarLectureItem! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "MenuBarLectureItem"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is MenuBarLectureItem}).first as? MenuBarLectureItem {
            newBox.initialize(with: timeSlot)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var courseTitleLabel: NSTextField!
    @IBOutlet weak var timeSlotStartLabel: NSTextField!
    
    
    func initialize(with timeSlot: TimeSlot) {
        courseTitleLabel.stringValue = timeSlot.course!.title!
        
        timeSlotStartLabel.stringValue = "\(HXTimeFormatter.formatTime(timeSlot.startMinute))"
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
