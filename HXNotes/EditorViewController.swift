//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {

    @IBOutlet weak var courseStack: NSStackView!
    @IBOutlet weak var lectureStack: NSStackView!
    @IBOutlet weak var lectureListContainer: NSBox!
    @IBOutlet weak var lectureListYrSemLabel: NSTextField!
    @IBOutlet weak var lectureListCourseLabel: NSTextField!
    
    var lectureCount = 0
    var weekCount = 0
    
    // Reference timeline top constraint to hide/show this container
    var timeLeadingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLeadingConstraint = lectureListContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        timeLeadingConstraint.isActive = true
        
        discloseLectureList()
    }
    
    // MARK: Object models ...................................................
    var thisSemester: Semester!
    var thisYear: Year!
    var thisCourse: Course!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    /// Must be called after thisSemester and thisYear are set. Populates course stack
    func loadCourses() {
        
        for case let course as Course in thisSemester.courses! {
            // Update Views: Load Course Add Template from nib
            var theObjects: NSArray = []
            Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
            // Get NSView from top level objects returned from nib load
            if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
                newBox.initialize(withTitle: course.title!, parent: self)
                // Update NSStackView
                courseStack.insertArrangedSubview(newBox, at: courseStack.subviews.count - 1)
            }
        }
        
    }
    
    func loadLectures() {
        for v in lectureStack.arrangedSubviews {
            v.removeFromSuperview()
        }
        lectureCount = 0
        weekCount = 0
        
        for case let lecture as Lecture in thisCourse.lectures! {
            if Int(lectureCount % 2) == 0 {
                addWeek()
            }
            
            // Update Views: Load Course Add Template from nib
            var theObjects: NSArray = []
            Bundle.main.loadNibNamed("HXLectureBox", owner: nil, topLevelObjects: &theObjects)
            // Get NSView from top level objects returned from nib load
            if let newBox = theObjects.filter({$0 is HXLectureBox}).first as? HXLectureBox {
                newBox.initialize(lectureNuber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)")
                //newBox.widthAnchor.constraint(equalTo: ).isActive = true
                lectureStack.addArrangedSubview(newBox)
                lectureCount += 1
            }
        }
    }
    
    func discloseLectureList() {
        if timeLeadingConstraint.constant != 0 {
            timeLeadingConstraint.constant = 0
        } else {
            timeLeadingConstraint.constant = -197
        }
    }
    
    func selectCourse(withTitle: String) {
        
        for case let course as Course in thisSemester.courses! {
            if course.title == withTitle {
                self.thisCourse = course
                loadLectures()
                timeLeadingConstraint.constant = 0
                lectureListYrSemLabel.stringValue = "\(thisSemester.title!.capitalized) \(thisYear.year)"
                lectureListCourseLabel.stringValue = course.title!
                break
            }
        }
        
        // Reset other buttons to not be bold in course stack
        for c in courseStack.arrangedSubviews {
            if let courseButton = c as? HXCourseBox {
                if courseButton.buttonTitle.title != withTitle && courseButton.buttonTitle.title != "Edit Courses" {
                    courseButton.deselect()
                }
            }
        }
        
    }
    
    func addLecture() {
        
        // Update Model
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        newLecture.course = thisCourse
        newLecture.lecture = lectureCount + 1
        newLecture.week = weekCount + 1
        newLecture.day = Int16(NSCalendar.current.component(.day, from: NSDate() as Date))
        newLecture.month = Int16(NSCalendar.current.component(.month, from: NSDate() as Date))
        newLecture.year = Int16(NSCalendar.current.component(.year, from: NSDate() as Date))
        
        appDelegate.saveAction(nil)
        
        if Int(lectureCount % 2) == 0 {
            addWeek()
        }
        
        // Update Views: Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureBox}).first as? HXLectureBox {
            newBox.initialize(lectureNuber: (lectureCount+1), withDate: "\(newLecture.month)/\(newLecture.day)/\(newLecture.year % 100)")
            lectureStack.addArrangedSubview(newBox)
            lectureCount += 1
        }
    }
    func addWeek() {
        // Update Views: Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXWeekDividerBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXWeekBox}).first as? HXWeekBox {
            newBox.initialize(weekNumber: (weekCount+1))
            lectureStack.addArrangedSubview(newBox)
            weekCount += 1
        }
    }
    
    @IBAction func action_addLecture(_ sender: Any) {
        addLecture()
    }
}
