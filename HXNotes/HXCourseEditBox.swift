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
    
    @IBOutlet weak var boxBack: NSBox!
    @IBOutlet weak var boxDrag: NSBox!
    @IBOutlet weak var labelCourse: CourseLabel!
    @IBOutlet weak var timeSlotStackView: NSStackView!
    @IBOutlet weak var timeSlotAddButton: NSButton!
    @IBOutlet weak var buttonTrash: NSButton!
    
    @IBOutlet weak var timeSlotAddViewHeightConstraint: NSLayoutConstraint!
    
    
    /// Initialize the color, index, and tracking area of the CourseBox view
    private func initialize(with course: Course, withCourseIndex index: Int, withParent parent: SidebarViewController) {
        
        if course.lectures!.count > 0 {
            timeSlotAddButton.isEnabled = false
            timeSlotAddViewHeightConstraint.constant = 0
        }
        
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
        
        for case let timeSlot as TimeSlot in course.timeSlots! {
            let newBox = HXTimeSlotBox.instance(with: timeSlot, for: self)
            let index = course.timeSlots!.index(of: newBox!.timeSlot)
            timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
        }
    }
    
    /// Removes this course box from the stack view
    @IBAction func removeCourseBox(_ sender: Any) {
        
        var confirmationFrequency = "NO_LECTURES"
        if let confirmPref = CFPreferencesCopyAppValue(NSString(string: "courseDeletionConfirmation"), kCFPreferencesCurrentApplication) as? String {
            confirmationFrequency = confirmPref
        }
        
        if confirmationFrequency == "NEVER" {
            confirmRemoveCourse()
        }
        
        if self.course.timeSlots!.count == 0 && confirmationFrequency != "ALWAYS" {
            confirmRemoveCourse()
            return
        }
        
        var lectureInfo = ""
        if self.course.lectures!.count == 1 {
            lectureInfo = " A lecture will be lost."
        } else if self.course.lectures!.count != 0 {
            lectureInfo = " \(self.course.lectures!.count) lectures will be lost."
        } else if confirmationFrequency == "NO_LECTURES" {
            confirmRemoveCourse()
            return
        }
        
        let _ = Alert(course: self.course.title!, content: "is to be removed." + lectureInfo + " Confirm removal?", question: "Remove Course", deny: "Cancel", action: #selector(self.confirmRemoveCourse), target: self, type: .deletion)

    }

    /// Removes a timeSlot from this course
    func removeTimeSlot(_ timeSlot: TimeSlot) {
        parentController.removeTimeSlot(timeSlot)
    }
    /// Adds a timeSlot for this course
    @IBAction func addTimeSlot(_ sender: Any) {
        let newBox = HXTimeSlotBox.instance(with: course.nextTimeSlot(), for: self)
        let index = course.timeSlots!.index(of: newBox!.timeSlot)
        timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
    }
    
    func confirmRemoveCourse() {
        Alert.flushAlerts(for: course.title!)
        parentController.removeCourse(self)
    }
    
    /// Clear selection of course's title field
    @IBAction func endEditingCourseLabel(_ sender: Any) {
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
