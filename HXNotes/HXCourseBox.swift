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
    
    weak var parent: SidebarViewController!
    weak var course: Course!
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDays: NSTextField!
    @IBOutlet weak var buttonOverlay: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(with course: Course, owner parent: SidebarViewController) {
        
        self.parent = parent
        self.course = course
        
        labelTitle.stringValue = course.title!
        labelDays.stringValue = course.daysPerWeekPrintable()
        
        let trackArea = NSTrackingArea(
            rect: self.bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackArea)
    }
    
    @IBAction func goToNotes(_ sender: Any) {
        if buttonOverlay.state == NSOnState {
            Swift.print("On state")
            self.select()
            parent.select(course: self.course)
        } else {
            Swift.print("Off state")
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
//        alphaValue = 0.5
    }
    
    override func mouseEntered(with event: NSEvent) {
//        alphaValue = 1
        NSCursor.pointingHand().push()
    }
    
    override func mouseExited(with event: NSEvent) {
        if buttonOverlay.state != NSOnState {
//            alphaValue = 0.5
        }
        NSCursor.pointingHand().pop()
    }
}
