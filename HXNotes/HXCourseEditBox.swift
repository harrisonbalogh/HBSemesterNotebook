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
    static func instance(with course: Course, withCourseIndex index: Int, withParent parent: SemesterPageViewController) -> HXCourseEditBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseEditBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseEditBox}).first as? HXCourseEditBox {
            newBox.initialize(with: course, withCourseIndex: index, withParent: parent)
            return newBox
        }
        return nil
    }
    
    weak var parentController: SemesterPageViewController!
    weak var course: Course!
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
    private func initialize(with course: Course, withCourseIndex index: Int, withParent parent: SemesterPageViewController) {
        
        if course.lectures!.count > 0 {
            timeSlotAddButton.isEnabled = false
            timeSlotAddViewHeightConstraint.constant = 0
        }
        
        let theColor = NSColor(red: CGFloat(course.color!.red), green: CGFloat(course.color!.green), blue: CGFloat(course.color!.blue), alpha: 1)
        self.boxDrag.fillColor = theColor
        
        self.parentController = parent
        
        self.course = course
        self.labelCourse.stringValue = course.title!
        self.oldName = course.title!
        
        for case let timeSlot as TimeSlot in course.timeSlots! {
            let newBox = HXTimeSlotBox.instance(with: timeSlot, for: self)
            let index = course.timeSlots!.index(of: newBox!.timeSlot)
            timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
        }
    }
    
    // MARK: - Creating and Removing
    
    /// Removes this course box from the stack view
    @IBAction func removeCourseBox(_ sender: Any) {
        
        var confirmationFrequency = "NO_LECTURES"
        if let confirmPref = CFPreferencesCopyAppValue(NSString(string: "courseDeletionConfirmation"), kCFPreferencesCurrentApplication) as? String {
            confirmationFrequency = confirmPref
        }
        
        if confirmationFrequency == "NEVER" {
            confirmRemoveCourse()
            return
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
        
        let _ = Alert(course: self.course, content: "is to be removed." + lectureInfo + " Confirm removal?", question: "Remove Course", deny: "Cancel", action: #selector(self.confirmRemoveCourse), target: self, type: .deletion)

    }

    /// Adds a timeSlot for this course
    @IBAction func addTimeSlot(_ sender: Any) {
        let newBox = HXTimeSlotBox.instance(with: course.nextTimeSlot(), for: self)
        let index = course.timeSlots!.index(of: newBox!.timeSlot)
        timeSlotStackView.insertArrangedSubview(newBox!, at: index + 1)
        
        parentController.notifyTimeSlotUpdated()
    }
    
    func confirmRemoveCourse() {
        Alert.flushAlerts(for: course)
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
                parentController.notifyTimeSlotUpdated()
                oldName = labelCourse.stringValue
            } else {
                // Revoke name change
                labelCourse.stringValue = oldName
            }
        }
    }

    
    // MARK: - Notifiers
    func notifyTimeSlotRemoved(_ timeSlot: TimeSlot) {
        parentController.notifyTimeSlotRemoved(timeSlot)
    }
    func notifyTimeSlotChange() {
        parentController.notifyTimeSlotUpdated()
        course.needsSort = true
    }
}
