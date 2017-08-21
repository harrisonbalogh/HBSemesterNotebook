//
//  CoursePageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CoursePageViewController: NSViewController {

    var sidebarVC: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    @IBOutlet weak var courseLabel: NSTextField!
    
    var weekCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if sidebarVC.selectedCourse == nil {
            return
        }
        
        courseLabel.stringValue = sidebarVC.selectedCourse.title!
        
        sidebarVC.selectedCourse.checkWork()
        sidebarVC.selectedCourse.checkTests()
        
        loadLectures()
        loadTests()
        loadWork()
        
        // Fill in absent lectures since last course open
        sidebarVC.selectedCourse.fillAbsentLectures()

        if AppDelegate.scheduleAssistant.checkHappening() {
            addButton.isEnabled = true
            addButton.isHidden = false
        } else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
    
    @IBAction func action_back(_ sender: NSButton) {
        sidebarVC.prev()
    }
    
    // MARK: - Populating Lectures
    @IBOutlet weak var lectureStackView: NSStackView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var noLecturesLabel: NSTextField!
    
    func noLectureCheck() {
        if sidebarVC.selectedCourse.lectures!.count == 0 {
            noLecturesLabel.alphaValue = 1
            noLecturesLabel.isHidden = false
        } else {
            noLecturesLabel.alphaValue = 0
            noLecturesLabel.isHidden = true
        }
    }
    
    // This button only appears when a course has been checked as happening now.
    @IBAction func action_addLecture(_ sender: NSButton) {
        sidebarVC.addLecture()
        
        noLectureCheck()
    }
    
    /// Populate lectureStackView with the loaded lectures from the selected course.
    func loadLectures() {
        
        // Flush old lectures
        flushLectures()
        
        // Add the first week box
        if sidebarVC.selectedCourse.lectures!.count > 0 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (1)))
            weekCount = 1
        }
        
        // Add all lectures and weekboxes
        for case let lecture as Lecture in sidebarVC.selectedCourse.lectures! {
            push(lecture: lecture )
        }
        
        noLectureCheck()
    }
    
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func push(lecture: Lecture) {

        // Insert weekbox every time week changes from previous lecture.
        // Following week deducation requires sorted time slots
        if lecture.course!.needsSort {
            lecture.course!.sortTimeSlots()
        }
        // If the lecture requested to be pushed is the first time slot in the week, it must be a new week
        if lecture.course!.timeSlots?.index(of: lecture.timeSlot!) == 0 && lectureStackView.arrangedSubviews.count != 1 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        }
        // If absent, create an absent box, instead of a normal box
        if lecture.absent {
            let newBox = HXAbsentLectureBox.instance()
            lectureStackView.addArrangedSubview(newBox!)
            newBox!.widthAnchor.constraint(equalTo: lectureStackView.widthAnchor).isActive = true
        } else {
            let year = lecture.course!.semester!.year
            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(year % 100)", owner: self)
            lectureStackView.addArrangedSubview(newBox!)
            newBox?.widthAnchor.constraint(equalTo: lectureStackView.widthAnchor).isActive = true
        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Removes all HXLectureBox's and HXWeekBox's from the ledgerStackView.
    private func flushLectures() {
        if lectureStackView != nil {
            for v in lectureStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
        }
        weekCount = 0
        
        noLectureCheck()
    }
    
    // MARK: - Populating Due
    @IBOutlet weak var workStackView: NSStackView!
    @IBOutlet weak var buttonAddWork: NSButton!
    @IBOutlet weak var noWorkLabel: NSTextField!
    var workDetailsPopover: NSPopover!
    
    func noWorkCheck() {
        if sidebarVC.selectedCourse.work!.filter({!($0 as! Work).completed}).count == 0 {
            noWorkLabel.alphaValue = 1
            noWorkLabel.isHidden = false
        } else {
            noWorkLabel.alphaValue = 0
            noWorkLabel.isHidden = true
        }
    }

    @IBAction func action_addDue(_ sender: NSButton) {
        push(work: sidebarVC.selectedCourse.createWork() )
        
        noWorkCheck()
    }
    
    func loadWork() {
        flushWork()
        
        // Add all work
        for case let work as Work in sidebarVC.selectedCourse.work! {
            if !work.completed {
                push(work: work )
            }
        }
        
        noWorkCheck()
    }
    
    func push(work: Work) {
        workStackView.addArrangedSubview(HXWorkBox.instance(with: work, for: self))
    }
    
    func flushWork() {
        for subview in workStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        noWorkCheck()
    }
    
    func pop(workBox: HXWorkBox) {
        workBox.removeFromSuperview()
        
        noWorkCheck()
    }
    
    // MARK: - Populating Tests
    @IBOutlet weak var examStackView: NSStackView!
    @IBOutlet weak var buttonAddTest: NSButton!
    @IBOutlet weak var noTestsLabel: NSTextField!
    var testDetailsPopover: NSPopover!
    
    func noTestsCheck() {
        if sidebarVC.selectedCourse.tests!.filter({!($0 as! Test).completed}).count == 0 {
            noTestsLabel.alphaValue = 1
            noTestsLabel.isHidden = false
        } else {
            noTestsLabel.alphaValue = 0
            noTestsLabel.isHidden = true
        }
    }
    
    @IBAction func action_addExams(_ sender: NSButton) {
        push(test: sidebarVC.selectedCourse.createTest() )
        
        noTestsCheck()
    }
    
    func loadTests() {
        flushTests()
        
        // Add all tests
        for case let test as Test in sidebarVC.selectedCourse.tests! {
            if !test.completed {
                push(test: test )
            }
        }
        
        noTestsCheck()
    }
    
    func push(test: Test) {
        examStackView.addArrangedSubview(HXExamBox.instance(with: test, for: self))
    }
    
    func flushTests() {
        for subview in examStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        noTestsCheck()
    }
    
    func pop(examBox: HXExamBox) {
        examBox.removeFromSuperview()
        
        noTestsCheck()
    }
    
    // MARK: - Notifiers
    
    func notifyCloseTestDetails() {
        if testDetailsPopover != nil {
            if testDetailsPopover.isShown {
                testDetailsPopover.performClose(self)
            }
        }
    }
    
    func notifyCloseWorkDetails() {
        if workDetailsPopover != nil {
            if workDetailsPopover.isShown {
                workDetailsPopover.performClose(self)
            }
        }
    }
    
    func notifyReveal(examBox: HXExamBox) {
        if testDetailsPopover != nil {
            if testDetailsPopover.isShown {
                testDetailsPopover.performClose(self)
            }
        }
        testDetailsPopover = NSPopover()
        let examAVC = ExamAdderViewController(nibName: "ExamAdderViewController", bundle: nil)
        examAVC?.owner = self
        examAVC?.examBox = examBox
        testDetailsPopover.contentViewController = examAVC
        testDetailsPopover.show(relativeTo: examBox.buttonDetails.bounds, of: examBox.buttonDetails, preferredEdge: NSRectEdge.maxX)
        
    }
    func notifyReveal(workBox: HXWorkBox) {
        if workDetailsPopover != nil {
            if workDetailsPopover.isShown {
                workDetailsPopover.performClose(self)
            }
        }
        workDetailsPopover = NSPopover()
        let workAVC = WorkAdderLectureController(nibName: "WorkAdderLectureController", bundle: nil)
        workAVC?.owner = self
        workAVC?.workBox = workBox
        workDetailsPopover.contentViewController = workAVC
        workDetailsPopover.show(relativeTo: workBox.buttonDetails.bounds, of: workBox.buttonDetails, preferredEdge: NSRectEdge.maxX)
    }
    
    func notifyDelete(test: Test) {
        for case let testBox as HXExamBox in examStackView.arrangedSubviews {
            if testBox.test! == test {
                // Update model
                appDelegate.managedObjectContext.delete( test )
                appDelegate.saveAction(self)
                // Update visuals
                pop(examBox: testBox)
                break
            }
        }
    }
    func notifyDelete(work: Work) {
        for case let workBox as HXWorkBox in workStackView.arrangedSubviews {
            if workBox.work! == work {
                // Update model
                appDelegate.managedObjectContext.delete( work )
                appDelegate.saveAction(self)
                // Update visuals
                pop(workBox: workBox)
                break
            }
        }
    }
    func notifyRenamed(test: Test) {
        for case let testBox as HXExamBox in examStackView.arrangedSubviews {
            if testBox.test! == test {
                testBox.labelExam.stringValue = test.title!
                break
            }
        }
    }
    func notifyRenamed(work: Work) {
        for case let workBox as HXWorkBox in workStackView.arrangedSubviews {
            if workBox.work! == work {
                workBox.labelWork.stringValue = work.title!
                break
            }
        }
    }
    func notifyDated(test: Test) {
        for case let testBox as HXExamBox in examStackView.arrangedSubviews {
            if testBox.test! == test {
                let day = Calendar.current.component(.day, from: test.date!)
                let month = Calendar.current.component(.month, from: test.date!)
                let year = Calendar.current.component(.year, from: test.date!)
                testBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
                break
            }
        }
    }
    func notifyDated(work: Work) {
        for case let workBox as HXWorkBox in workStackView.arrangedSubviews {
            if workBox.work! == work {
                let day = Calendar.current.component(.day, from: work.date!)
                let month = Calendar.current.component(.month, from: work.date!)
                let year = Calendar.current.component(.year, from: work.date!)
                workBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
                break
            }
        }
    }
}
