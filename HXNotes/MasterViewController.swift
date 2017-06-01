//
//  MasterViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/24/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Darwin

class MasterViewController: NSViewController {
    
    // MARK: View references
    @IBOutlet weak var container_content: NSView!
    @IBOutlet weak var container_topBar: NSView!
    @IBOutlet weak var container_sideBar: NSView!
    
    // Children controllers
    var sidebarViewController: SidebarViewController!
    // The following 2 controllers fill container_content as is needed
    private var calendarViewController: CalendarViewController!
    private var editorViewController: EditorViewController!
    
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox = HXCourseDragBox.instance()
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    
    var topBarConstraintTop: NSLayoutConstraint!
    var sideBarConstraintLead: NSLayoutConstraint!
    
    // Mark: Object models informed by TimelineViewController
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBarConstraintTop = container_topBar.topAnchor.constraint(equalTo: self.view.topAnchor)
        topBarConstraintTop.isActive = true
        
        sideBarConstraintLead = container_sideBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        sideBarConstraintLead.isActive = true
        
        courseDragBox.translatesAutoresizingMaskIntoConstraints = false
        
        topBarConstraintTop.constant = -container_topBar.frame.height
    }
    override func viewDidAppear() {
        for case let sidebarVC as SidebarViewController in self.childViewControllers {
            self.sidebarViewController = sidebarVC
            self.sidebarViewController.masterViewController = self
        }
    }
    
    // MARK: Login Logic ....................................................................................
    /// Default UI setup when app loads
    // MOVING OUT OF MASTER VIEW CONTROLLER
