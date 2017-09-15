//
//  SchedulerPageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerPageViewController: NSViewController {
    
    var schedulingDelegate: SchedulingDelegate?
    var sidebarDelegate: SidebarDelegate?
    
    /// Set this to update visuals for a semester that is no longer editable
    /// (happened in the past).
    var isPastSemester = false {
        didSet {
            if isPastSemester {
                addCourseButton.isEnabled = false
                addCourseButton.isHidden = true
                doneSchedulingButton.isEnabled = false
                doneSchedulingButton.isHidden = true
            } else {
                addCourseButton.isEnabled = true
                addCourseButton.isHidden = false
                doneSchedulingButton.isHidden = false
            }
        }
    }
    
    @IBOutlet weak var addCourseButton: NSButton!
    @IBOutlet weak var doneSchedulingButton: NSButton!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        sidebarDelegate?.sidebarSchedulingNeedsPopulating(self)
    }
    
    // MARK: - Populating (Editable) Courses
    
    @IBOutlet weak var courseStackView: NSStackView!
    @IBOutlet weak var noCourseLabel: NSTextField!
    
    func loadCourses(from semester: Semester) {
        
        // Flush old views
        flushCourses()
        
        // Push course edit boxes
        for case let course as Course in semester.courses! {
            push(course: course )
        }
        
        checkSchedule(for: semester)
    }
    
    func push(course: Course) {
        let newBox = SchedulerCourseBox.instance(with: course, schedulingDelegate: self.schedulingDelegate!)!
        courseStackView.addArrangedSubview(newBox)
        newBox.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
        
        if course.lectures!.count > 0 || isPastSemester {
            newBox.timeSlotAddButton.isEnabled = false
            newBox.timeSlotAddViewHeightConstraint.constant = 0
        }
        
    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given 
    /// HXCourseEditBox from the ledgerStackView
    func pop(courseBox: SchedulerCourseBox) {
        courseBox.removeFromSuperview()
    }
    
    func flushCourses() {
        if courseStackView != nil {
            for v in courseStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
        }
    }
    
    /// Displays or hides the noCourseLabel based on the given semester have more than one course
    /// and being valid. Also updates 'Done' button based on valid schedule.
    func checkSchedule(for semester: Semester) {
        if semester.needsValidate {
            semester.validateSchedule()
        }
        
        doneSchedulingButton.isEnabled = true
        
        if courseStackView.arrangedSubviews.count == 0 {
            noCourseLabel.alphaValue = 1
            noCourseLabel.isHidden = false
            
            doneSchedulingButton.isEnabled = false
        } else {
            noCourseLabel.alphaValue = 0
            noCourseLabel.isHidden = true
        }

        if !semester.valid {
            doneSchedulingButton.isEnabled = false
        }
        for case let course as Course in semester.courses! {
            if course.timeSlots!.count == 0 {
                doneSchedulingButton.isEnabled = false
            }
        }
    }
    
    // MARK: - Course & TimeSlot Model
    
    @IBAction func action_finishScheduling(_ sender: NSButton) {
        schedulingDelegate?.schedulingDidFinish()
    }
    
    @IBAction func action_addCourse(_ sender: NSButton) {
        schedulingDelegate?.schedulingAddCourse(self)
    }
    
    // MARK: - Notifiers
    
    /// Inform the semesterVC that a timeSlot has been removed from a course edit box.
    func notifyTimeSlotRemoved(_ timeSlot: TimeSlot) {
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
        
        schedulingDelegate?.schedulingNeedsValidation(self)
    }
}
