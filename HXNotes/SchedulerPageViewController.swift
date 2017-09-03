//
//  SchedulerPageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerPageViewController: NSViewController {
    
    weak var sidebarVC: SidebarPageController!
    
    var isPastSemester = false {
        didSet {
            if isPastSemester {
                addCourseButton.isEnabled = false
                addCourseButton.isHidden = true
            } else {
                addCourseButton.isEnabled = true
                addCourseButton.isHidden = false
            }
        }
    }
    
    @IBOutlet weak var addCourseButton: NSButton!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        print("SchedulerVC - viewDidAppear")
        
        isPastSemester = sidebarVC.selectedSemester.isEarlier(than: sidebarVC.semesterToday)
        
        loadCourses()
        
//        sidebarVC.notifySelectedScheduler()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        print("SchedulerVC - viewWillDisappear")
    }
    
    // MARK: - Populating (Editable) Courses
    
    @IBOutlet weak var courseStackView: NSStackView!
    @IBOutlet weak var noCourseLabel: NSTextField!
    
    func loadCourses() {
        
        // Flush old views
        flushCourses()
        
        // Push course edit boxes
        for case let course as Course in sidebarVC.selectedSemester.courses! {
            push(course: course )
        }
        
        noCoursecheck()
        
    }
    
    func push(course: Course) {
        let newBox = SchedulerCourseBox.instance(with: course, owner: self)!
        courseStackView.addArrangedSubview(newBox)
        newBox.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given HXCourseEditBox from the ledgerStackView
    func pop(courseBox: SchedulerCourseBox) {
        courseBox.removeFromSuperview()
        
        noCoursecheck()
    }
    
    func flushCourses() {
        if courseStackView != nil {
            for v in courseStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
        }
        
        noCoursecheck()
    }
    
    /// Displays or hides the noCourseLabel based on courseStackView arranged subviews having boxes or not.
    func noCoursecheck() {
        
        if courseStackView.arrangedSubviews.count == 0 {
            noCourseLabel.alphaValue = 1
            noCourseLabel.isHidden = false
        } else {
            noCourseLabel.alphaValue = 0
            noCourseLabel.isHidden = true
        }
        
    }
    
    // MARK: - Course & TimeSlot Model
    
    /// Confirms removal of all information associated with a course object. Model and Views
    internal func removeCourse(_ courseBox: SchedulerCourseBox) {
        // Remove course from courseStackView
        pop(courseBox: courseBox)
        // Update model
        appDelegate.managedObjectContext.delete( courseBox.course )
        appDelegate.saveAction(self)
        sidebarVC.notifyTimeSlotChange()
        // Prevent user from accessing lecture view if there are no courses
        if sidebarVC.selectedSemester.courses!.count == 0 {
//            sidebarVC.masterVC.notifyInvalidSemester()
        } else {
            // Check if the remaining courses have any TimeSlots
            for case let course as Course in sidebarVC.selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
//                    sidebarVC.masterVC.notifyInvalidSemester()
                    return
                }
            }
//            sidebarVC.masterVC.notifyValidSemester()
        }
    }
    
    @IBAction func action_addCourse(_ sender: NSButton) {
        // Creates new course data model and puts new view in ledgerStackView
        push(course: sidebarVC.selectedSemester.createCourse() )
        
        noCoursecheck()
        
        notifyTimeSlotUpdated()
    }
    
    // MARK: - Notifiers
    
    /// Inform the semesterVC that a timeSlot has been removed from a course edit box.
    func notifyTimeSlotRemoved(_ timeSlot: TimeSlot) {
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
        sidebarVC.notifyTimeSlotChange()
        
        print("notifyTimeSlotRemoved")
        
        sidebarVC.selectedSemester.needsValidate = true
    }
    
    /// Inform the semesterVC that timeSlot has been changed from a course.
    func notifyTimeSlotUpdated() {
        
        print("notifyTimeSlotUpdated")
        
        sidebarVC.selectedSemester.needsValidate = true
        
        sidebarVC.notifyTimeSlotChange()
    }
    
    /// Inform the semester VC that timeSlot has been renamed. This does not require revalidation.
    func notifyTimeSlotRenamed() {
        
        sidebarVC.notifyTimeSlotChange()
    
    }
    
}
