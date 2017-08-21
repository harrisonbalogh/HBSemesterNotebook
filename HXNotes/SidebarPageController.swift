//
//  SidebarPageController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SidebarPageController: NSPageController, NSPageControllerDelegate {
    
    var singleSelectPref = true

    @IBOutlet var semesterVC: SemesterPageViewController!
    @IBOutlet var courseVC: CoursePageViewController!
    var masterVC: MasterViewController!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.delegate = self
        self.arrangedObjects = ["semesterPage", "coursePage"]
        
        semesterVC.sidebarVC = self
        courseVC.sidebarVC = self
        
        loadPreferences()
    }
    
    func loadPreferences() {
        if let singleSelect = CFPreferencesCopyAppValue(NSString(string: "assumeSingleSelection"), kCFPreferencesCurrentApplication) as? String {
            if singleSelect == "true" {
                singleSelectPref = true
            } else if singleSelect == "false" {
                singleSelectPref = false
            }
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        courseVC.view.layout()
    }
    
    // MARK: - Page Controller Delegate methods
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        switch identifier {
        case "semesterPage":
            return semesterVC
        case "coursePage":
            return courseVC
        default:
            return semesterVC
        }
    }
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
    }
    /// Slide to course page
    func next(from course: Course) {
        selectedCourse = course
    }
    /// Slide to semester page
    func prev() {
        
        selectedCourse = nil
    }
    
    // MARK: - Model
    
    /// Creates a new Lecture data object and updates lectureStackView visuals with a new HXLectureBox.
    /// This assumes that an alert called addLecture.
    public func addLecture() {
        
        // Hide the static button
        if selectedCourse != nil {
            courseVC.addButton.isHidden = true
            courseVC.addButton.isEnabled = false
        }
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        
        // See if the current semester exists in the persistant store
        if let currentSemester = Semester.retrieveSemester(titled: semesterTitle, in: yearComponent) {
            if let timeSlotHappening = currentSemester.duringCourse() {
                if timeSlotHappening.course!.theoreticalLectureCount() != timeSlotHappening.course!.lectures!.count || timeSlotHappening.course!.theoreticalLectureCount() == 0 {
                    if selectedSemester != currentSemester {
                        selectedSemester = currentSemester
                    }
                    if selectedCourse != timeSlotHappening.course! {
                        selectedCourse = timeSlotHappening.course!
                    }
                    
                    Alert.flushAlerts(for: selectedCourse)
                    
                    // Displays lecture in the lectureStackView
                    let newLec = timeSlotHappening.course!.createLecture(during: timeSlotHappening.course!.duringTimeSlot()!, on: nil, in: nil)
                    
                    courseVC.loadLectures()
                    
                    // Displays lecture in the lectureStackView
                    masterVC.notifyLectureAddition(lecture: newLec)
                } else {
                    print("No lectures to add??? Theoretical count: \(timeSlotHappening.course!.theoreticalLectureCount())")
                }
            } else {
                // User probably waited too long to accept lecture, so display error
                let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
                let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
                let _ = Alert(hour: hour, minute: minute, course: nil, content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil, type: .custom)
            }
        }
    }
    
    // MARK: - Control flow for SemesterVC
    
    /// The current semester displayed in the sidebar. Setting this value will update visuals.
    var selectedSemester: Semester! {
        didSet {
            if selectedCourse != nil {
                self.selectedCourse = nil
            }
            
            self.scheduling = !scheduleCheck()
            
            // This can be changed in preferences
            if selectedSemester.courses!.count == 1 && singleSelectPref {
                // Only 1 course in semester, so select it if preference set
                selectedCourse = (selectedSemester.courses![0] as! Course)
            }
        }
    }
    
    /// The current course displayed in the sidebar. Setting this value will update visuals.
    var selectedCourse: Course! {
        didSet {
            
            if selectedCourse == nil {
                print("                                                Nil selected course")
                self.navigateBack(self)
                masterVC.notifySemester(selectedSemester, is: false)
                return
            }
            if oldValue == nil || selectedCourse != oldValue {
                self.navigateForward(self)
                self.navigateForward(self)
                
                // Notify masterViewController that a course was selected
                masterVC.notifyCourseSelection(course: selectedCourse)
            }
        }
    }
    
    /// This determines whether or not the courseStackView is showing subviews
    /// that allow the changing of the schedule or the browsing of course content.
    var scheduling = false {
        didSet {
            
            if scheduling && selectedCourse != nil {
                selectedCourse = nil
            }
            
            scheduleCheck()
            
            if scheduling {
                masterVC.editSemesterButton.state = NSOffState
            } else {
                masterVC.editSemesterButton.state = NSOnState
            }
            
            masterVC.notifySemester(self.selectedSemester, is: scheduling)
            semesterVC.reloadCourses(scheduling: scheduling)
        }
    }
    
    @discardableResult func scheduleCheck() -> Bool {
        // UI control flow update - Note the RETURN calls
        if self.selectedSemester.courses!.count == 0 {
            masterVC.notifyInvalidSemester()
            return false
        }
        if self.selectedSemester.needsValidate {
            self.selectedSemester.validateSchedule()
        }
        if !self.selectedSemester.valid {
            masterVC.notifyInvalidSemester()
            return false
        }
        for case let course as Course in self.selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                masterVC.notifyInvalidSemester()
                return false
            }
        }
        masterVC.notifyValidSemester()
        return true
    }
    
    // MARK: - Notifiers
    
    func notifyTimeSlotChange() {
        masterVC.notifyTimeSlotChange()
        
        scheduleCheck()
    }
}
