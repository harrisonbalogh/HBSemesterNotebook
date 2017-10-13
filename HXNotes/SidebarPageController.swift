//
//  SidebarPageController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SidebarPageController: NSPageController, NSPageControllerDelegate {
    
    var selectionDelegate: SelectionDelegate? {
        didSet {
            semesterVC?.selectionDelegate = self.selectionDelegate
            courseVC?.selectionDelegate = self.selectionDelegate
        }
    }
    var schedulingDelegate: SchedulingDelegate? {
        didSet {
            schedulerVC?.schedulingDelegate = self.schedulingDelegate
            semesterVC?.schedulingDelegate = self.schedulingDelegate
            courseVC?.schedulingDelegate = self.schedulingDelegate
        }
    }
    var sidebarDelegate: SidebarDelegate? {
        didSet {
            schedulerVC?.sidebarDelegate = self.sidebarDelegate
            semesterVC?.sidebarDelegate = self.sidebarDelegate
            courseVC?.sidebarDelegate = self.sidebarDelegate
        }
    }
    var documentsDropDelegate: DocumentsDropDelegate? {
        didSet {
            courseVC?.documentDropDelegate = self.documentsDropDelegate
        }
    }

    @IBOutlet var schedulerVC: SchedulerPageViewController!
    @IBOutlet var semesterVC: SemesterPageViewController!
    @IBOutlet var courseVC: CoursePageViewController!
    
    let SBSchedulerIndex = 0
    let SBSemesterIndex = 1
    let SBCourseIndex = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        self.arrangedObjects = ["schedulerPage", "semesterPage", "coursePage"]
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if semesterVC != nil && self.selectedIndex == SBSemesterIndex {
            semesterVC.view.frame = self.view.bounds
        }
        
        if courseVC != nil && self.selectedIndex == SBCourseIndex {
            courseVC.view.frame = self.view.bounds
        }
        
        if schedulerVC != nil && self.selectedIndex == SBSchedulerIndex {
            schedulerVC.view.frame = self.view.bounds
        }
        
        // 154px gathered from CourseLectureBox nib
        if selectedIndex == SBCourseIndex && self.view.frame.width <= (154) {
            courseVC?.lectureBoxSize(reduced: true)
        }
    }
    
    // MARK: - Page Controller Delegate methods
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        switch identifier {
        case "schedulerPage":
            return schedulerVC
        case "semesterPage":
            return semesterVC
        case "coursePage":
            return courseVC
        default:
            return semesterVC
        }
    }
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
        
//        let ind = pageController.selectedIndex
//        let objs = pageController.arrangedObjects
        
        switch pageController.selectedIndex {
        case SBSchedulerIndex:
//            guard let vc = objs[ind] as? SchedulerPageViewController else { break }
            // setup vc
            break
        case SBSemesterIndex:
//            guard let vc = objs[ind] as? SemesterPageViewController else { break }
            // setup vc
            break
        case SBCourseIndex:
//            guard let vc = objs[ind] as? CoursePageViewController else { break }
            // setup vc
            break
        default:
            break
        }
    }
    
    /// Override swiping forward.
    override func scrollWheel(with event: NSEvent) {
        if event.deltaX > 0 {
            super.scrollWheel(with: event)
        }
    }
}
