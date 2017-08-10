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
//        sidebarBGBox.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
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
        
        var noPrev = true
        if let prevOpenCourse = CFPreferencesCopyAppValue(NSString(string: "previouslyOpenedCourse"), kCFPreferencesCurrentApplication) as? String {
            if prevOpenCourse != "nil" {
                let parseSem = prevOpenCourse.substring(to: (prevOpenCourse.range(of: ":")?.lowerBound)!)
                let remain = prevOpenCourse.substring(from: (prevOpenCourse.range(of: ":")?.upperBound)!)
                let parseYr = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseCourse = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                
                let semester = Semester.produceSemester(titled: parseSem.lowercased(), in: Int(parseYr)!)
                noPrev = false
                sidebarViewController.setDate(semester: semester)
                
                if parseCourse != "nil" {
                    sidebarViewController.selectedCourse = semester.retrieveCourse(named: parseCourse)
                }
            }
        }
        
        if noPrev {
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
    }
    
    // MARK: - ––– Preferences –––
    @IBOutlet weak var preferencesButton: NSButton!
    var prefNav: PreferencesNavViewController!
    var prefNavLeadingAnchor: NSLayoutConstraint!
    var pref: PreferencesViewController!
    var prefTrailingAnchor: NSLayoutConstraint!
    
    /// Creates a new PreferencesVC and PreferencesNavVC and adds their views to MasterVC as well as animates
    /// the addition and hiding of appropriate views.
    func displayPreferences() {
        // Prevent more than one preferences view from being created.
        if prefNav == nil {
            
            pref = PreferencesViewController(nibName: "PreferencesView", bundle: nil)!
            self.addChildViewController(pref)
            self.view.addSubview(pref.view)
            pref.view.frame = container_content.frame
            pref.view.widthAnchor.constraint(equalTo: container_content.widthAnchor).isActive = true
            pref.view.topAnchor.constraint(equalTo: container_content.topAnchor).isActive = true
            pref.view.bottomAnchor.constraint(equalTo: container_content.bottomAnchor).isActive = true
            prefTrailingAnchor = pref.view.trailingAnchor.constraint(equalTo: container_content.trailingAnchor, constant: container_content.frame.width)
            prefTrailingAnchor.isActive = true
            
            prefNav = PreferencesNavViewController(nibName: "PreferencesNavView", bundle: nil)!
            self.addChildViewController(prefNav)
            self.view.addSubview(prefNav.view)
            prefNav.view.frame = sidebarBGBox.frame
            prefNav.view.widthAnchor.constraint(equalToConstant: prefNav.view.frame.width).isActive = true
            prefNav.view.topAnchor.constraint(equalTo: container_sideBar.topAnchor).isActive = true
            prefNav.view.bottomAnchor.constraint(equalTo: container_sideBar.bottomAnchor).isActive = true
            prefNavLeadingAnchor = prefNav.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -sidebarBGBox.frame.width)
            prefNavLeadingAnchor.isActive = true
            prefNav.preferencesVC = pref
            
            // Update button
            preferencesButton.image = #imageLiteral(resourceName: "icon_drawer")
            
            // Animate the box to reveal it since its initially off-screen (and fade stuff behind it)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            NSAnimationContext.current().completionHandler = {
                self.container_sideBar.isHidden = true
                self.container_sideBar.alphaValue = 1
            }
            prefNavLeadingAnchor.animator().constant = 0
            prefTrailingAnchor.animator().constant = 0
            container_sideBar.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func action_preferencesToggle(_ sender: NSButton) {
        // Toggle between hiding and showing preference views
        if prefNav == nil {
            displayPreferences()
        } else {
            // Update button
            preferencesButton.image = #imageLiteral(resourceName: "icon_settings")
            
            // Recall hidden stuff. Slide away the preferences view, then remove it.
            container_sideBar.alphaValue = 0
            container_sideBar.isHidden = false
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            NSAnimationContext.current().completionHandler = {
                if self.prefNav != nil {
                    self.prefNav.view.removeFromSuperview()
                    self.prefNav.removeFromParentViewController()
                    
                    self.pref.view.removeFromSuperview()
                    self.pref.removeFromParentViewController()
                    
                    self.prefNav = nil
                    self.prefNavLeadingAnchor = nil
                    
                    self.pref = nil
                    self.prefTrailingAnchor = nil
                }
                if self.editorViewController != nil {
                    self.editorViewController.loadPreferences()
                    self.editorViewController.collectionView.collectionViewLayout?.invalidateLayout()
                }
                if self.schedulerViewController != nil {
                    self.sidebarViewController.selectedSemester.validateSchedule()
                    self.sidebarViewController.notifyTimeSlotChange()
                } else {
                    // Check if the preference changes invalidated any time slots
                    if !self.sidebarViewController.selectedSemester.validateSchedule() {
                        print("Not valid!")
                        self.sidebarViewController.selectedSemester = self.sidebarViewController.selectedSemester
                    }
                }
            }
            prefNavLeadingAnchor.animator().constant = -sidebarBGBox.frame.width
            prefTrailingAnchor.animator().constant = container_content.frame.width
            container_sideBar.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
        }
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
        if editorViewController != nil {
            editorViewController.selectedCourse = course
        }
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
    func notifyLectureFocus(is lectureCVI: LectureCollectionViewItem?) {
        if lectureCVI == nil {
            sidebarViewController.focus(lecture: nil)
        } else {
            sidebarViewController.focus(lecture: lectureCVI!.lecture)
        }
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
