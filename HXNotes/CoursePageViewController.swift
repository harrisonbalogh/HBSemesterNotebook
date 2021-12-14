//
//  CoursePageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CoursePageViewController: NSViewController, NSSplitViewDelegate {

    var sidebarDelegate: SidebarDelegate?
    var selectionDelegate: SelectionDelegate?
    var schedulingDelegate: SchedulingDelegate?
    var documentDropDelegate: DocumentsDropDelegate? {
        didSet {
            docsScrollView?.documentDropDelegate = self.documentDropDelegate
        }
    }
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var courseLabel: NSTextField!
    @IBOutlet weak var colorBox: NSBox!
    
    var weekCount = 0
    
    @IBOutlet weak var splitView: NSSplitView!
    func optimizeSplitViewSpace() {
        
        let MAX_DOCS_SHOWN = 2
        let MAX_TESTS_SHOWN = 2
        let MAX_WORK_SHOWN = 2
        
        let LECTUREBOX_HEIGHT: CGFloat = 44
        let DOCSBOX_HEIGHT: CGFloat = 43
        let WORKBOX_HEIGHT: CGFloat = 43
        let TESTBOX_HEIGHT: CGFloat = 43
        
        let NO_ITEMS_HEIGHT: CGFloat = 2
        
        let splitHeight = splitView.frame.height
        
        // Initial height of the docs, work, and test views. If there aren't arranged subviews, they are limited
        // to the height of their divider plus the 'no items' label. Else the height is the divider height plus
        // up to MAX_items_SHOWN arranged subview heights. So having moring than MAX_items_SHOWN has no affect 
        // in this step.
        let docsHeight = splitDividerDocs.frame.height + max(CGFloat(min(docsStackView.arrangedSubviews.count, MAX_DOCS_SHOWN)) * DOCSBOX_HEIGHT, NO_ITEMS_HEIGHT)
        var workHeight = splitDividerWork.frame.height + max(CGFloat(min(workStackView.arrangedSubviews.count, MAX_WORK_SHOWN)) * WORKBOX_HEIGHT, NO_ITEMS_HEIGHT)
        var testHeight = splitDividerTest.frame.height + max(CGFloat(min(testStackView.arrangedSubviews.count, MAX_TESTS_SHOWN)) * TESTBOX_HEIGHT, NO_ITEMS_HEIGHT)
        
        // The height of the course has no bound on its number of arranged subviews but its overall height must
        // leave room for the minimum heights of the work and test views defined above.
        let lectureHeight = min(splitDividerLecture.frame.height + CGFloat(lectureStackView.arrangedSubviews.count) * LECTUREBOX_HEIGHT, splitHeight - workHeight - testHeight - docsHeight)
        
        // We don't want the work view to go up to the bottom of the course view if it doesn't have to. So start
        // increasing the height of the work view for each arranged sbuview as long as there is room between the
        // minimum test view & docs view and the course view heights.
        if workStackView.arrangedSubviews.count > MAX_WORK_SHOWN {
            for _ in MAX_WORK_SHOWN..<workStackView.arrangedSubviews.count {
                // First check if there is room to increase the work height by another arranged subview's height
                if workHeight + WORKBOX_HEIGHT > splitHeight - lectureHeight - testHeight - docsHeight {
                    break
                }
                workHeight += WORKBOX_HEIGHT
            }
        }
        
        // Perform same height expansion for the test view. Increase it if necessary but we're trying to keep the
        // test and work views using up only the exact amount of space to display all their arranged subviews.
        if testStackView.arrangedSubviews.count > MAX_TESTS_SHOWN {
            for _ in MAX_TESTS_SHOWN..<testStackView.arrangedSubviews.count {
                // First check if there is room to increase the test height by another arranged subview's height
                if testHeight + TESTBOX_HEIGHT > splitHeight - lectureHeight - workHeight - docsHeight {
                    break
                }
                testHeight += TESTBOX_HEIGHT
            }
        }
        
        // Note the docs height is not adjusted for having more than the max amount of items preferred. It will cap
        // at the max specified.
        
        splitView.setPosition(splitHeight - workHeight - testHeight - docsHeight, ofDividerAt: 0)
        splitView.setPosition(splitHeight - workHeight - testHeight, ofDividerAt: 1)
        splitView.setPosition(splitHeight - testHeight, ofDividerAt: 2)
        
        DispatchQueue.main.async {
            self.lectureStackView.scroll(NSPoint(x: 0, y: 0))
        }
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    func prepDisplay() {
        splitView.alphaValue = 0
        splitView.needsDisplay = true
        progressIndicator.isHidden = false
        progressIndicator.alphaValue = 1
        progressIndicator.startAnimation(self)
    }
    // Call this after view has been populated and arranged.
    func display() {
        progressIndicator.stopAnimation(self)
        splitView.alphaValue = 1
        progressIndicator.isHidden = true
        progressIndicator.alphaValue = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        splitView.alphaValue = 0
        self.view.alphaValue = 0
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        toggleCompletedWork.state = NSControl.StateValue.off
        toggleCompletedTests.state = NSControl.StateValue.off
        
        print("CourseVC - viewDidAppear")
        
        sidebarDelegate?.sidebarCourseNeedsPopulating(self)
        
        docsScrollView.registerForDraggedTypes([NSFilenamesPboardType, NSFilenamesPboardType])
        docsScrollView.documentDropDelegate = self.documentDropDelegate
    }
    
    func testListen() {
        
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        splitView.alphaValue = 0
        
        courseLabel.stringValue = ""
        colorBox.fillColor = NSColor.clear
        
        flushDocs()
        flushWork()
        flushTests()
        flushLectures()
    }
    
    @IBAction func action_back(_ sender: NSButton) {
        selectionDelegate?.courseWasSelected(nil)
    }
    
    // MARK: - Populating Lectures
    @IBOutlet weak var lectureStackView: NSStackView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var noLecturesLabel: NSTextField!
    @IBOutlet weak var splitDividerLecture: NSBox!
    
    func noLectureCheck(for course: Course) {
        if course.lectures!.count == 0 {
            noLecturesLabel.alphaValue = 1
            noLecturesLabel.isHidden = false
        } else {
            noLecturesLabel.alphaValue = 0
            noLecturesLabel.isHidden = true
        }
    }
    
    // This button only appears when a course has been checked as happening now.
    @IBAction func action_addLecture(_ sender: NSButton) {
        schedulingDelegate?.schedulingAddLecture()
    }
    
    /// Populate lectureStackView with the loaded lectures from the selected course.
    func loadLectures(from course: Course) {
        // Flush old lectures
        flushLectures()
        
        // Add the first week box
        if course.lectures!.count > 0 {
            lectureStackView.addArrangedSubview(CourseWeekBox.instance(with: 1))
            weekCount = 1
        }
        
        // Add all lectures and weekboxes - do this on another thread as we may be
        // instantiating many Lecture boxes.
        DispatchQueue.main.async {
            for case let lecture as Lecture in course.lectures! {
                self.push(lecture: lecture )
            }
        }
//        for case let lecture as Lecture in course.lectures! {
//            push(lecture: lecture )
//        }
        
        noLectureCheck(for: course)
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
        let newBox = CourseLectureBox.instance(with: lecture)!
        newBox.selectionDelegate = self.selectionDelegate
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
    }
    
    // MARK: - Populating Docs
    
    @IBOutlet weak var splitDividerDocs: NSBox!
    @IBOutlet weak var docsScrollView: DocumentsScrollView!
    @IBOutlet weak var noDocsLabel: NSTextField!
    @IBOutlet weak var docsStackView: NSStackView!
    
    func loadDocs(from course: Course) {
        flushDocs()
        
        guard let semester = course.semester else { return }
        
        let courseLoc = "\(semester.year)/\(semester.title!)/\(course.title!)/Documents/"
        let docsLoc = appDelegate.applicationDocumentsDirectory.appendingPathComponent(courseLoc)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docsLoc, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for file in files {
                push(doc: file)
            }
        } catch { }
        
        noDocsCheck()
    }
    
    func noDocsCheck() {
        if docsStackView.arrangedSubviews.count == 0 {
            noDocsLabel.alphaValue = 1
            noDocsLabel.isHidden = false
        } else {
            noDocsLabel.alphaValue = 0
            noDocsLabel.isHidden = true
        }
    }
    
    /// Pushes a new CourseDocsBox to the docsStackView. The new CourseDocsBox is returned
    /// if callee of push(:String) wants to do custom setup of the view.
    @discardableResult func push(doc: URL) -> CourseDocsBox {
        let newBox = CourseDocsBox.instance(with: doc)!
//        newBox.selectionDelegate = self.selectionDelegate
        docsStackView.addArrangedSubview(newBox)
        return newBox
    }
    
    func flushDocs() {
        for subview in docsStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }

    // MARK: - Populating Due
    @IBOutlet weak var workStackView: NSStackView!
    @IBOutlet weak var buttonAddWork: NSButton!
    @IBOutlet weak var noWorkLabel: NSTextField!
    @IBOutlet weak var splitDividerWork: NSBox!
    @IBOutlet weak var toggleCompletedWork: NSButton!
    var workDetailsPopover: NSPopover!
    
    func noWorkCheck() {
        if workStackView.arrangedSubviews.count == 0 {
            noWorkLabel.alphaValue = 1
            noWorkLabel.isHidden = false
        } else {
            noWorkLabel.alphaValue = 0
            noWorkLabel.isHidden = true
        }
    }

    @IBAction func action_addDue(_ sender: NSButton) {
        schedulingDelegate?.schedulingAddWork()

        let WORKBOX_HEIGHT: CGFloat = 43
        
        let y = splitDividerWork.convert(splitDividerWork.bounds, to: splitView).origin.y
        let yNext = splitDividerTest.convert(splitDividerTest.bounds, to: splitView).origin.y
        
        if yNext - y - splitDividerWork.bounds.height < WORKBOX_HEIGHT {
            splitView.setPosition(y - WORKBOX_HEIGHT, ofDividerAt: 1)
        }
        
        DispatchQueue.main.async {
            self.workStackView.scroll(NSPoint(x: 0, y: 0))
        }
    }
    
    func loadWork(from course: Course, showingCompleted: Bool) {
        course.checkWork()
        
        flushWork()
        
        // Add all work
        for case let work as Work in course.work! {
            if work.completed && showingCompleted {
                push(work: work )
            } else if !work.completed {
                generateTitle(for: work)
                push(work: work )
            }
        }

        noWorkCheck()
    }
    
    /// Pushes a new CourseWorkBox to the workStackView. The new CourseWorkBox is returned
    /// if callee of push(:Work) wants to do custom setup of the view.
    @discardableResult func push(work: Work) -> CourseWorkBox {
        let newBox = CourseWorkBox.instance(with: work)!
        newBox.selectionDelegate = self.selectionDelegate
        workStackView.addArrangedSubview(newBox)
        return newBox
    }
    
    func flushWork() {
        for subview in workStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    func pop(workBox: CourseWorkBox) {
        workBox.removeFromSuperview()
        
        noWorkCheck()
    }
    
    @IBAction func action_completedWork(_ sender: NSButton) {
        sidebarDelegate?.sidebarCoursePopulateCompletedWork(self)
    }
    
    // MARK: - Populating Tests
    @IBOutlet weak var testStackView: NSStackView!
    @IBOutlet weak var buttonAddTest: NSButton!
    @IBOutlet weak var noTestsLabel: NSTextField!
    @IBOutlet weak var splitDividerTest: NSBox!
    @IBOutlet weak var toggleCompletedTests: NSButton!
    var testDetailsPopover: NSPopover!
    
    func noTestsCheck() {
        if testStackView.arrangedSubviews.count == 0 {
            noTestsLabel.alphaValue = 1
            noTestsLabel.isHidden = false
        } else {
            noTestsLabel.alphaValue = 0
            noTestsLabel.isHidden = true
        }
    }
    
    @IBAction func action_addTests(_ sender: NSButton) {
        schedulingDelegate?.schedulingAddTest()
        
        let TESTBOX_HEIGHT: CGFloat = 43
        
        let y = splitDividerTest.convert(splitDividerTest.bounds, to: splitView).origin.y
        
        if splitView.frame.height - y < TESTBOX_HEIGHT {
            splitView.setPosition(y - TESTBOX_HEIGHT, ofDividerAt: 2)
        }
        
        DispatchQueue.main.async {
            self.testStackView.scroll(NSPoint(x: 0, y: 0))
        }
    }
    
    func loadTests(from course: Course, showingCompleted: Bool) {
        flushTests()
        
        // Add all tests
        for case let test as Test in course.tests! {            
            if test.completed && showingCompleted {
                push(test: test )
            } else if !test.completed {
                generateTitle(for: test)
                push(test: test )
            }
        }
        
        noTestsCheck()
    }
    
    /// Pushes a new CourseTestBox to the testStackView. The new CourseTestBox is returned
    /// if callee of push(:Test) wants to do custom setup of the view.
    @discardableResult func push(test: Test) -> CourseTestBox {
        let newBox = CourseTestBox.instance(with: test)!
        newBox.selectionDelegate = self.selectionDelegate
        testStackView.addArrangedSubview(newBox)
        return newBox
    }
    
    func flushTests() {
        for subview in testStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    func pop(testBox: CourseTestBox) {
        testBox.removeFromSuperview()
        
        noTestsCheck()
    }
    
    @IBAction func action_completedTests(_ sender: NSButton) {
        sidebarDelegate?.sidebarCoursePopulateCompletedTests(self)
    }
    
    // MARK: - Split View Delegation
    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        
        var newRect: NSRect!
        
        switch dividerIndex {
            case 0: newRect = splitDividerDocs.convert(splitDividerDocs.bounds, to: splitView)
            case 1: newRect = splitDividerWork.convert(splitDividerWork.bounds, to: splitView)
            case 2: newRect = splitDividerTest.convert(splitDividerTest.bounds, to: splitView)
            default: return NSZeroRect
        }
        
        newRect.size = CGSize(width: toggleCompletedWork.frame.origin.x, height: newRect.height)
        return newRect
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
    
    public func lectureBoxSize(reduced: Bool) {
        for case let lecBox as CourseLectureBox in lectureStackView.arrangedSubviews {
            lecBox.size(reduced: reduced)
        }
    }
    
    // MARK: - Work & Test Editor Popovers
    
    func closeWorkPopover() {
        if workDetailsPopover != nil {
            if workDetailsPopover.isShown {
                workDetailsPopover.performClose(self)
            }
        }
    }
    
    func showWorkPopover(for workBox: CourseWorkBox) {
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
        let workAVC = WorkAdderLectureController(nibName: NSNib.Name(rawValue: "WorkAdderLectureController"), bundle: nil)
        workAVC.schedulingDelegate = self.schedulingDelegate
        workAVC.selectionDelegate = self.selectionDelegate
        workAVC.workBox = workBox
        workDetailsPopover.contentViewController = workAVC
        workDetailsPopover.show(relativeTo: workBox.buttonDetails.bounds, of: workBox.buttonDetails, preferredEdge: NSRectEdge.maxX)
    }
    
    func closeTestPopover() {
        if testDetailsPopover != nil {
            if testDetailsPopover.isShown {
                testDetailsPopover.performClose(self)
            }
        }
    }
    
    func showTestPopover(for testBox: CourseTestBox) {
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
        let testAVC = TestAdderViewController(nibName: NSNib.Name(rawValue: "TestAdderViewController"), bundle: nil)
        testAVC.schedulingDelegate = self.schedulingDelegate
        testAVC.selectionDelegate = self.selectionDelegate
        testAVC.testBox = testBox
        testDetailsPopover.contentViewController = testAVC
        testDetailsPopover.show(relativeTo: testBox.buttonDetails.bounds, of: testBox.buttonDetails, preferredEdge: NSRectEdge.maxX)
    }
}
