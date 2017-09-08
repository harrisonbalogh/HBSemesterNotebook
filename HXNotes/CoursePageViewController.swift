//
//  CoursePageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CoursePageViewController: NSViewController {

    weak var sidebarVC: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    @IBOutlet weak var courseLabel: NSTextField!
    @IBOutlet weak var colorBox: NSBox!
    
    var weekCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        print("CourseVC - viewDidAppear")
        
        guard let course = sidebarVC.selectedCourse else { return }

        let theColor = NSColor(red: CGFloat(course.color!.red), green: CGFloat(course.color!.green), blue: CGFloat(course.color!.blue), alpha: 0.25)
        self.colorBox.fillColor = theColor
        
        courseLabel.stringValue = course.title!
        
        course.checkWork()
        course.checkTests()
        
        loadLectures()
        loadTests()
        loadWork()
        
        // Fill in absent lectures since last course open
        sidebarVC.selectedCourse.fillAbsentLectures()
        
        if course.duringTimeSlot() != nil {
            addButton.isEnabled = true
            addButton.isHidden = false
            addButton.title = "Add Lecture \(max(course.theoreticalLectureCount(), 1))"
        } else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        print("CourseVC - viewWillDisappear")
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
            lectureStackView.addArrangedSubview(CourseWeekBox.instance(with: 1))
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
            lectureStackView.addArrangedSubview(CourseWeekBox.instance(with: (weekCount+1) ))
            weekCount += 1
        }
        // Create lecture box
        let newBox = CourseLectureBox.instance(with: lecture, owner: self)!
        lectureStackView.addArrangedSubview(newBox)
        newBox.widthAnchor.constraint(equalTo: lectureStackView.widthAnchor).isActive = true
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
                generateTitle(for: work)
                push(work: work )
            }
        }
        
        noWorkCheck()
    }
    
    func push(work: Work) {
        workStackView.addArrangedSubview(CourseWorkBox.instance(with: work, owner: self)!)
    }
    
    func flushWork() {
        for subview in workStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        noWorkCheck()
    }
    
    func pop(workBox: CourseWorkBox) {
        workBox.removeFromSuperview()
        
        noWorkCheck()
    }
    
    // MARK: - Populating Tests
    @IBOutlet weak var testStackView: NSStackView!
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
    
    @IBAction func action_addTests(_ sender: NSButton) {
        push(test: sidebarVC.selectedCourse.createTest() )
        
        noTestsCheck()
    }
    
    func loadTests() {
        flushTests()
        
        // Add all tests
        for case let test as Test in sidebarVC.selectedCourse.tests! {
            if !test.completed {
                generateTitle(for: test)
                push(test: test )
            }
        }
        
        noTestsCheck()
    }
    
    func push(test: Test) {
        testStackView.addArrangedSubview(CourseTestBox.instance(with: test, owner: self)!)
    }
    
    func flushTests() {
        for subview in testStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        noTestsCheck()
    }
    
    func pop(testBox: CourseTestBox) {
        testBox.removeFromSuperview()
        
        noTestsCheck()
    }
    
    // MARK: - Convenience Methods
    
    private func generateTitle(for work: Work) {
        if !work.customTitle && work.date != nil {
            
            // Adjust if work is due today
            let weekday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            let weekdayWork = Calendar.current.component(.weekday, from: work.date!)
            let minuteOfDayWork = Calendar.current.component(.hour, from: work.date!) * 60 + Calendar.current.component(.minute, from: work.date!)
            
            work.title! = "Placeholder"
            
            var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            if weekday == weekdayWork && minuteOfDay < minuteOfDayWork {
                ENGLISH_DAYS[weekday] = "Today"
            }
            let day = ENGLISH_DAYS[weekdayWork]
            
            work.title! = work.course!.nextWorkTitleAvailable(with: "\(day) Work ")
        }
    }
    
    private func generateTitle(for test: Test) {
        if !test.customTitle && test.date != nil {
            
            // Adjust if work is due today
            let weekday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            let weekdayTest = Calendar.current.component(.weekday, from: test.date!)
            let minuteOfDayTest = Calendar.current.component(.hour, from: test.date!) * 60 + Calendar.current.component(.minute, from: test.date!)
            
            test.title! = "Placeholder"
            
            var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            if weekday == weekdayTest && minuteOfDay < minuteOfDayTest {
                ENGLISH_DAYS[weekday] = "Today"
            }
            let day = ENGLISH_DAYS[weekdayTest]
            
            test.title! = test.course!.nextWorkTitleAvailable(with: "\(day) Test ")
        }
    }
    
    // MARK: - Notifiers
    
    func notifySelected(lecture: Lecture) {
        sidebarVC.notifySelected(lecture: lecture)
        
        // Update visuals for all HXLectureBox's
        for case let lectureBox as CourseLectureBox in lectureStackView.arrangedSubviews {
            if lectureBox.lecture == lecture {
                lectureBox.updateVisual(selected: true)
            } else {
                lectureBox.updateVisual(selected: false)
            }
        }
    }
    
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
    
    func notifyReveal(testBox: CourseTestBox) {
        if testDetailsPopover != nil {
            if testDetailsPopover.isShown {
                if let testAVC = testDetailsPopover.contentViewController as? TestAdderViewController {
                    if testAVC.testBox == testBox {
                        testDetailsPopover.performClose(self)
                        return
                    }
                }
                testDetailsPopover.performClose(self)
            }
        }
        testDetailsPopover = NSPopover()
        let testAVC = TestAdderViewController(nibName: "TestAdderViewController", bundle: nil)
        testAVC?.owner = self
        testAVC?.testBox = testBox
        testDetailsPopover.contentViewController = testAVC
        testDetailsPopover.show(relativeTo: testBox.buttonDetails.bounds, of: testBox.buttonDetails, preferredEdge: NSRectEdge.maxX)
        
    }
    func notifyReveal(workBox: CourseWorkBox) {
        if workDetailsPopover != nil {
            if workDetailsPopover.isShown {
                if let workAVC = workDetailsPopover.contentViewController as? WorkAdderLectureController {
                    if workAVC.workBox == workBox {
                        workDetailsPopover.performClose(self)
                        return
                    }
                }
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
        for case let testBox as CourseTestBox in testStackView.arrangedSubviews {
            if testBox.test! == test {
                // Update model
                appDelegate.managedObjectContext.delete( test )
                appDelegate.saveAction(self)
                // Update visuals
                pop(testBox: testBox)
                break
            }
        }
    }
    func notifyDelete(work: Work) {
        for case let workBox as CourseWorkBox in workStackView.arrangedSubviews {
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
    func notifyRenamed(lecture: Lecture) {
        for case let lectureBox as CourseLectureBox in lectureStackView.arrangedSubviews {
            if lectureBox.lecture! == lecture {
                lectureBox.labelCustomTitle.stringValue = lecture.title!
                break
            }
        }
    }
    func notifyRenamed(test: Test) {
        for case let testBox as CourseTestBox in testStackView.arrangedSubviews {
            if testBox.test! == test {
                testBox.labelTest.stringValue = test.title!
                break
            }
        }
    }
    func notifyRenamed(work: Work) {
        for case let workBox as CourseWorkBox in workStackView.arrangedSubviews {
            if workBox.work! == work {
                workBox.labelWork.stringValue = work.title!
                break
            }
        }
    }
    func notifyDated(test: Test) {
        for case let testBox as CourseTestBox in testStackView.arrangedSubviews {
            if testBox.test! == test {
                let day = Calendar.current.component(.day, from: test.date!)
                let month = Calendar.current.component(.month, from: test.date!)
                let year = Calendar.current.component(.year, from: test.date!)
                let weekday = Calendar.current.component(.weekday, from: test.date!)
                let minuteOfDay = Calendar.current.component(.hour, from: test.date!) * 60 + Calendar.current.component(.minute, from: test.date!)
                let weekdayToday = Calendar.current.component(.weekday, from: Date())
                let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
                if weekdayToday == weekday && minuteOfDayToday < minuteOfDay {
                    testBox.labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
                } else {
                    testBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
                }
                break
            }
        }
    }
    func notifyDated(work: Work) {
        for case let workBox as CourseWorkBox in workStackView.arrangedSubviews {
            if workBox.work! == work {
                let day = Calendar.current.component(.day, from: work.date!)
                let month = Calendar.current.component(.month, from: work.date!)
                let year = Calendar.current.component(.year, from: work.date!)
                let weekday = Calendar.current.component(.weekday, from: work.date!)
                let minuteOfDay = Calendar.current.component(.hour, from: work.date!) * 60 + Calendar.current.component(.minute, from: work.date!)
                let weekdayToday = Calendar.current.component(.weekday, from: Date())
                let minuteOfDayToday = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
                if weekdayToday == weekday && minuteOfDayToday < minuteOfDay {
                    workBox.labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
                } else {
                    workBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
                }
                break
            }
        }
    }
}
