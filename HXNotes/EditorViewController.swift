//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {
    
    // CHANGE THE GRID STACK VIEWS
    // TO TABLE STACK VIEWS
    // Only use stackviews when wanting to resize things inside the

    // Mark: IB outlets
    @IBOutlet weak var lectureStack: NSStackView!
    @IBOutlet weak var courseStack: NSStackView!
    @IBOutlet weak var lectureLedgerStack: NSStackView!
    @IBOutlet weak var lectureListContainer: NSBox!
    @IBOutlet weak var lectureListYrSemLabel: NSTextField!
    @IBOutlet weak var lectureListCourseLabel: NSTextField!
    // Reference lecture lead constraint to hide/show this container
    private var lectureLeadingConstraint: NSLayoutConstraint!
    
    // MARK: Object models and logic
    private var thisSemester: Semester! {
        didSet {
            // Clear old course visuals
            popAllCourses()
            // Populate new lecture visuals
            loadCourses(fromSemester: thisSemester)
        }
    }
    // Setting thisCourse immediately updates visuals
    private var thisCourse: Course! {
        didSet {
            // Clear old lecture visuals
            popAllLectures()
            // Populate new lecture visuals
            loadLectures(fromCourse: thisCourse)
            // Reset other lecture buttons to not be bold in course stack
            for c in courseStack.arrangedSubviews {
                if let courseButton = c as? HXCourseBox {
                    if courseButton.buttonTitle.title != thisCourse.title! && courseButton.buttonTitle.title != "Edit Courses" {
                        courseButton.deselect()
                    }
                }
            }
        }
    }
    var lectureCount = 0
    var weekCount = 0
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lectureLeadingConstraint = lectureListContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        lectureLeadingConstraint.isActive = true
        
        discloseLectureList()
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
    /// Called when a course is pressed in the courseStack. Populate stackViews with the loaded lectures from the selected course
    private func loadLectures(fromCourse course: Course) {
        for case let lecture as Lecture in course.lectures! {
            pushLecture( lecture )
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
                lectureLeadingConstraint.constant = 0
                lectureListYrSemLabel.stringValue = "\(thisSemester.title!.capitalized) \(thisSemester.year!.year)"
                lectureListCourseLabel.stringValue = course.title!
                break
            }
        }
    }
    /// Creates a Lecture object for the currently selected course, and pushes an HXLectureLedger plus HXLectureView
    /// to their appropriate stacks. Will also add an HXWeekDividerBox to the lectureLedgerStack if necessary.
    private func addLecture() {
        
        pushLecture( newLecture() )
        
    }
    /// Handles purely the visual aspect of lectures. Populates lectureLedgerStack and lectureStack.
    private func pushLecture(_ lecture: Lecture) {
        if Int(lectureCount % 2) == 0 {
            lectureLedgerStack.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        }
        // Update Views
//        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        let newController = LectureViewController(nibName: "HXLectureView", bundle: nil)!
        self.addChildViewController(newController)
        lectureStack.addArrangedSubview(newController.view)
        newController.initialize(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", withLecture: lecture)
        //        newController.view.widthAnchor.constraint(equalTo: lectureLedgerStack.widthAnchor).isActive = true
////        if let newController = strybrd.instantiateController(withIdentifier: "LectureControllerID") as? LectureViewController {
//
//        }
        lectureLedgerStack.addArrangedSubview(HXLectureLedger.instance(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)"))
        lectureCount += 1
    }
    /// Handles purely the visual aspect of courses. Populates courseStack.
    private func pushCourse(_ course: Course) {
        let newBox = HXCourseBox.instance(withTitle: course.title!, withParent: self)
        courseStack.insertArrangedSubview(newBox!, at: courseStack.subviews.count - 1)
    }
    /// Handles purely the visual aspect of lectures. Resets lectureLedgerStack, lectureStack, lectureCount, and weekCount
    private func popAllLectures() {
        for v in lectureLedgerStack.arrangedSubviews {
            v.removeFromSuperview()
        }
        for v in lectureStack.arrangedSubviews {
            v.removeFromSuperview()
        }
        lectureCount = 0
        weekCount = 0
    }
    /// Handles purely the visual aspect of courses. Reset the courseStack
    private func popAllCourses() {
        for case let v as HXCourseBox in courseStack.arrangedSubviews {
            v.removeFromSuperview()
        }
    }
    
    // MARK: Instance object models .....................................................................................
    /// Doesn't require parameters. Accesses local lectureCount, weekCount, thisCourse, and current NSCalendar date
    private func newLecture() -> Lecture {
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        newLecture.course = thisCourse
        newLecture.lecture = Int16(lectureCount + 1)
        newLecture.week = Int16(weekCount + 1)
        newLecture.day = Int16(NSCalendar.current.component(.day, from: NSDate() as Date))
        newLecture.month = Int16(NSCalendar.current.component(.month, from: NSDate() as Date))
        newLecture.year = Int16(NSCalendar.current.component(.year, from: NSDate() as Date))
        return newLecture
    }
    
    // MARK: TEMP
    /// Should not be able to simply add lectures this way
    @IBAction func action_addLecture(_ sender: Any) {
        addLecture()
    }
    func discloseLectureList() {
        if lectureLeadingConstraint.constant != 0 {
            lectureLeadingConstraint.constant = 0
        } else {
            lectureLeadingConstraint.constant = -197
        }
    }
}