//    private func checkWhatCourses() {
//        print("Running the open check.")
//        // Default to current year
//        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
//        selectYear(yr)
//        timelineViewController.selectYear(yr)
//        print("    Year is \(yr)")
//        // Default to current semester by assuming Fall: [July, December]
//        let month = NSCalendar.current.component(.month, from: NSDate() as Date)
//        print("    Month is \(month)")
//        if month >= 7 && month <= 12 {
//            timelineViewController.action_selectFall(self)
//        } else {
//            timelineViewController.action_selectSpring(self)
//        }
//        // Find lecture happening in current time
//        let dayOfWeek = NSCalendar.current.component(.weekday, from: NSDate() as Date)
//        print("    Day of week is \(dayOfWeek)")
//        if dayOfWeek == 1 || dayOfWeek == 7 {
//            // Stop here if opening app on weekend since we assume no classes are on weekend.
//            print("        Dumping here. It's the weekend!")
//            return
//        }
//        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
//        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
//        print("    Hour is \(hour)")
//        print("    Minute is \(minute)")
//        // Get all courses in this semester
//        for case let course as Course in semesterSelected.courses! {
//            for case let timeSlot as TimeSlot in course.timeSlots! {
//                if timeSlot.day + 2 == Int16(dayOfWeek) {
//                    // timeSlot.day has range [2,6] and dayOfWeek is [1,7]
//                    if timeSlot.hour == Int16(hour - 8) {
//                        // Check if in the hour of a course
//                    } else if timeSlot.hour - 1 + 8 == Int16(hour) && minute >= 55 {
//                        // Check if its close enough before the start of a lecture
//                        
//                    }
//                }
//            }
//        }
//    }
//    
//    private func checkWhatCourses(month: Int, year: Int, dayOfWeek: Int, hour: Int, minute: Int) {
//        print("Running the open check.")
//        print("    Year is \(year)")
//        selectYear(year)
//        timelineViewController.selectYear(year)
//        if month >= 7 && month <= 12 {
//            timelineViewController.action_selectFall(self)
//        } else {
//            timelineViewController.action_selectSpring(self)
//        }
//        print("    Month is \(month)")
//        // Find lecture happening in current time
//        print("    Day of week is \(dayOfWeek)")
//        if dayOfWeek == 1 || dayOfWeek == 7 {
//            // Stop here if opening app on weekend since we assume no classes are on weekend.
//            print("        Dumping here. It's the weekend!")
//            return
//        }
//        print("    Hour is \(hour)")
//        print("    Minute is \(minute)")
//        // Get all courses in this semester
//        for case let course as Course in semesterSelected.courses! {
//            for case let timeSlot as TimeSlot in course.timeSlots! {
//                if timeSlot.day + 2 == Int16(dayOfWeek) {
//                    print("        \(course.title!) is today.")
//                    // timeSlot.day has range [2,6] and dayOfWeek is [1,7]
//                    if timeSlot.hour == Int16(hour - 8) {
//                        print("            Class is happening now. \(hour):00")
//                        courseViewController.select(course: course)
//                        editorViewController.action_addLecture(self)
//                        break
//                        // Check if in the hour of a course
//                    } else if timeSlot.hour - 1 + 8 == Int16(hour) && minute >= 55 {
//                        print("            Class is about to happen. \(60 - minute) minutes 'till.")
//                        courseViewController.select(course: course)
//                        editorViewController.action_addLecture(self)
//                        break
//                        // Check if its close enough before the start of a lecture
//                    } else {
//                        print("            No class at the moment.")
//                    }
//                }
//            }
//        }
//    }
    
    // MARK: Handle content container changes ................................................................    
    private func pushCalendar(semester: Semester) {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "CalendarID") as? CalendarViewController {
            calendarViewController = newController
            self.addChildViewController(calendarViewController)
            container_content.addSubview(calendarViewController.view)
            calendarViewController.masterViewController = self
            calendarViewController.view.frame = container_content.bounds
            calendarViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            calendarViewController.initialize(with: semester)
        }
    }
    private func pushEditor() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "EditorID") as? EditorViewController {
            editorViewController = newController
            self.addChildViewController(editorViewController)
            editorViewController.masterViewController = self
            container_content.addSubview(editorViewController.view)
            editorViewController.view.frame = container_content.bounds
            editorViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        }
    }
    private func popCalendar() {
        if calendarViewController != nil {
            if calendarViewController.view.superview != nil {
                calendarViewController.view.removeFromSuperview()
                calendarViewController.removeFromParentViewController()
                calendarViewController = nil
            }
        }
        topBarShown(false)
    }
    private func popEditor() {
        if editorViewController != nil {
            if editorViewController.view.superview != nil {
                editorViewController.view.removeFromSuperview()
                editorViewController.removeFromParentViewController()
                editorViewController = nil
            }
        }
    }
    
    // MARK: Container Disclosure Functionality
    /// Reveal or hide the top bar container.
    func topBarShown(_ visible: Bool) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        NSAnimationContext.current().duration = 0.25
        if visible {
            topBarConstraintTop.animator().constant = 0
        } else {
            topBarConstraintTop.animator().constant = -container_topBar.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    
    func sideBarShown(_ visible: Bool) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        NSAnimationContext.current().duration = 0.25
        if visible {
            sideBarConstraintLead.animator().constant = 0
        } else {
            sideBarConstraintLead.animator().constant = -container_sideBar.frame.width
        }
        NSAnimationContext.endGrouping()
    }
    
    // MARK: Notifiers - Child Controllers ............................................................
    /// Notify MasterViewController that a course has been selected or deselected.
    /// Passes on course selection to EditorViewController
    func notifyCourseSelection(course: Course?) {
        editorViewController.selectedCourse = course
        if course != nil {
            topBarShown(true)
        } else {
            topBarShown(false)
        }
    }
    /// Notfy MasterViewController that a course has been removed.
    /// Currently used to remove time slot grid spaces in Calendar.
    func notifyCourseDeletion(named course: String) {
        calendarViewController.clearTimeSlots(named: course)
        calendarViewController.evaluateEmptyVisuals()
    }
    /// Notify calendar of a course being added so it may display proper visuals.
    func notifyCourseAddition() {
        if calendarViewController != nil {
            calendarViewController.evaluateEmptyVisuals()
        }
    }
    /// Notify MasterViewController that a course has been renamed.
    /// Currently used to reload the label titles on time slots in the Calendar.
    func notifyCourseRename(from oldName: String) {
        calendarViewController.reloadTimeslotTitles(named: oldName)
    }
    ///
    func notifyCourseDragStart(editBox: HXCourseEditBox, to loc: NSPoint) {
        // Update drag box visuals to match course being dragged
        courseDragBox.updateWithCourse(editBox.course)
        // Add drag box back to the superview
        self.view.addSubview(courseDragBox)
        // Try and move these to dragBox initialize in viewDidLoad()
        courseDragBox.removeConstraints(courseDragBox.constraints)
        dragBoxConstraintLead = courseDragBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: loc.x - editBox.boxDrag.frame.origin.x - editBox.boxDrag.frame.width/2)
        dragBoxConstraintTop = courseDragBox.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.view.bounds.height - loc.y - editBox.boxDrag.frame.origin.y - editBox.boxDrag.frame.height/2)
        dragBoxConstraintLead.isActive = true
        dragBoxConstraintTop.isActive = true
        courseDragBox.widthAnchor.constraint(equalToConstant: editBox.bounds.width + 2).isActive = true
        courseDragBox.heightAnchor.constraint(equalToConstant: editBox.bounds.height + 1).isActive = true
    }
    ///
    func notifyCourseDragMoved(editBox: HXCourseEditBox, to loc: NSPoint) {
        dragBoxConstraintLead.constant = loc.x - editBox.boxDrag.frame.origin.x - editBox.boxDrag.frame.width/2
        dragBoxConstraintTop.constant = self.view.bounds.height - loc.y - editBox.boxDrag.frame.origin.y - editBox.boxDrag.frame.height/2
        calendarViewController.drag()
    }
    ///
    func notifyCourseDragEnd(course: Course, at loc: NSPoint) {
        self.courseDragBox.removeFromSuperview()
        calendarViewController.drop(course: course, at: loc)
    }
    ///
    func notifyLectureFocus(is lecture: Lecture?) {
        sidebarViewController.focus(lecture: lecture)
    }
    /// 
    func notifyLectureSelection(lecture: String) {
        editorViewController.scrollToLecture(lecture)
    }
    ///
    func notifySemesterEditing(semester: Semester) {
        if calendarViewController == nil {
            // Only push a new calendar if the editor is showing.
            popEditor()
            pushCalendar(semester: semester)
        } else {
            calendarViewController.initialize(with: semester)
        }
    }
    ///
    func notifySemesterViewing(semester: Semester) {
        if editorViewController == nil {
            // Only push a new editor if the calendar is showing.
            popCalendar()
            pushEditor()
        } else {
            editorViewController.selectedCourse = nil
        }
    }
    /// 
    func notifyTimeSlotAddition() {
        sidebarViewController.notifyTimeSlotAdded()
    }
    ///
    func notifyTimeSlotDeletion() {
        sidebarViewController.notifyTimeSlotRemoved()
    }
}
