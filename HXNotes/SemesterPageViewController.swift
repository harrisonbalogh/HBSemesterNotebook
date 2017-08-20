//
//  SemesterPageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterPageViewController: NSViewController {
    
    var sidebarVC: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        print("sidebarVC.selectedSemester: \(sidebarVC.selectedSemester)")
        
        if sidebarVC.selectedSemester != nil {
            return
        }
        print("    sidebarVC.selectedSemester: \(sidebarVC.selectedSemester)")
        
        // Start with last semester opened
        var noPrev = true
        if let prevOpenCourse = CFPreferencesCopyAppValue(NSString(string: "previouslyOpenedCourse"), kCFPreferencesCurrentApplication) as? String {
            if prevOpenCourse != "nil" {
                let parseSem = prevOpenCourse.substring(to: (prevOpenCourse.range(of: ":")?.lowerBound)!)
                let remain = prevOpenCourse.substring(from: (prevOpenCourse.range(of: ":")?.upperBound)!)
                let parseYr = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseCourse = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                
                let semester = Semester.produceSemester(titled: parseSem.lowercased(), in: Int(parseYr)!)
                noPrev = false
                print("Remember")
                sidebarVC.masterVC.setDate(semester: semester)
                
                if parseCourse != "nil" {
                    if let course = semester.retrieveCourse(named: parseCourse) {
                        sidebarVC.next(from: course)
                    }
                    
                }
            }
        }
        
        // Or use today's date
        if noPrev {
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            // Get calendar date to deduce semester
            let yearComponent = calendar.component(.year, from: Date())
            print("Today's date")
            // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
            var semesterTitle = "spring"
            if calendar.component(.month, from: Date()) >= 7 {
                semesterTitle = "fall"
            }
            // Set the current semester displayed in the SidebarVC - might want to remeber last selected semester
            sidebarVC.masterVC.setDate(semester: Semester.produceSemester(titled: semesterTitle, in: yearComponent))
        }
        
    }
    
    // MARK: - Populating stackview
    
    @IBOutlet weak var courseStackView: NSStackView!
    
    /// Flushes out subviews in courseStackView and repopulates with a course box for every course in selectedSemester.
    /// Scheduling determines if the coures boxes are editable or clickable for content display.
    func reloadCourses(scheduling: Bool) {
        
        // Flush old views
        popCoursesInStackView()
        
        // Push course boxes
        if scheduling {
            // Scheduling
            
            // When first loading editable courses, append the 'New Course' button at end of courseStackView
            let addBox = HXCourseAddBox.instance(target: self, action: #selector(SemesterPageViewController.action_addCourse))
            courseStackView.addArrangedSubview(addBox!)
            addBox?.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
            
            // Add editable course boxes
            for case let course as Course in sidebarVC.selectedSemester.courses! {
                pushEditableCourseToStackView( course )
            }
            
        } else {
            // Not scheduling
            
            for case let course as Course in sidebarVC.selectedSemester.courses! {
                pushCourseToStackView( course )
            }
            
        }
        
    }
    /// Handles purely the visual aspect of courses. Internal use only. Adds a new HXCourseBox to the courseStackView.
    private func pushCourseToStackView(_ course: Course) {
        let newBox = HXCourseBox.instance(with: course, owner: self)
        courseStackView.addArrangedSubview(newBox!)
        newBox?.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
    }
    /// Handles purely the visual aspect of courses. Internal use only. Adds a new HXCourseEditBox to the courseStackView.
    private func pushEditableCourseToStackView(_ course: Course) {
        let newBox = HXCourseEditBox.instance(with: course, withCourseIndex: courseStackView.subviews.count-1, withParent: self)
        courseStackView.addArrangedSubview(newBox!)
        newBox?.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
    }
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given HXCourseEditBox from the ledgerStackView
    private func popEditableCourse(_ course: HXCourseEditBox) {
        course.removeFromSuperview()
    }
    
    /// Removes all subviews from courseStackView
    private func popCoursesInStackView() {
        for subview in courseStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    // MARK: - Course & TimeSlot Model
    
    /// Confirms removal of all information associated with a course object. Model and Views
    internal func removeCourse(_ editBox: HXCourseEditBox) {
        // Remove course from courseStackView
        popEditableCourse(editBox)
        // Update model
        appDelegate.managedObjectContext.delete( editBox.course )
        appDelegate.saveAction(self)
        sidebarVC.masterVC.notifyCourseDeletion()
        // Prevent user from accessing lecture view if there are no courses
        if sidebarVC.selectedSemester.courses!.count == 0 {
            sidebarVC.masterVC.notifyInvalidSemester()
        } else {
            // Check if the remaining courses have any TimeSlots
            for case let course as Course in sidebarVC.selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    sidebarVC.masterVC.notifyInvalidSemester()
                    return
                }
            }
            sidebarVC.masterVC.notifyValidSemester()
        }
    }
    
    func action_addCourse() {
        // Creates new course data model and puts new view in ledgerStackView
        pushEditableCourseToStackView( sidebarVC.selectedSemester.createCourse() )
    }
    
    // MARK: - Notifiers
    
    /// Inform the semesterVC that a timeSlot has been removed from a course edit box.
    func notifyTimeSlotRemoved(_ timeSlot: TimeSlot) {
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
        sidebarVC.notifyTimeSlotChange()
        
        sidebarVC.selectedSemester.needsValidate = true
    }
    
    /// Inform the semesterVC that timeSlot has been changed from a course.
    func notifyTimeSlotUpdated() {
        
        sidebarVC.selectedSemester.needsValidate = true
        
        sidebarVC.notifyTimeSlotChange()
    }
    
    /// Inform the semesterVC that one of its HXCourseBox's has been mouse clicked.
    func notifyCourseSelected(_ course: Course) {
        sidebarVC.next(from: course)
    }
    
}
