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
    static func instance(with course: Course, withCourseIndex index: Int, withParent parent: CourseViewController) -> HXCourseEditBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseEditBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseEditBox}).first as? HXCourseEditBox {
            newBox.initialize(with: course, withCourseIndex: index, withParent: parent)
            return newBox
        }
        return nil
    }
    
//    // Need to update course index when a course gets removed
//    var courseIndex: Int!
    var parentController: CourseViewController!
    var course: Course!
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
    var resizeIcon: NSImageView!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(with course: Course, withCourseIndex index: Int, withParent parent: CourseViewController) {
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BOX_DRAG:
                boxDrag = v as! NSBox
                resizeIcon = boxDrag.subviews.first!.subviews.first! as! NSImageView
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
        
        let theColor = NSColor(red: CGFloat(course.colorRed), green: CGFloat(course.colorGreen), blue: CGFloat(course.colorBlue), alpha: 1)
        self.boxDrag.fillColor = theColor
        
        self.parentController = parent
        
        let trackArea = NSTrackingArea(
            rect: self.bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        addTrackingArea(trackArea)
        
        self.course = course
        self.labelCourse.stringValue = course.title!
        self.oldName = course.title!
        
    }
    
    /// Removes this course box from the stack view
    func removeCourseBox() {
        parentController.action_removeCourseButton(course: self)
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
            parentController.action_courseTextField(self)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        var insideACursorArea = false
        
        let origin = boxDrag.superview!.convert(boxDrag.frame.origin, to: nil) as NSPoint
        let loc = event.locationInWindow
        if loc.x > origin.x && loc.x < origin.x + boxDrag.frame.width && loc.y > origin.y && loc.y < origin.y + boxDrag.frame.height {
            insideACursorArea = true
            if !insideDrag {
                NSCursor.openHand().pop()
                NSCursor.openHand().push()
                insideDrag = true
            }
        } else {
            if insideDrag && !dragging {
                insideDrag = false
            }
        }
        
        let originLabel = labelCourse.superview!.convert(labelCourse.frame.origin, to: nil) as NSPoint
        if loc.x > originLabel.x && loc.x < originLabel.x + labelCourse.frame.width && loc.y > originLabel.y && loc.y < originLabel.y + labelCourse.frame.height {
            insideACursorArea = true
            NSCursor.iBeam().pop()
            NSCursor.iBeam().push()
        }
        
        let originTrash = buttonTrash.superview!.convert(buttonTrash.frame.origin, to: nil) as NSPoint
        if loc.x > originTrash.x && loc.x < originTrash.x + buttonTrash.frame.width && loc.y > originTrash.y && loc.y < originTrash.y + buttonTrash.frame.height {
            insideACursorArea = true
            NSCursor.pointingHand().pop()
            NSCursor.pointingHand().push()
        }
        
        if !insideACursorArea {
            NSCursor.pop()
            NSCursor.pop()
            NSCursor.pop()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !dragging {
            if insideDrag {
                NSCursor.openHand().pop()
                insideDrag = false
            }
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        labelCourse.alphaValue = 0.5
        if !dragging {
            dragging = true
            resizeIcon.alphaValue = 0
            NSCursor.closedHand().push()
        }
        parentController.mouseDrag_courseBox(with: course, to: event.locationInWindow)
    }
    
    override func mouseUp(with event: NSEvent) {
        labelCourse.alphaValue = 1
        if dragging {
            dragging = false
            resizeIcon.alphaValue = 1
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
                    NSCursor.openHand().pop()
                    insideDrag = false
                }
            }
        }
        parentController.mouseUp_courseBox(for: course, at: event.locationInWindow)
    }
}
