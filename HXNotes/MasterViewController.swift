//
//  MasterViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/24/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Darwin

class MasterViewController: NSViewController {
    
    // MARK: View references
    @IBOutlet weak var container_content: NSView!
    @IBOutlet weak var container_sideBar: NSView!
    @IBOutlet weak var sidebarBGBox: VisualEffectView!
    
    // Children controllers
    var sidebarViewController: SidebarViewController!
    // The following 2 controllers fill container_content as is needed
//    private var calendarViewController: CalendarViewController!
    private var schedulerViewController: SchedulerViewController!
    var editorViewController: EditorViewController!
    
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox = HXCourseDragBox.instance()
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSApp.keyWindow?.makeFirstResponder(self)
        NSApp.keyWindow?.initialFirstResponder = self.view
        
        sidebarBGBox.state = .active
        sidebarBGBox.blendingMode = .behindWindow
        sidebarBGBox.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        sidebarBGBox.material = .appearanceBased
        
        Alert.masterViewController = self
        
        view.wantsLayer = true
        
        AppDelegate.scheduleAssistant = ScheduleAssistant(masterController: self)
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        for case let sidebarVC as SidebarViewController in self.childViewControllers {
            self.sidebarViewController = sidebarVC
            self.sidebarViewController.masterViewController = self
        }
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        // Set the current semester displayed in the SidebarVC - might want to remeber last selected semester
        sidebarViewController.setDate(semester: Semester.produceSemester(titled: semesterTitle, in: yearComponent))
    }
    
    // MARK: ––– Populating Content Container –––
    
    private func pushCalendar(semester: Semester) {

        schedulerViewController = SchedulerViewController(nibName: "HXScheduler", bundle: nil)!
        self.addChildViewController(schedulerViewController)
        container_content.addSubview(schedulerViewController.view)
        schedulerViewController.view.frame = container_content.bounds
        schedulerViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        schedulerViewController.initialize(with: semester)
        
    }
    private func pushEditor() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "EditorID") as? EditorViewController {
            editorViewController = newController
            self.addChildViewController(editorViewController)
            editorViewController.masterViewController = self
            container_content.addSubview(editorViewController.view)
            editorViewController.view.frame = container_content.bounds
            editorViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        }
    }
    private func popCalendar() {
        if schedulerViewController != nil {
            if schedulerViewController.view.superview != nil {
                schedulerViewController.view.removeFromSuperview()
                schedulerViewController.removeFromParentViewController()
                schedulerViewController = nil
            }
        }
    }
    private func popEditor() {
        if editorViewController != nil {
            if editorViewController.view.superview != nil {
                editorViewController.view.removeFromSuperview()
                editorViewController.removeFromParentViewController()
                editorViewController = nil
            }
        }
    }
    
    // MARK: ––– Sidebar Visuals ––– 
    
    func sideBarShown(_ visible: Bool) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        NSAnimationContext.current().duration = 0.25
