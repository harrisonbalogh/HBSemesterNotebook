//
//  SchedulerCourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerCourseBox: NSView {
    
    var schedulingDelegate: SchedulingDelegate?
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with course: Course, schedulingDelegate: SchedulingDelegate) -> SchedulerCourseBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("SchedulerCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SchedulerCourseBox}).first as? SchedulerCourseBox {
            newBox.initialize(with: course, schedulingDelegate: schedulingDelegate)
            return newBox
        }
        return nil
    }
    
    weak var course: Course!
    
    // Retain name of course before editing to update data model
    var oldName = ""
    
    @IBOutlet weak var boxBack: NSBox!
    @IBOutlet weak var boxDrag: NSBox!
    @IBOutlet weak var labelCourse: NSTextField!
    @IBOutlet weak var labelLocation: NSTextField!
    @IBOutlet weak var labelProfessor: NSTextField!
    @IBOutlet weak var timeSlotStackView: NSStackView!
    @IBOutlet weak var timeSlotAddButton: NSButton!
    @IBOutlet weak var buttonTrash: NSButton!

    private func initialize(with course: Course, schedulingDelegate: SchedulingDelegate) {
        self.course = course
        self.schedulingDelegate = schedulingDelegate
        
        let theColor = NSColor(red: CGFloat(course.color!.red), green: CGFloat(course.color!.green), blue: CGFloat(course.color!.blue), alpha: 1)
        self.boxDrag.fillColor = theColor
        
        self.labelCourse.stringValue = course.title!
        if course.professor == nil {
            self.labelProfessor.stringValue = ""
        } else {
            self.labelProfessor.stringValue = course.professor!
        }
        if course.location == nil {
            self.labelLocation.stringValue = ""
        } else {
            self.labelLocation.stringValue = course.location!
        }
        self.oldName = course.title!
        
        for case let timeSlot as TimeSlot in course.timeSlots! {
            let newBox = SchedulerTimeSlotBox.instance(with: timeSlot)
            newBox?.schedulingDelegate = schedulingDelegate
            let index = course.timeSlots!.index(of: newBox!.timeSlot)
            timeSlotStackView.insertArrangedSubview(newBox!, at: index)
        }
    }
    
    // MARK: - Creating and Removing
    
    /// Removes this course box from the stack view
    @IBAction func removeCourseBox(_ sender: Any) {
        
        let confirmationFrequency = AppPreference.courseDeletionConfirmation
        
        if confirmationFrequency == .NEVER {
            confirmRemoveCourse()
            return
        }
        
        if self.course.timeSlots!.count == 0 && confirmationFrequency != .ALWAYS {
            confirmRemoveCourse()
            return
        }
        
        var lectureInfo = ""
        if self.course.lectures!.count == 1 {
            lectureInfo = " A lecture will be lost."
        } else if self.course.lectures!.count != 0 {
            lectureInfo = " \(self.course.lectures!.count) lectures will be lost."
        } else if confirmationFrequency == .NO_LECTURES {
            confirmRemoveCourse()
            return
        }
        
        let _ = Alert(course: self.course, content: "is to be removed." + lectureInfo + " Confirm removal?", question: "Remove Course", deny: "Cancel", action: #selector(self.confirmRemoveCourse), target: self, type: .deletion)
        
    }
    
    /// Adds a timeSlot for this course
    @IBAction func addTimeSlot(_ sender: NSButton) {
        let newBox = SchedulerTimeSlotBox.instance(with: course.nextTimeSlotSpace())
        newBox?.schedulingDelegate = schedulingDelegate
        let index = course.timeSlots!.index(of: newBox!.timeSlot)
        timeSlotStackView.insertArrangedSubview(newBox!, at: index)
        
        schedulingDelegate?.schedulingUpdatedTimeSlot()
    }
    
    func confirmRemoveCourse() {
        schedulingDelegate?.schedulingRemove(course: course)
    }
    
    /// Clear selection of course's title field
    @IBAction func endEditingCourseLabel(_ sender: Any) {
        labelCourse.stringValue = labelCourse.stringValue.trimmingCharacters(in: .whitespaces)
        
        // Check if it has content
        if labelCourse.stringValue == "" {
            labelCourse.stringValue = oldName
        } else {
            // Rename course if the name isn't already taken
            Swift.print("course.semester!: \(course.semester)")
            if course.semester!.retrieveCourse(named: labelCourse.stringValue) == nil {
                course.title = labelCourse.stringValue
                schedulingDelegate?.schedulingRenameCourse()
                oldName = labelCourse.stringValue
            } else {
                // Revoke name change
                labelCourse.stringValue = oldName
            }
        }
    }
    @IBAction func endEditingCourseLocation(_ sender: NSTextField) {
        course.location = sender.stringValue
    }
    @IBAction func endEditingCourseProfessor(_ sender: NSTextField) {
        course.professor = sender.stringValue
    }
    
    // MARK: - Coloring Course
    @IBAction func action_colorWheel(_ sender: NSButton) {
        sender.window!.makeFirstResponder(sender)
        NSApp.orderFrontColorPanel(self)
        NSColorPanel.shared().setTarget(self)
        NSColorPanel.shared().showsAlpha = false
        NSColorPanel.shared().color = self.boxDrag.fillColor
    }
    override func changeColor(_ sender: Any?) {
        if let sender = sender as? NSColorPanel  {
            self.boxDrag.fillColor = sender.color
            course.color!.red = Float(sender.color.redComponent)
            course.color!.green = Float(sender.color.greenComponent)
            course.color!.blue = Float(sender.color.blueComponent)
            schedulingDelegate?.schedulingReloadScheduler()
        }
    }
}
