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
    
    var semesterToday: Semester!

    @IBOutlet var schedulerVC: SchedulerPageViewController!
    @IBOutlet var semesterVC: SemesterPageViewController!
    @IBOutlet var courseVC: CoursePageViewController!
    
    let SBSchedulerIndex = 0
    let SBSemesterIndex = 1
    let SBCourseIndex = 2
    
    var masterVC: MasterViewController!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.delegate = self
        self.arrangedObjects = ["schedulerPage", "semesterPage", "coursePage"]
        
        schedulerVC.sidebarVC = self
        semesterVC.sidebarVC = self
        courseVC.sidebarVC = self
        
        loadPreferences()
        
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
                
                masterVC.setDate(semester: semester)
                
                if parseCourse != "nil" {
                    if let course = semester.retrieveCourse(named: parseCourse) {
//                        next(from: course)
                    }
                }
            }
        }
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        // Set the current semester displayed in the SidebarVC - might want to remeber last selected semester
        semesterToday = Semester.produceSemester(titled: semesterTitle, in: yearComponent)
        // Or use today's date
        if noPrev {
            masterVC.setDate(semester: semesterToday)
        }
    }
    
    public func loadPreferences() {
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
        
        if semesterVC != nil && self.selectedIndex == SBSemesterIndex {
            semesterVC.view.frame = self.view.bounds
        }
        
        if courseVC != nil && self.selectedIndex == SBCourseIndex {
            courseVC.view.frame = self.view.bounds
        }
        
        if schedulerVC != nil && self.selectedIndex == SBSchedulerIndex {
            schedulerVC.view.frame = self.view.bounds
        }
    }
    
    // MARK: - Page Controller Delegate methods
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        switch identifier {
        case "schedulerPage":
            return schedulerVC
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
        
        // If just transitioned to semesterVC but there's a course selected, transition again
        if pageController.selectedIndex == SBSemesterIndex {
            
            if self.isScheduling {
                
                prev()
//                notifySelectedScheduler()
                
            } else if selectedCourse != nil {
                
                next(from: selectedCourse)
                
            } else {
                
//                notifySelectedSemester()
                
            }
        } else if pageController.selectedIndex == SBSchedulerIndex {
            
            if !self.isScheduling {
                
                next()
                
            } else {
                
//                notifySelectedScheduler()
                
            }
            
        } else { // selectedIndex == SBCourseIndex
            
            if selectedCourse.lectures!.count == 0 {
                notifySelected(lecture: nil)
            } else {
                notifySelected(lecture: (selectedCourse.lectures!.lastObject as! Lecture))
            }
            
        }
    }
    
    /// Slide to course page (assumed) from the SemesterVC.
    func next(from course: Course) {
        
        selectedCourse = course
        
        self.navigateForward(self)
        
    }
    /// Slide to semester pagd from the SchedulerVC
    func next() {
        
        self.navigateForward(self)
        
    }
    
    /// Slide to semester page (assumed) from the CourseVC.
    func prev() {
        
        masterVC.notifySelected(lecture: nil)
        selectedCourse = nil
        
        self.navigateBack(self)
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
                    } else {
                        selectedCourse.fillAbsentLectures()
                    }
                    
                    Alert.flushAlerts(for: selectedCourse)
                    
                    // Create new lecture
                    timeSlotHappening.course!.createLecture(during: timeSlotHappening.course!.duringTimeSlot()!, on: nil, in: nil)
                    
                    // Displays lecture in the lectureStackView
                    courseVC.loadLectures()

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
    
    override func scrollWheel(with event: NSEvent) {
        if event.deltaX > 0 {
            super.scrollWheel(with: event)
        }
    }
    
    // MARK: - Control flow for SemesterVC
    
    /// The current semester displayed in the sidebar. Setting this value will update visuals.
    var selectedSemester: Semester! {
        didSet {
            print("selectedSemester: \(selectedSemester.title)")
            self.isScheduling = scheduleCheck()
            self.notifyTimeSlotChange()
            
        }
    }
    
    /// The current course displayed in the sidebar. Setting this value will update visuals.
    var selectedCourse: Course!
    
    /// This determines whether or not the PageViewController is on the Semester or
    /// Scheduler page.
    private var isScheduling = true {
        didSet {
            print("isScheduling: \(isScheduling)")
            if selectedCourse != nil {
                selectedCourse = nil
            }
        }
    }
    
    /// Notifies masterVC that the user shouldnt be able to leave the scheduler if a course doesn't have
    /// valid timeslots. Will return false if the schedule does not check out. This effectively is just
    /// checking the 'valid' attribute on a semester. It will run through a validateSchedule() call if the
    /// semester needs it.
    @discardableResult func scheduleCheck() -> Bool {
        // UI control flow update - Note the RETURN calls
        if self.selectedSemester.courses!.count == 0 {
//            masterVC.notifyInvalidSemester()
            print("scheduleCheck no_course")
            return false
        }
        if self.selectedSemester.needsValidate {
            self.selectedSemester.validateSchedule()
        }
        if !self.selectedSemester.valid {
            print("scheduleCheck invalid")
//            masterVC.notifyInvalidSemester()
            return false
        }
        for case let course as Course in self.selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
//                masterVC.notifyInvalidSemester()
                print("scheduleCheck no_times")
                return false
            }
        }
//        masterVC.notifyValidSemester()
        print("scheduleCheck gucci")
        return true
    }
    
    // MARK: - Notifiers
    
    func notifyScheduling(is scheduling: Bool) {
        
        self.isScheduling = scheduling
        
        if scheduling {
            
            if self.selectedIndex == SBSchedulerIndex {
                // Scheduler already shown, reload courses for new semester selection.
                schedulerVC.loadCourses()
            } else {
                prev()
            }
            
        } else {
            
            if self.selectedIndex == SBSchedulerIndex {
                next()
            } else if self.selectedIndex == SBCourseIndex {
                prev()
            }
            
        }
    }
    
    func notifyTimeSlotChange() {
        masterVC.notifyTimeSlotChange()
        
        scheduleCheck()
    }
    
    func notifySelected(lecture: Lecture?) {
        masterVC.notifySelected(lecture: lecture)
    }
    
//    func notifySelectedSemester() {
//        print("notifySelectedSemester")
//        masterVC.notifySelected(semester: self.selectedSemester, is: isScheduling)
//    }
    func notifySelected(semester: Semester) {
        selectedSemester = semester
        if self.selectedIndex == SBSchedulerIndex {
            schedulerVC.loadCourses()
            schedulerVC.isPastSemester = selectedSemester.isEarlier(than: semesterToday)
        } else {
            prev()
        }
    }
    
//    func notifySelectedScheduler() {
//        print("notifySelectedScheduler")
//        masterVC.notifySelected(semester: self.selectedSemester, is: isScheduling)
//    }
    
    func notifyRenamed(lecture: Lecture) {
        if courseVC != nil {
            courseVC.notifyRenamed(lecture: lecture)
        }
    }
}
