//
//  CourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseEditBox: NSView {
    
    /// Return a new instance of a HXCourseEditBox based on the nib template.
    static func instance(withTitle title: String, withCourseIndex index: Int, withColor color: NSColor, withParent parent: CourseViewController) -> HXCourseEditBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseEditBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseEditBox}).first as? HXCourseEditBox {
            newBox.initialize(withTitle: title, withCourseIndex: index, withColor: color, withParent: parent)
            return newBox
        }
        return nil
    }
    
    var trackingArea: NSTrackingArea!
//    // Need to update course index when a course gets removed
//    var courseIndex: Int!
    var parentCalendar: CourseViewController!
    var originalColor: NSColor!
    // Note when cursor is inside the area to drag box (to calendar)
    var insideDrag = false
    // Note when user started dragging after being in drag region
    var dragging = false
    // Retain name of course before editing to update data model
    var oldName = ""
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_TRASH     = "course_button_trash"
    let ID_LABEL_TITLE      = "course_label_title"
    let ID_BOX_DRAG         = "course_box_drag"
    // Elements of course box
    var boxDrag: NSBox!
    var labelCourse: CourseLabel!
    var buttonTrash: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(withTitle title: String, withCourseIndex index: Int, withColor color: NSColor, withParent parent: CourseViewController) {
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BOX_DRAG:
                boxDrag = v as! NSBox
            case ID_BUTTON_TRASH:
                buttonTrash = v as! NSButton
            case ID_LABEL_TITLE:
                labelCourse = v as! CourseLabel
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
        
        self.boxDrag.fillColor = color
        
        self.parentCalendar = parent
        
        self.trackingArea = NSTrackingArea(
            rect: boxDrag.bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: ["index":index])
        
        addTrackingArea(trackingArea)
        
        self.labelCourse.stringValue = title
        self.oldName = title
        
    }
    
    /// Removes this course box from the stack view
    func removeCourseBox() {
        parentCalendar.action_removeCourseButton(course: self)
    }
    
    /// Clear selection of course's title field
    func endEditingCourseLabel() {
        labelCourse.isEditable = false
        labelCourse.isSelectable = false
        labelCourse.stringValue = labelCourse.stringValue.trimmingCharacters(in: .whitespaces)
        
        // Check if it has content
        if labelCourse.stringValue == "" {
            labelCourse.stringValue = oldName
        } else {
            parentCalendar.action_courseTextField(self)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let origin = boxDrag.superview!.convert(boxDrag.frame.origin, to: nil) as NSPoint
        let loc = event.locationInWindow
        if loc.x > origin.x && loc.x < origin.x + boxDrag.frame.width && loc.y > origin.y && loc.y < origin.y + boxDrag.frame.height {
            if !insideDrag {
                NSCursor.openHand().push()
                insideDrag = true
            }
        } else {
            if insideDrag && !dragging {
                Swift.print("Popping an openHand from mouseMoved")
                NSCursor.openHand().pop()
                insideDrag = false
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !dragging {
            if insideDrag {
                Swift.print("Popping an openHand from mouseExited")
                NSCursor.openHand().pop()
                insideDrag = false
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        labelCourse.alphaValue = 0.5
        if !dragging {
            dragging = true
            NSCursor.closedHand().push()
        }
//        parentCalendar.mouseDrag_courseBox(course: self, toLocation: event.locationInWindow)
    }
    
    override func mouseUp(with event: NSEvent) {
        labelCourse.alphaValue = 1
        if dragging {
            dragging = false
            Swift.print("Popping a closedHand from mouseUp")
            NSCursor.closedHand().pop()
            let origin = boxDrag.superview!.convert(boxDrag.frame.origin, to: nil) as NSPoint
            let loc = event.locationInWindow
            if loc.x > origin.x && loc.x < origin.x + boxDrag.frame.width && loc.y > origin.y && loc.y < origin.y + boxDrag.frame.height {
                if !insideDrag {
                    NSCursor.openHand().push()
                    insideDrag = true
                }
            } else {
                if insideDrag {
                    Swift.print("Popping an openHand from mouseUp")
                    NSCursor.openHand().pop()
                    insideDrag = false
                }
            }
        }
//        parentCalendar.mouseUp_courseBox(atLocation: event.locationInWindow)
    }
}
