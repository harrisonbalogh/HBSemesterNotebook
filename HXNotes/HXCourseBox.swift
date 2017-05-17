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
    static func instance(withTitle title: String, withParent parent: CourseViewController) -> HXCourseBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
            newBox.initialize(withTitle: title, parent: parent)
            return newBox
        }
        return nil
    }
    
    var parent: CourseViewController!
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_TITLE = "course_button_title"
    // Elements of course box
    var buttonTitle: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize(withTitle: String, parent: CourseViewController) {
        
        self.parent = parent
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BUTTON_TITLE:
                buttonTitle = v as! NSButton
            default: continue
            }
        }
        
        buttonTitle.title = withTitle
        // Initialize course label functionality
        buttonTitle.target = self
        buttonTitle.action = #selector(self.goToNotes)
    }
    
    func goToNotes() {
        if buttonTitle.state == NSOnState {
            self.select()
            parent.selectCourse(withTitle: buttonTitle.title)
        } else {
            parent.clearSelectedCourse()
            self.deselect()
        }
    }
    
    func select() {
        buttonTitle.state = NSOnState
    }
    
    func deselect() {
        buttonTitle.state = NSOffState
    }
    
}