//        if visible {
//            sidebarConstraintLead.animator().constant = 0
//        } else {
//            sidebarConstraintLead.animator().constant = -container_sideBar.frame.width - 1
//        }
        NSAnimationContext.endGrouping()
    }
    
    @IBAction func sideBarShownToggle(_ sender: NSButton) {
//        if sidebarConstraintLead.constant == 0 {
//            sideBarShown(false)
//        } else {
//            sideBarShown(true)
//        }
    }
    
    // MARK: ––– Notifiers –––
    
    /// Notify MasterViewController that a course has been selected or deselected.
    /// Passes on course selection to EditorViewController
    func notifyCourseSelection(course: Course?) {
        editorViewController.selectedCourse = course
    }
    /// Notify MasterViewController that a course has been removed.
    /// Currently used to remove time slot grid spaces in Calendar.
    func notifyCourseDeletion() {
        if schedulerViewController != nil {
            schedulerViewController.notifyTimeSlotChange()
        }
    }
    /// Notify scheduler of a course being added so it may display proper visuals.
    func notifyCourseAddition() {
        if schedulerViewController != nil {
            schedulerViewController.notifyTimeSlotChange()
        }
    }
    /// Notify MasterViewController that a course has been renamed.
    /// Currently used to reload the label titles on time slots in the Calendar.
    func notifyCourseRename(from oldName: String) {
//        calendarViewController.reloadTimeslotTitles(named: oldName)
    }
    ///
    func notifyCourseDragStart(editBox: HXCourseEditBox, to loc: NSPoint) {
        // Update drag box visuals to match course being dragged
        courseDragBox.updateWithCourse(editBox.course)
        // Add drag box back to the superview
        self.view.addSubview(courseDragBox)
        // Try and move these to dragBox initialize in viewDidLoad()
        courseDragBox.removeConstraints(courseDragBox.constraints)
        dragBoxConstraintLead = courseDragBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: loc.x - editBox.boxDrag.frame.origin.x - editBox.boxDrag.frame.width/2)
        dragBoxConstraintTop = courseDragBox.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.view.bounds.height - loc.y - editBox.boxDrag.frame.origin.y - editBox.boxDrag.frame.height/2)
        dragBoxConstraintLead.isActive = true
        dragBoxConstraintTop.isActive = true
        courseDragBox.widthAnchor.constraint(equalToConstant: editBox.bounds.width + 2).isActive = true
        courseDragBox.heightAnchor.constraint(equalToConstant: editBox.bounds.height + 1).isActive = true
    }
    ///
    func notifyCourseDragMoved(editBox: HXCourseEditBox, to loc: NSPoint) {
        dragBoxConstraintLead.constant = loc.x - editBox.boxDrag.frame.origin.x - editBox.boxDrag.frame.width/2
        dragBoxConstraintTop.constant = self.view.bounds.height - loc.y - editBox.boxDrag.frame.origin.y - editBox.boxDrag.frame.height/2
//        calendarViewController.drag()
    }
    ///
    func notifyCourseDragEnd(course: Course, at loc: NSPoint) {
        self.courseDragBox.removeFromSuperview()
//        calendarViewController.drop(course: course, at: loc)
    }
    /// From EditorVC to SidebarVC
    func notifyLectureFocus(is lecture: Lecture?) {
        sidebarViewController.focus(lecture: lecture)
    }
    /// from SidebarVC to EditorVC
    func notifyLectureSelection(lecture: String) {
        editorViewController.notifyLectureSelection(lecture: lecture)
    }
    ///
    func notifyLectureAddition(lecture: Lecture) {
        editorViewController.notifyLectureAddition(lecture: lecture)
    }
    ///
    func notifySemesterEditing(semester: Semester) {
        if schedulerViewController == nil {
            // Only push a new calendar if the editor is showing.
            popEditor()
            pushCalendar(semester: semester)
        } else {
//            calendarViewController.initialize(with: semester)
        }
    }
    ///
    func notifySemesterViewing(semester: Semester) {
        if editorViewController == nil {
            // Only push a new editor if the calendar is showing.
            popCalendar()
            pushEditor()
        } else {
            editorViewController.selectedCourse = nil
        }
    }
    ///
    func notifyTimeSlotChange() {
        if schedulerViewController != nil {
            schedulerViewController.notifyTimeSlotChange()
        }
    }
    /// 
    func notifyTimeSlotAddition() {
        sidebarViewController.notifyTimeSlotAdded()
    }
    ///
    func notifyTimeSlotDeletion() {
        sidebarViewController.notifyTimeSlotRemoved()
    }
    ///
    func notifyExport() {
        if editorViewController != nil {
            editorViewController.notifyExport()
        }
    }
    ///
    func notifyPrint() {
        if editorViewController != nil {
            editorViewController.notifyPrint()
        }
    }
    ///
    func notifyFind() {
        if editorViewController != nil {
            editorViewController.notifyFind()
        }
    }
    ///
    func notifyFindAndReplace() {
        if editorViewController != nil {
            editorViewController.notifyFindAndReplace()
        }
    }
}
