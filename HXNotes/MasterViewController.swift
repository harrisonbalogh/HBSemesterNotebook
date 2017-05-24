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
    @IBOutlet weak var container_timeline: NSView!
    // Reference timeline top constraint to hide/show this container
    var timelineTopConstraint: NSLayoutConstraint!
    // Children controllers
    var timelineViewController: TimelineViewController!
    var courseViewController: CourseViewController!
    // The following 2 controllers fill container_content as is needed
    var calendarViewController: CalendarViewController!
    var editorViewController: EditorViewController!
    
    // MARK: Drag Box for adding time slots for course
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox!
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    
    // Mark: Object models informed by TimelineViewController
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    var yearSelected: Year!
    var semesterSelected: Semester! {
        didSet {
            // Clear all other content displayed
            popCalendar()
            popEditor()
            // Check if this semester has courses entered
            if semesterSelected.courses!.count > 0 {
                pushEditor()
                courseViewController.toggleEditsButtons.isEnabled = true
            } else {
                pushCalendar()
                // Prevent user from going into lecture mode if there are no courses yet.
                courseViewController.toggleEditsButtons.isEnabled = false
            }
        }
    }
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()

        timelineTopConstraint = container_timeline.topAnchor.constraint(equalTo: self.view.topAnchor)
        timelineTopConstraint.isActive = true
        
        // Create course dragged box
        self.courseDragBox = HXCourseDragBox.instance()
    }
    override func viewDidAppear() {
        for case let timelineVC as TimelineViewController in self.childViewControllers {
            self.timelineViewController = timelineVC
        }
        for case let courseVC as CourseViewController in self.childViewControllers {
            self.courseViewController = courseVC
            courseViewController.masterViewController = self
        }
        checkWhatCourses()
    }
    
    // MARK: Login Logic ....................................................................................
    /// Default UI setup when app loads
    private func checkWhatCourses() {
        // Default to current year
        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
        selectYear(yr)
        timelineViewController.selectYear(yr)
        // Default to current semester by assuming Fall: [July, December]
        let month = NSCalendar.current.component(.month, from: NSDate() as Date)
        if month >= 7 && month <= 12 {
            timelineViewController.action_selectFall(self)
        } else {
            timelineViewController.action_selectSpring(self)
        }
        // Find lecture happening in current time
        let dayOfWeek = NSCalendar.current.component(.weekday, from: NSDate() as Date)
        if dayOfWeek == 1 || dayOfWeek == 7 {
            // Stop here if opening app on weekend since we assume no classes are on weekend.
            return
        }
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        // Get all courses in this semester
        for case let course as Course in semesterSelected.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if timeSlot.day + 2 == Int16(dayOfWeek) {
                    // timeSlot.day has range [2,6] and dayOfWeek is [1,7]
                    if timeSlot.hour == Int16(hour - 8) {
                        // Check if in the hour of a course
                        
                    } else if timeSlot.hour - 1 + 8 == Int16(hour) && minute >= 55 {
                        // Check if its close enough before the start of a lecture
                        
                    }
                }
            }
        }
    }
    
    // MARK: Handle content container changes ................................................................
     /// Notifies MasterViewController from TimelineViewController that user has landed on a year.
    func selectYear(_ year: Int) {
        // Try fetching this year in persistent store
        let yearFetch = NSFetchRequest<Year>(entityName: "Year")
        do {
            let years = try appDelegate.managedObjectContext.fetch(yearFetch) as [Year]
            if let foundYear = years.filter({$0.year == Int16(year)}).first {
                // This year already present in store so load
                yearSelected = foundYear
            } else {
                // Create year since it wasn't found
                let newYear = NSEntityDescription.insertNewObject(forEntityName: "Year", into: appDelegate.managedObjectContext) as! Year
                newYear.year = Int16(year)
                yearSelected = newYear
            }
        } catch { fatalError("Failed to fetch years: \(error)") }
    }
    
    /// Notifies MasterViewController from TimelineViewCotnroler that user has selected a semester.
    func selectSemester(_ semester: String) {
        // Try finding this semester in year selected
        for case let sem as Semester in yearSelected.semesters! {
            if sem.title! == semester {
                semesterSelected = sem
                courseViewController.thisSemester = semesterSelected
                return;
            }
        }
        // Create semester since it wasn't found
        semesterSelected = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
        semesterSelected.title = semester
        semesterSelected.year = yearSelected
        courseViewController.thisSemester = semesterSelected
    }
    
    func notifyCalendarOfCourseListChange() {
        calendarViewController.evaluateEmptyVisuals()
    }
    
    func updateCourse(from oldName: String) {
        calendarViewController.reloadTimeslotTitles(named: oldName)
    }
    
    func pushCalendar() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "CalendarID") as? CalendarViewController {
            calendarViewController = newController
            self.addChildViewController(calendarViewController)
            container_content.addSubview(calendarViewController.view)
            calendarViewController.masterViewController = self
            calendarViewController.view.frame = container_content.bounds
            calendarViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            calendarViewController.initialize(withSemester: semesterSelected)
        }
        courseViewController.toggleEditsButtons.state = NSOnState
    }
    func pushEditor() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "EditorID") as? EditorViewController {
            editorViewController = newController
            self.addChildViewController(editorViewController)
            container_content.addSubview(editorViewController.view)
            editorViewController.view.frame = container_content.bounds
            editorViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        }
        courseViewController.toggleEditsButtons.state = NSOffState
    }
    func popCalendar() {
        if calendarViewController != nil {
            if calendarViewController.view.superview != nil {
                calendarViewController.view.removeFromSuperview()
                calendarViewController.removeFromParentViewController()
            }
        }
    }
    func popEditor() {
        if editorViewController != nil {
            if editorViewController.view.superview != nil {
                editorViewController.view.removeFromSuperview()
                editorViewController.removeFromParentViewController()
            }
        }
    }
    
    /// Show or hide the timeline pull out drawer.
    func discloseTimeline(_ state: Int) {
        if state == NSOnState {
            // Animate showing the timeline
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            NSAnimationContext.current().duration = 0.2
            timelineTopConstraint.animator().constant = 0
            NSAnimationContext.endGrouping()
        } else if state == NSOffState {
            // Animate hiding the timeline
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            NSAnimationContext.current().duration = 0.2
            timelineTopConstraint.animator().constant = -105
            NSAnimationContext.endGrouping()
        }
    }
    
    /// Handles toggle between course editing in the calendar versus editing lectures.
    func isEditing(_ editing: Bool) {
        popCalendar()
        popEditor()
        if editing {
            pushCalendar()
        } else {
            pushEditor()
        }
    }
    /// Tells lecture content to display a specific course or clear it if set to nil
    func select(course: Course?) {
        editorViewController.thisCourse = course
    }
    
    // MARK: Dragging functionality for calendar
    /// Initializes drag box from the calendar view
    func startDragging(course: Course) {
        // Update drag box visuals to match course being dragged
        courseDragBox.updateWithCourse(course)
        // Add drag box back to the superview
        self.view.addSubview(courseDragBox)
        // Try and move these to dragBox initialize in viewDidLoad()
        dragBoxConstraintLead = courseDragBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -1000)
        dragBoxConstraintTop = courseDragBox.topAnchor.constraint(equalTo: self.view.topAnchor, constant: -1000)
        dragBoxConstraintLead.isActive = true
        dragBoxConstraintTop.isActive = true
    }
    /// Notify the drag box of movement
    func moveDragging(course: Course, to loc: NSPoint) {
        dragBoxConstraintLead.constant = loc.x - courseDragBox.bounds.width/2
        dragBoxConstraintTop.constant = self.view.bounds.height - loc.y - 5
        
        calendarViewController.drag()
    }
    /// Remove the drag box from master view
    func stopDragging(course: Course, at loc: NSPoint) {
        self.courseDragBox.removeFromSuperview()
        calendarViewController.drop(course: course, at: loc)
    }
    func removeCourse(named course: String) {
        calendarViewController.clearTimeSlots(named: course)
    }
}
