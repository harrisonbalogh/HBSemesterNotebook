//
//  SemesterPageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterPageViewController: NSViewController {
    
    weak var sidebarVC: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        print("SemesterVC - viewDidAppear")
        
        if sidebarVC.selectedSemester == nil {
            return
        }
        
        loadCourses()
        loadWork()
        loadTests()
        
//        sidebarVC.notifySelectedSemester()
        
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        print("SemesterVC - viewWillDisappear")
        
//        sidebarVC.notifySelectedScheduler()
    }
    
    
    
    // MARK: - Populating Courses
    
    @IBOutlet weak var courseStackView: NSStackView!
    
    /// Flushes out subviews in courseStackView and repopulates with a course box for every course in selectedSemester.
    /// Scheduling determines if the coures boxes are editable or clickable for content display.
    private func loadCourses() {
        
        // Flush old views
        flushCourses()
        
        // Push course boxes
        for case let course as Course in sidebarVC.selectedSemester.courses! {
            push(course: course )
        }
        
//        if scheduling {
//            // Scheduling
//            
//            // When first loading editable courses, append the 'New Course' button at end of courseStackView
//            let addBox = HXCourseAddBox.instance(target: self, action: #selector(SemesterPageViewController.action_addCourse))
//            courseStackView.addArrangedSubview(addBox!)
//            addBox?.widthAnchor.constraint(equalTo: courseStackView.widthAnchor).isActive = true
//            
//            // Add editable course boxes
//            for case let course as Course in sidebarVC.selectedSemester.courses! {
//                pushEditableCourseToStackView( course )
//            }
//            
//        } else {
//            // Not scheduling
//            
//            
//            
//        }
    }
    
    /// Handles purely the visual aspect of courses. Internal use only. Adds a new HXCourseBox to the courseStackView.
    private func push(course: Course) {
        let newBox = SemesterCourseBox.instance(with: course, owner: self)
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
        sidebarVC.notifyScheduling(is: true)
    }
    
    
    // MARK: - Populating Work
    
    @IBOutlet weak var workStackView: NSStackView!
    @IBOutlet weak var noWorkLabel: NSTextField!
    
    private func loadWork() {
        
        flushWork()
        
        // Push work boxes
        for case let course as Course in sidebarVC.selectedSemester.courses! {
            for case let work as Work in course.work! {
                if !work.completed {
                    push(work: work )
                }
            }
        }
        
        noWorkCheck()
        
    }
    
    private func push(work: Work) {
        let newBox = SemesterWorkBox.instance(with: work, owner: self)!
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
    
    @IBOutlet weak var testStackView: NSStackView!
    @IBOutlet weak var noTestLabel: NSTextField!
    
    private func loadTests() {
        
        flushTests()
        
        // Push test boxes
        for case let course as Course in sidebarVC.selectedSemester.courses! {
            for case let test as Test in course.tests! {
                if !test.completed {
                    push(test: test )
                }
            }
        }
        
        noTestCheck()
        
    }
    
    private func push(test: Test) {
        let newBox = SemesterTestBox.instance(with: test, owner: self)!
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
    
    // MARK: - Notifiers
    
    /// Inform the semesterVC that one of its HXCourseBox's has been mouse clicked.
    func notifySelected(course: Course) {
        sidebarVC.next(from: course)
    }
    
    func notifySelected(work: Work) {
        notifySelected(course: work.course!)
    }
    
    func notifySelected(test: Test) {
        notifySelected(course: test.course!)
    }
    
}
