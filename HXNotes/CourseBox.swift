//
//  CourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseBox: NSBox {
    
    var trackingArea: NSTrackingArea!
    // Need to update course index when a course gets removed
    var courseIndex: Int!
    var parentCalendar: CalendarViewController!
    var originalColor: NSColor!
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_FILL      = "course_button_fill"
    let ID_BUTTON_TRASH     = "course_button_trash"
    let ID_LABEL_TITLE      = "course_label_title"
    let ID_LABEL_DRAG       = "course_label_drag"
    // Elements of course box
    var labelCourse: CourseLabel!
    var labelDragHere: NSTextField!
    var buttonFill: NSButton!
    var buttonTrash: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize(withCourseIndex index: Int, withColor color: NSColor, withParent parent: CalendarViewController) {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_BUTTON_FILL:
                buttonFill = v as! NSButton
            case ID_BUTTON_TRASH:
                buttonTrash = v as! NSButton
            case ID_LABEL_TITLE:
                labelCourse = v as! CourseLabel
            case ID_LABEL_DRAG:
                labelDragHere = v as! NSTextField
            default: continue
            }
        }
        
        // Initialize course label functionality
        labelCourse.target = self
        labelCourse.action = #selector(self.endEditingCourseLabel)
        
        // Initialize button functionality
        buttonTrash.target = self
        buttonTrash.action = #selector(self.removeCourseBox)
        
        self.originalColor = color
        
        self.parentCalendar = parent
        
        self.courseIndex = index;
        
        self.fillColor = color
        
        self.trackingArea = NSTrackingArea(
            rect: bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: ["index":index])
        
        addTrackingArea(trackingArea)
    }
    
    /// Removes this course box from the stack view
    func removeCourseBox() {
        parentCalendar.receiveCourseRemove(course: self)
    }
    
    /// Clear selection of course's title field
    func endEditingCourseLabel() {
        labelCourse.isEditable = false
        labelCourse.isSelectable = false
        parentCalendar.updateCourseName(atIndex: courseIndex, withName: labelCourse.stringValue)
    }
    
    func updateIndex(index: Int) {
        self.courseIndex = index
    }
    
    override func mouseDragged(with event: NSEvent) {
        Swift.print("Index of drag: \(courseIndex)")
        fillColor = NSColor.white
        buttonFill.isEnabled = false
        buttonTrash.isEnabled = false
        buttonFill.isHidden = true
        buttonTrash.isHidden = true
        labelDragHere.alphaValue = 0
        labelCourse.alphaValue = 0.5
        parentCalendar.receiveMouseDragFromCourse(course: self, toLocation: event.locationInWindow)
    }
    
    override func mouseUp(with event: NSEvent) {
        fillColor = originalColor
        buttonFill.isEnabled = true
        buttonTrash.isEnabled = true
        buttonFill.isHidden = false
        buttonTrash.isHidden = false
        labelDragHere.alphaValue = 1
        labelCourse.alphaValue = 1
        parentCalendar.receiveMouseDragStopFromCourse(atLocation: event.locationInWindow)
    }
    
    override func mouseEntered(with event: NSEvent) {
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
    }
}
