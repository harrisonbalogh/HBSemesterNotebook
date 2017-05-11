//
//  HXCourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseBox: NSBox {
    
    var parent: EditorViewController!
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_TITLE = "course_button_title"
    // Elements of course box
    var buttonTitle: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize(withTitle: String, parent: EditorViewController) {
        
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
        self.select()
        parent.selectCourse(withTitle: buttonTitle.title)
    }
    
    func select() {
        buttonTitle.state = NSOnState
    }
    
    func deselect() {
        buttonTitle.state = NSOffState
    }
    
}
