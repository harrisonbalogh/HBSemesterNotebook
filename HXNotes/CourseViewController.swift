//
//  CourseViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/16/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseViewController: NSViewController {
    
    // Mark: View references
    @IBOutlet weak var lectureListYrSemLabel: NSTextField!
    @IBOutlet weak var toggleEditsButtons: NSButton!
    @IBOutlet weak var courseStack: NSStackView!
    
    // MARK: Object models and logic
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    var thisSemester: Semester! {
        didSet {
            // Clear old course visuals
            popAllCourses()
            // Get courses from this semester
            if thisSemester.courses!.count > 0 {
                loadCourses(fromSemester: thisSemester)
                masterViewController.notifySemesterViewing(semester: thisSemester)
                toggleEditsButtons.isEnabled = true
            } else {
                loadEditableCourses(fromSemester: thisSemester)
                masterViewController.notifySemesterEditing(semester: thisSemester)
                toggleEditsButtons.isEnabled = false
            }
            lectureListYrSemLabel.stringValue = "\(thisSemester.title!.capitalized) \(thisSemester.year!.year)"
        }
    }
    private var thisCourse: Course! {
        didSet {
            // Notify masterViewController that a course was selected
            masterViewController.notifyCourseSelection(course: thisCourse)
            // Deselect all other buttons
            for case let courseButton as HXCourseBox in courseStack.arrangedSubviews {
                if thisCourse == nil {
                    courseButton.deselect()
                } else if courseButton.buttonTitle.title != thisCourse.title {
                    courseButton.deselect()
                }
            }
        }
    }
    var masterViewController: MasterViewController!
    // MARK: Dragging editable course references
    // Reference to index of course being dragged, nil when not dragging
    var dragCourse: Course!
    
    // MARK: Color handling for editing courses
    // Colors used to give course boxes unique colors
    let COLORS_ORDERED = [
        NSColor.init(red: 88/255, green: 205/255, blue: 189/255, alpha: 1),
        NSColor.init(red: 114/255, green: 205/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 89/255, green: 138/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 204/255, green: 88/255, blue: 127/255, alpha: 1),
        NSColor.init(red: 205/255, green: 142/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 161/255, green: 88/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 54/255, green: 255/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 0/255, green: 240/255, blue: 255/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 210/255, alpha: 1)]
    // Track which colors have been used,
    // in case user removes a course box in the middle of stack
    var colorAvailability = [Int: Bool]()
    /// Return the first color available, or gray if all colors taken
    func nextColorAvailable() -> NSColor {
        for x in 0..<COLORS_ORDERED.count {
            if colorAvailability[x] == true {
                colorAvailability[x] = false
                return COLORS_ORDERED[x]
            }
        }
        return NSColor.gray
    }
    /// Mark a color as in-use
    func useColor(color: NSColor) {
        for i in 0..<COLORS_ORDERED.count {
            if Int(COLORS_ORDERED[i].redComponent * 1000) == Int(color.redComponent * 1000) &&
                Int(COLORS_ORDERED[i].greenComponent * 1000) == Int(color.greenComponent * 1000) &&
                Int(COLORS_ORDERED[i].blueComponent * 1000) == Int(color.blueComponent * 1000) {
                colorAvailability[i] = false
            }
        }
    }
    /// Release a color to be usuable again
    func releaseColor(color: NSColor) {
        for i in 0..<COLORS_ORDERED.count {
            if Int(COLORS_ORDERED[i].redComponent * 1000) == Int(color.redComponent * 1000) &&
                Int(COLORS_ORDERED[i].greenComponent * 1000) == Int(color.greenComponent * 1000) &&
                Int(COLORS_ORDERED[i].blueComponent * 1000) == Int(color.blueComponent * 1000) {
                colorAvailability[i] = true
            }
        }
    }
    /// Return the first number available in the course for untitled courses.
    func nextNumberAvailable() -> Int {
        // Find next available number for naming Course
        var nextCourseNumber = 1
        var seekingNumber = true
        repeat {
            if (retrieveCourse(withName: "Untitled \(nextCourseNumber)")) == nil {
                seekingNumber = false
            } else {
                nextCourseNumber += 1
            }
        } while(seekingNumber)
        return nextCourseNumber
    }
    
    // MARK: Initialize course viewController ...........................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize colorAvailability dictionary
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
    }
    
    // MARK: Load object models ..........................................................................................
    /// Populates course stack. Must be called after thisSemester is set.
    private func loadCourses(fromSemester semester: Semester) {
        for case let course as Course in semester.courses! {
            pushCourse( course )
        }
    }
    /// Populates an editable course stack. Must be called after thisSemester is set.
    private func loadEditableCourses(fromSemester semester: Semester) {
        let newAddCourse = NSButton.init(title: "New Course", target: self, action: #selector(CourseViewController.action_addCourseButton))
        newAddCourse.isBordered = false
        newAddCourse.font = NSFont.boldSystemFont(ofSize: 12)
        courseStack.addArrangedSubview(newAddCourse)
        for case let course as Course in semester.courses! {
            pushEditableCourse( course )
        }
    }
    // MARK: Populating stacks ...........................................................................................
    /// Change selected course in course view. Nil value is appropriate when clearing selection. 
    /// SEE thisCourse didSet method for more details.
    func select(course: Course?) {
        self.thisCourse = course
    }
    /// Creates and returns a new persistent Course object.
    private func newCourse() -> Course {
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: appDelegate.managedObjectContext) as! Course
        let assignedColor = nextColorAvailable()
        newCourse.colorRed = Float(assignedColor.redComponent)
        newCourse.colorGreen = Float(assignedColor.greenComponent)
        newCourse.colorBlue = Float(assignedColor.blueComponent)
        newCourse.title = "Untitled \(nextNumberAvailable())"
        newCourse.semester = thisSemester
        return newCourse
    }
    /// Add a course model and visual to courseStack
    private func addCourse() {
        // Creates new course data model and puts new view in courseStack
        pushCourse( newCourse() )
    }
    /// Add a course model and visual to courseStack
    private func addEditableCourse() {
        // Creates new course data model and puts new view in courseStack
        pushEditableCourse( newCourse() )
        // Allow user to access lecture view when there are courses added
        toggleEditsButtons.isEnabled = true
    }
    /// Removes all information associated with a course object. Model and Views
    private func removeCourse(_ course: HXCourseEditBox) {
        // Remove course from courseStack, reset grid spaces of timeSlots, delete data model
        popCourse( course )
        masterViewController.notifyCourseDeletion(named: course.labelCourse.stringValue)
//        popTimeSlots(forCourse: retrieveCourse(withName: course.labelCourse.stringValue) )
        appDelegate.managedObjectContext.delete( retrieveCourse(withName: course.labelCourse.stringValue) )
        appDelegate.saveAction(self)
        // Prevent user from accessing lecture view if there are no courses
        if thisSemester.courses!.count == 0 {
            toggleEditsButtons.isEnabled = false
        }
//        self.removeCourse(course)
        
    }
    /// Handles purely the visual aspect of courses. Populates courseStack.
    private func pushCourse(_ course: Course) {
        let newBox = HXCourseBox.instance(with: course, owner: self)
        courseStack.addArrangedSubview(newBox!)
        let theColor = NSColor(red: CGFloat(course.colorRed), green: CGFloat(course.colorGreen), blue: CGFloat(course.colorBlue), alpha: 1)
        useColor(color: theColor)
    }
    private func popCourse(_ course: HXCourseEditBox) {
        course.removeFromSuperview()
        releaseColor(color: course.boxDrag.fillColor)
    }

    /// Handles purely the visual aspect of editable courses. Populates courseStack.
    private func pushEditableCourse(_ course: Course) {
        let courseColor = NSColor(red: CGFloat(course.colorRed), green: CGFloat(course.colorGreen), blue: CGFloat(course.colorBlue), alpha: 1)
        useColor(color: courseColor)
        let newBox = HXCourseEditBox.instance(with: course, withCourseIndex: courseStack.subviews.count-1, withParent: self)
        courseStack.insertArrangedSubview(newBox!, at: courseStack.subviews.count - 1)
    }
    
    /// Handles purely the visual aspect of courses. Reset the courseStack
    private func popAllCourses() {
        for v in courseStack.arrangedSubviews {
            v.removeFromSuperview()
        }
        // Reset colors for usage on next editable courses
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
    }
    /// Receive action from toggleEditsButton to toggle course editing modes.
    @IBAction func action_toggleEdits(_ sender: Any) {
        if toggleEditsButtons.state == NSOnState {
            isEditing(true)
            masterViewController.notifySemesterEditing(semester: thisSemester)
        } else {
            isEditing(false)
            masterViewController.notifySemesterViewing(semester: thisSemester)
        }
    }
    func action_addCourseButton() {
        addEditableCourse()
    }
    /// Button in HXCourseEditBox - on MouseDown
    internal func action_removeCourseButton(course: HXCourseEditBox) {
        self.removeCourse(course)
    }
    /// CourseLabel in HXCourseEditBox - on Enter
    internal func action_courseTextField(_ courseBox: HXCourseEditBox) {
        // Update Model:
        if let fetchedCourse = retrieveCourse(withName: courseBox.oldName) {
            fetchedCourse.title = courseBox.labelCourse.stringValue
            (self.parent! as! MasterViewController).notifyCourseRename(from: courseBox.oldName)
        }
        courseBox.oldName = courseBox.labelCourse.stringValue
    }
    internal func retrieveCourse(withName: String) -> Course! {
        for case let course as Course in thisSemester.courses! {
            if course.title! == withName {
                return course
            }
        }
        return nil
    }
    /// Setting this reloads all courses in this semester based on if the user is
    /// editing the courses in the calendar or view/writing lectures.
    func isEditing(_ editing: Bool) {
        popAllCourses()
        if editing {
            loadEditableCourses(fromSemester: thisSemester)
            toggleEditsButtons.state = NSOnState
        } else {
            loadCourses(fromSemester: thisSemester)
            toggleEditsButtons.state = NSOffState
        }
    }
    
    // MARK: Dragging editable courses
    /// HXCourseEditBox - Mouse Up: Stop dragging a course to a time slot
    func mouseUp_courseBox(for course: Course, at loc: NSPoint) {
        // Ensure a course was being dragged
        if self.dragCourse != nil {
            // Remove drag box from superview
            masterViewController.stopDragging(course: course, at: loc)
            self.dragCourse = nil
        }
    }
    /// HXCourseEditBox - Mouse Drag: Drag a course to a time slot
    func mouseDrag_courseBox(with course: Course, to loc: NSPoint) {
        if self.dragCourse == nil {
            self.dragCourse = course
            masterViewController.startDragging(course: course)
        } else {
            masterViewController.moveDragging(course: course, to: loc)
        }
    }
}
