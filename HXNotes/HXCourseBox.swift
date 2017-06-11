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
    let ID_BUTTON_OVERLAY = "course_overlay_button"
    let ID_LABEL_DAYS     = "course_days_label"
    let ID_LABEL_TITLE    = "course_title_label"
    // Elements of course box
    var buttonOverlay: NSButton!
    var labelDays: NSTextField!
    var labelTitle: NSTextField!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(with course: Course, owner parent: SidebarViewController) {
        
        self.parent = parent
        self.course = course
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelTitle = v as! NSTextField
            case ID_BUTTON_OVERLAY:
                buttonOverlay = v as! NSButton
            case ID_LABEL_DAYS:
                labelDays = v as! NSTextField
            default: continue
            }
        }
        
        labelTitle.stringValue = course.title!
        labelDays.stringValue = parent.daysPerWeek(for: course)
        // Initialize course label functionality
        buttonOverlay.target = self
        buttonOverlay.action = #selector(self.goToNotes)
        
        let trackArea = NSTrackingArea(
            rect: self.bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackArea)
    }
    
    func goToNotes() {
        if buttonOverlay.state == NSOnState {
            self.select()
            parent.select(course: self.course)
        } else {
            self.deselect()
            parent.select(course: nil)
        }
    }
    
    func select() {
        buttonOverlay.state = NSOnState
        labelTitle.font = NSFont.boldSystemFont(ofSize: 16)
        alphaValue = 1
    }
    
    func deselect() {
        buttonOverlay.state = NSOffState
        labelTitle.font = NSFont.systemFont(ofSize: 12)
        alphaValue = 0.5
    }
    
    override func mouseEntered(with event: NSEvent) {
        alphaValue = 1
        NSCursor.pointingHand().push()
    }
    
    override func mouseExited(with event: NSEvent) {
        if buttonOverlay.state != NSOnState {
            alphaValue = 0.5
        }
        NSCursor.pointingHand().pop()
    }
}
