//
//  HXCourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseBox: NSBox {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with course: Course, owner parent: SidebarViewController) -> HXCourseBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
            newBox.initialize(with: course, owner: parent)
            return newBox
        }
        return nil
    }
    
    var parent: SidebarViewController!
    var course: Course!
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_TITLE = "course_button_title"
    let ID_LABEL_DAYS   = "course_days_label"
    // Elements of course box
    var buttonTitle: NSButton!
    var labelDays: NSTextField!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize(with course: Course, owner parent: SidebarViewController) {
        
        self.parent = parent
        self.course = course
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BUTTON_TITLE:
                buttonTitle = v as! NSButton
            case ID_LABEL_DAYS:
                labelDays = v as! NSTextField
            default: continue
            }
        }
        
        buttonTitle.title = course.title!
        // Initialize course label functionality
        buttonTitle.target = self
        buttonTitle.action = #selector(self.goToNotes)
        
        let trackArea = NSTrackingArea(
            rect: self.bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackArea)
    }
    
    func goToNotes() {
        if buttonTitle.state == NSOnState {
            self.select()
            parent.select(course: self.course)
        } else {
            self.deselect()
            parent.select(course: nil)
        }
    }
    
    func select() {
        buttonTitle.state = NSOnState
    }
    
    func deselect() {
        buttonTitle.state = NSOffState
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand().push()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.pointingHand().pop()
    }
    
}
