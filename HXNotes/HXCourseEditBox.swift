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
    static func instance(with course: Course, withCourseIndex index: Int, withParent parent: SidebarViewController) -> HXCourseEditBox! {
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
    weak var parentController: SidebarViewController!
    weak var course: Course!
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
    let ID_BOX_BACK         = "course_box_back"
    let ID_ADD_TIME         = "timeslot_add_button"
    let ID_STACKVIEW_TIMESLOT = "timeSlot_stack_view"
    // Elements of course box
    var boxDrag: NSBox!
    var labelCourse: CourseLabel!
    var buttonTrash: NSButton!
    var boxBack: NSBox!
    var timeSlotStackView: NSStackView!
    var timeSlotAddButton: NSButton!
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(with course: Course, withCourseIndex index: Int, withParent parent: SidebarViewController) {
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BOX_DRAG:
                boxDrag = v as! NSBox
            case ID_BUTTON_TRASH:
                buttonTrash = v as! NSButton
            case ID_LABEL_TITLE:
                labelCourse = v as! CourseLabel
            case ID_BOX_BACK:
                boxBack = v as! NSBox
            case ID_STACKVIEW_TIMESLOT:
                timeSlotStackView = v as! NSStackView
                for child in timeSlotStackView.arrangedSubviews[0].subviews {
                    if child.identifier == ID_ADD_TIME {
                        timeSlotAddButton = child as! NSButton
                    }
                }
            default: continue
            }
        }
        
        // Initialize course label functionality
        labelCourse.target = self
        labelCourse.action = #selector(self.endEditingCourseLabel)
        
        // Initialize button functionality
        buttonTrash.target = self
        buttonTrash.action = #selector(self.removeCourseBox)
        
        timeSlotAddButton.target = self
        timeSlotAddButton.action = #selector(self.addTimeSlot)
        
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
        
        Swift.print("HXCourseEditBox - initialize() : Print time slots!")
        for case let timeSlot as TimeSlot in course.timeSlots! {
            Swift.print("    timeSlot - Weekday: \(timeSlot.weekday)  Minute: \(timeSlot.startMinuteOfDay)")
            let newBox = HXTimeSlotBox.instance(with: timeSlot, for: self)
            let index = course.timeSlots!.index(of: newBox!.timeSlot)
            timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
        }
    }
    
    /// Removes this course box from the stack view
    func removeCourseBox() {
        
        if self.course.timeSlots!.count == 0 {
            confirmRemoveCourse()
            return
        }
        
        var lectureInfo = ""
        if self.course.lectures!.count == 1 {
            lectureInfo = " A lecture will be lost."
        } else if self.course.lectures!.count != 0 {
            lectureInfo = " \(self.course.lectures!.count) lectures will be lost."
        }
        
        let _ = Alert(course: self.course.title!, content: "is to be removed." + lectureInfo + " Confirm removal?", question: "Remove Course", deny: "Cancel", action: #selector(self.confirmRemoveCourse), target: self, type: .deletion)
    }
    /// Removes a timeSlot from this course
    func removeTimeSlot(_ timeSlot: TimeSlot) {
        parentController.removeTimeSlot(timeSlot)
    }
    /// Adds a timeSlot for this course
    func addTimeSlot() {
        let newBox = HXTimeSlotBox.instance(with: course.nextTimeSlot(), for: self)
        let index = course.timeSlots!.index(of: newBox!.timeSlot)
        timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
    }
    
    func confirmRemoveCourse() {
        Alert.flushAlerts(for: course.title!)
        parentController.removeCourse(self)
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
            // Rename course if the name isn't already taken
            if course.semester!.retrieveCourse(named: labelCourse.stringValue) == nil {
                course.title = labelCourse.stringValue
                parentController.masterViewController.notifyTimeSlotChange()
                oldName = labelCourse.stringValue
            } else {
                // Revoke name change
                labelCourse.stringValue = oldName
            }
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
        if !dragging {
            dragging = true
            buttonTrash.alphaValue = 0
            boxDrag.alphaValue = 0
            labelCourse.alphaValue = 0
//            boxBack.fillColor = NSColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
            NSCursor.closedHand().push()
        }
        parentController.mouseDrag_courseBox(with: self, to: event.locationInWindow)
    }
    
    override func mouseUp(with event: NSEvent) {
        labelCourse.alphaValue = 1
        if dragging {
            dragging = false
            buttonTrash.alphaValue = 1
            boxDrag.alphaValue = 1
            labelCourse.alphaValue = 1
//            boxBack.fillColor = NSColor.white
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
    
    // MARK: - Notifiers
    func notifyTimeSlotChange() {
        parentController.notifyTimeSlotChange()
        course.sortTimeSlots()
    }
}
