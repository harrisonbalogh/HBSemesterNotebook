//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {

    // Mark: IB outlets

    @IBOutlet weak var lectureStack: NSStackView!
    @IBOutlet weak var lectureLedgerStack: NSStackView!
    @IBOutlet weak var lectureListContainer: NSBox!
    // Reference lecture lead constraint to hide/show this container
    private var lectureLeadingConstraint: NSLayoutConstraint!
    
    var lectureCount = 0
    var weekCount = 0
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    private var thisCourse: Course! {
        didSet {
            // Setting thisCourse immediately updates visuals
            if thisCourse != nil {
                // Clear old lecture visuals
                popAllLectures()
                // Populate new lecture visuals
                loadLectures(fromCourse: thisCourse)
            } else {
                                popAllLectures()
                                lectureListIsDisclosed(false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lectureLeadingConstraint = lectureListContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        lectureLeadingConstraint.isActive = true
        
        lectureListIsDisclosed(false)
    }

    // MARK: Load object models ..........................................................................................
    /// Called when a course is pressed in the courseStack. Populate stackViews with the loaded lectures from the selected course
    private func loadLectures(fromCourse course: Course) {
        for case let lecture as Lecture in course.lectures! {
            pushLecture( lecture )
        }
    }
    
    // MARK: Populating stacks ...........................................................................................
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
        let newController = LectureViewController(nibName: "HXLectureView", bundle: nil)!
        self.addChildViewController(newController)
        lectureStack.addArrangedSubview(newController.view)
        newController.initialize(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", withLecture: lecture)
        lectureLedgerStack.addArrangedSubview(HXLectureLedger.instance(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)"))
        lectureCount += 1
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
    func lectureListIsDisclosed(_ visible: Bool) {
        if visible {
            lectureLeadingConstraint.constant = 0
        } else {
            lectureLeadingConstraint.constant = -197
        }
    }
}
