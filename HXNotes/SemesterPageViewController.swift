//
//  SemesterPageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterPageViewController: NSViewController, NSSplitViewDelegate {
    
    var selectionDelegate: SelectionDelegate?
    var schedulingDelegate: SchedulingDelegate?
    var sidebarDelegate: SidebarDelegate?
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    @IBOutlet weak var splitView: NSSplitView!
    func optimizeSplitViewSpace() {
        
        let MAX_TESTS_SHOWN = 2
        let MAX_WORK_SHOWN = 2
        
        let COURSEBOX_HEIGHT: CGFloat = 30
        let WORKBOX_HEIGHT: CGFloat = 43
        let TESTBOX_HEIGHT: CGFloat = 43
        
        let NO_ITEMS_HEIGHT: CGFloat = 18
        
        let splitHeight = splitView.frame.height
        
        // Initial height of the work and test views. If there aren't arranged subviews, they are limited to
        // the height of their divider plus the 'no items' label. Else the height is the divider height plus
        // up to MAX_TESTS_SHOWN arranged subview heights. So having moring than MAX_TESTS_SHOWN has no affect
        // in this step.
        var workHeight = splitDividerWork.frame.height + max(CGFloat(min(workStackView.arrangedSubviews.count, MAX_WORK_SHOWN)) * WORKBOX_HEIGHT, NO_ITEMS_HEIGHT)
        var testHeight = splitDividerTest.frame.height + max(CGFloat(min(testStackView.arrangedSubviews.count, MAX_TESTS_SHOWN)) * TESTBOX_HEIGHT, NO_ITEMS_HEIGHT)
        
        // The height of the course has no bound on its number of arranged subviews but its overall height must
        // leave room for the minimum heights of the work and test views defined above.
        let courseHeight = min(splitDividerCourse.frame.height + CGFloat(courseStackView.arrangedSubviews.count) * COURSEBOX_HEIGHT, splitHeight - workHeight - testHeight)
        
        // We don't want the work view to go up to the bottom of the course view if it doesn't have to. So start
        // increasing the height of the work view for each arranged sbuview as long as there is room between the 
        // minimum test view and the course view heights.
        if workStackView.arrangedSubviews.count > MAX_WORK_SHOWN {
            for _ in MAX_WORK_SHOWN..<workStackView.arrangedSubviews.count {
                // First check if there is room to increase the work height by another arranged subview's height
                if workHeight + WORKBOX_HEIGHT > splitHeight - courseHeight - testHeight {
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
                if testHeight + TESTBOX_HEIGHT > splitHeight - courseHeight - workHeight {
                    break
                }
                testHeight += TESTBOX_HEIGHT
            }
        }
        
        splitView.setPosition(splitHeight - workHeight - testHeight, ofDividerAt: 0)
        splitView.setPosition(splitHeight - testHeight, ofDividerAt: 1)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        print("SemesterVC - viewDidAppear")
        
        sidebarDelegate?.sidebarSemesterNeedsPopulating(self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        print("SemesterVC - viewWillDisappear")
    }
    
    // MARK: - Populating Courses
    
    @IBOutlet weak var courseView: NSView!
    @IBOutlet weak var courseStackView: NSStackView!
    @IBOutlet weak var splitDividerCourse: NSBox!
    
    /// Flushes out subviews in courseStackView and repopulates with a course box for every course in selectedSemester.
    /// Scheduling determines if the coures boxes are editable or clickable for content display.
    func loadCourses(from semester: Semester) {
        
        // Flush old views
        flushCourses()
        
        // Push course boxes
        for case let course as Course in semester.courses! {
            push(course: course )
        }
    }
    
    /// Handles purely the visual aspect of courses. Internal use only. Adds a new HXCourseBox to the courseStackView.
    private func push(course: Course) {
        let newBox = SemesterCourseBox.instance(with: course)
        newBox?.selectionDelegate = self.selectionDelegate
        courseStackView.addArrangedSubview(newBox!)
        newBox?.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
    }
    
    /// Removes all subviews from courseStackView
    private func flushCourses() {
        for subview in courseStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    @IBAction func action_editSchedule(_ sender: NSButton) {
        schedulingDelegate?.schedulingDidStart()
    }
    
    
    // MARK: - Populating Work
    
    @IBOutlet weak var workView: NSView!
    @IBOutlet weak var workStackView: NSStackView!
    @IBOutlet weak var noWorkLabel: NSTextField!
    @IBOutlet weak var splitDividerWork: NSBox!
    
    func loadWork(from semester: Semester) {
        
        flushWork()
        
        // Push work boxes
        for case let course as Course in semester.courses! {
            for case let work as Work in course.work! {
                if !work.completed {
                    push(work: work )
                }
            }
        }
        
        noWorkCheck()
        
    }
    
    private func push(work: Work) {
        let newBox = SemesterWorkBox.instance(with: work)!
        newBox.selectionDelegate = self.selectionDelegate
        workStackView.addArrangedSubview(newBox)
        newBox.widthAnchor.constraint(equalTo: workStackView.widthAnchor).isActive = true
        
        noWorkCheck()
    }
    
    private func pop(workBox: SemesterWorkBox) {
        workBox.removeFromSuperview()
        
        noWorkCheck()
    }
    
    private func flushWork() {
        for subview in workStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    private func noWorkCheck() {
        if workStackView.arrangedSubviews.count == 0 {
            noWorkLabel.alphaValue = 1
            noWorkLabel.isHidden = false
        } else {
            noWorkLabel.alphaValue = 0
            noWorkLabel.isHidden = true
        }
    }
    
    // MARK: - Populating Tests
    
    @IBOutlet weak var testView: NSView!
    @IBOutlet weak var testStackView: NSStackView!
    @IBOutlet weak var noTestLabel: NSTextField!
    @IBOutlet weak var splitDividerTest: NSBox!
    
    func loadTests(from semester: Semester) {
        
        flushTests()
        
        // Push test boxes
        for case let course as Course in semester.courses! {
            for case let test as Test in course.tests! {
                if !test.completed {
                    push(test: test )
                }
            }
        }
        
        noTestCheck()
        
    }
    
    private func push(test: Test) {
        let newBox = SemesterTestBox.instance(with: test)!
        newBox.selectionDelegate = self.selectionDelegate
        testStackView.addArrangedSubview(newBox)
        newBox.widthAnchor.constraint(equalTo: testStackView.widthAnchor).isActive = true
        
        noTestCheck()
    }
    
    private func pop(testBox: SemesterTestBox) {
        testBox.removeFromSuperview()
        
        noTestCheck()
    }
    
    private func flushTests() {
        for subview in testStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
    }
    
    private func noTestCheck() {
        if testStackView.arrangedSubviews.count == 0 {
            noTestLabel.alphaValue = 1
            noTestLabel.isHidden = false
        } else {
            noTestLabel.alphaValue = 0
            noTestLabel.isHidden = true
        }
    }
    
    // MARK: - Split View Delegation
    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        switch dividerIndex {
            case 0:
                return splitDividerWork.convert(splitDividerWork.bounds, to: splitView)
            case 1:
                return splitDividerTest.convert(splitDividerTest.bounds, to: splitView)
            default:
                return NSZeroRect
        }
    }
}
