//
//  CourseViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/16/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseViewController: NSViewController {

    
    
    @IBOutlet weak var lectureListYrSemLabel: NSTextField!
    @IBOutlet weak var toggleEditsButtons: NSButton!
    @IBOutlet weak var courseStack: NSStackView!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // MARK: Object models and logic
    var thisSemester: Semester! {
        didSet {
            // Clear old course visuals
            popAllCourses()
            // Get courses from this semester
            if thisSemester.courses!.count > 0 {
                loadCourses(fromSemester: thisSemester)
            } else {
                loadEditableCourses(fromSemester: thisSemester)
            }
            
            lectureListYrSemLabel.stringValue = "\(thisSemester.title!.capitalized) \(thisSemester.year!.year)"
        }
    }
    private var thisCourse: Course! {
        didSet {
            // Setting thisCourse immediately updates visuals
            if thisCourse != nil {
                // Clear old lecture visuals
//                popAllLectures()
                // Populate new lecture visuals
//                loadLectures(fromCourse: thisCourse)
                // Reset other lecture buttons to not be bold in course stack
                for case let courseButton as HXCourseBox in courseStack.arrangedSubviews {
                    if courseButton.buttonTitle.title != thisCourse.title! {
                        courseButton.deselect()
                    }
                }
            } else {
//                popAllLectures()
//                lectureListIsDisclosed(false)
            }
        }
    }
    
    // MARK: Color vars
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
        for x in 0..<colorAvailability.count {
            if colorAvailability[x] == true {
                colorAvailability[x] = false
                return COLORS_ORDERED[x]
            }
        }
        return NSColor.gray
    }
    /// Release a color to be usuable again
    func releaseColor(color: NSColor) {
        for i in 0..<COLORS_ORDERED.count {
            if COLORS_ORDERED[i] == color {
                colorAvailability[i] = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize colorAvailability dictionary
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
    }
    func initialize(withSemester sem: Semester) {
        self.thisSemester = sem
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
    /// Populates the lecture stacks with data from the course with the given title.
    func selectCourse(withTitle: String) {
        // Find the course with the given title and update thisCourse
        for case let course as Course in thisSemester.courses! {
            if course.title == withTitle {
                // Setting thisCourse calls visual updates and loads lectures
                self.thisCourse = course
//                lectureListIsDisclosed(true)
                break
            }
        }
    }
    /// Clears the selected course. NYI: Shows overview of all courses in columns.
    func clearSelectedCourse() {
        self.thisCourse = nil
    }
    /// Creates and returns a new persistent Course object.
    private func newCourse() -> Course {
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: appDelegate.managedObjectContext) as! Course
        
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
        
        newCourse.title = "Untitled \(nextCourseNumber)"
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
    }
    /// Removes all information associated with a course object. Model and Views
    private func removeCourse(_ course: HXCourseEditBox) {
        // Remove course from courseStack, reset grid spaces of timeSlots, delete data model
        popCourse( course )
//        popTimeSlots(forCourse: retrieveCourse(withName: course.labelCourse.stringValue) )
        appDelegate.managedObjectContext.delete( retrieveCourse(withName: course.labelCourse.stringValue) )
    }
    /// Handles purely the visual aspect of courses. Populates courseStack.
    private func pushCourse(_ course: Course) {
        let newBox = HXCourseBox.instance(withTitle: course.title!, withParent: self)
        courseStack.addArrangedSubview(newBox!)
    }
    private func popCourse(_ course: HXCourseEditBox) {
        course.removeFromSuperview()
        releaseColor(color: course.boxDrag.fillColor)
    }

    /// Handles purely the visual aspect of editable courses. Populates courseStack.
    private func pushEditableCourse(_ course: Course) {
        let newBox = HXCourseEditBox.instance(withTitle: course.title!, withCourseIndex: courseStack.subviews.count-1, withColor: nextColorAvailable(), withParent: self)
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
    
    @IBAction func action_toggleEdits(_ sender: Any) {
        if let thisParent = self.parent! as? MasterViewController {
            if toggleEditsButtons.state == NSOnState {
                isEditing(true)
                thisParent.popEditor()
                thisParent.pushCalendar()
            } else {
                isEditing(false)
                thisParent.popCalendar()
                thisParent.pushEditor()
            }
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
//            let fetchRequest = NSFetchRequest<TimeSlot>(entityName: "TimeSlot")
//            do {
//                let fetch = try appDelegate.managedObjectContext.fetch(fetchRequest) as [TimeSlot]
//                let found = fetch.filter({$0.course == fetchedCourse})
//                for t in found {
//                    gridBoxes[Int(t.day)][Int(t.hour)].labelTitle.stringValue = courseBox.labelCourse.stringValue
//                }
//            } catch { fatalError("Failed to fetch: \(error)") }
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
    func isEditing(_ editing: Bool) {
        popAllCourses()
        if editing {
            loadEditableCourses(fromSemester: thisSemester)
        } else {
            loadCourses(fromSemester: thisSemester)
        }
    }
}
