//
//  DragBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseDragBox: NSBox {
    
    /// Return a new instance of a HXCourseDragBox based on the nib template.
    static func instance() -> HXCourseDragBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseDragBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseDragBox}).first as? HXCourseDragBox {
            newBox.initialize()
            return newBox
        }
        return nil
    }
    
    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE      = "course_label_title"
    let ID_BOX_DRAG         = "course_box_drag"
    // Elements of course box
    var labelCourse: NSTextField!
    var boxDrag: NSBox!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    func initialize() {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelCourse = v as! NSTextField
            case ID_BOX_DRAG:
                boxDrag = v as! NSBox
            default: continue
            }
        }
        
    }

    /// Set this box to match the properties of the course provided
    func updateWithCourse(_ course: Course) {
        labelCourse.stringValue = course.title!
        boxDrag.fillColor = NSColor(
            red: CGFloat(course.colorRed),
            green: CGFloat(course.colorGreen),
            blue: CGFloat(course.colorBlue),
            alpha: 1)
    }
}
