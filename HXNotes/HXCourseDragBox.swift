//
//  DragBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseDragBox: NSBox {
    
    
    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE      = "course_label_title"
    // Elements of course box
    var labelCourse: CourseLabel!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize() {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelCourse = v as! CourseLabel
            default: continue
            }
        }
        
    }

}
