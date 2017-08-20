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
    @IBOutlet weak var splitView_sidebar: NSView!
    @IBOutlet weak var sidebarBGBox: VisualEffectView!
    
    // Children controllers
    var sidebarPageController: SidebarPageController!
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
        
        for case let sidebarPC as SidebarPageController in self.childViewControllers {
            self.sidebarPageController = sidebarPC
            sidebarPC.masterVC = self
        }
        
//        var recoloredText = NSMutableAttributedString(attributedString: semesterButton.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.red, range: NSMakeRange(0,semesterButton.attributedTitle.length))
//        semesterButton.attributedTitle = recoloredText
//        
//        recoloredText = NSMutableAttributedString(attributedString: semesterButtonAnimated.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.red, range: NSMakeRange(0,semesterButtonAnimated.attributedTitle.length))
//        semesterButtonAnimated.attributedTitle = recoloredText
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        var course = ""
        if self.sidebarPageController.selectedCourse == nil {
            course = "nil"
        } else {
            course = self.sidebarPageController.selectedCourse.title!
        }
        
        let key = semesterButton.title.uppercased() + ":" + yearLabel.stringValue + ":" + course
        
        CFPreferencesSetAppValue(NSString(string: "previouslyOpenedCourse"),NSString(string: key), kCFPreferencesCurrentApplication)
        
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    // MARK: - ––– Preferences –––
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
            splitView_sidebar.addSubview(prefNav.view)
            prefNav.view.frame = splitView_sidebar.frame
            prefNav.view.widthAnchor.constraint(equalToConstant: prefNav.view.frame.width).isActive = true
            prefNav.view.topAnchor.constraint(equalTo: splitView_sidebar.topAnchor, constant: 30).isActive = true
            prefNav.view.bottomAnchor.constraint(equalTo: splitView_sidebar.bottomAnchor).isActive = true
            prefNavLeadingAnchor = prefNav.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -sidebarBGBox.frame.width)
            prefNavLeadingAnchor.isActive = true
            prefNav.preferencesVC = pref
            
            // Animate the box to reveal it since its initially off-screen (and fade stuff behind it)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            NSAnimationContext.current().completionHandler = {
                self.editSemesterButton.isEnabled = false
            }
            prefNavLeadingAnchor.animator().constant = 0
            prefTrailingAnchor.animator().constant = 0
            editSemesterButton.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func action_preferencesToggle(_ sender: NSButton) {
        // Toggle between hiding and showing preference views
        if prefNav == nil {
            displayPreferences()
        } else {
            self.editSemesterButton.isEnabled = true
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
                self.sidebarPageController.selectedSemester.validateSchedule()
                self.sidebarPageController.notifyTimeSlotChange()
            }
            prefNavLeadingAnchor.animator().constant = -sidebarBGBox.frame.width
            prefTrailingAnchor.animator().constant = container_content.frame.width
            editSemesterButton.animator().alphaValue = 1
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
    
    @IBOutlet weak var editSemesterButton: NSButton!
    
    @IBAction func action_sidebarMode(_ sender: NSButton) {
        if sender.state == NSOnState {
            sidebarPageController.scheduling = false
        } else {
            sidebarPageController.scheduling = true
        }
    }
    
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
    
    // MARK: ––– Semester Selection –––
    
    @IBOutlet weak var semesterButton: NSButton!
    @IBOutlet weak var semButtonBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var semesterButtonAnimated: NSButton!
    @IBOutlet weak var semButtonAnimBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearLabel: NSTextField!
    @IBOutlet weak var yearLabelAnimated: NSTextField!
    @IBOutlet weak var yrButtonBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var yrButtonAnimBotConstraint: NSLayoutConstraint!
    
    func updateDate() {
        if let yr = Int(yearLabel.stringValue) {
            lastYearUsed = yr
        } else {
            yearLabel.stringValue = "\(lastYearUsed)"
        }
        
        if Int(yearLabel.stringValue) != nil {
            if semesterButton.title == "Spring" {
                self.sidebarPageController.selectedSemester = Semester.produceSemester(titled: "spring", in: Int(yearLabel.stringValue)!)
            } else {
                self.sidebarPageController.selectedSemester = Semester.produceSemester(titled: "fall", in: Int(yearLabel.stringValue)!)
            }
        }
    }
    func setDate(semester: Semester) {
        lastYearUsed = Int(semester.year)
        yearLabel.stringValue = "\(lastYearUsed)"
        self.sidebarPageController.selectedSemester = semester
        
        semesterButton.title = self.sidebarPageController.selectedSemester.title!.capitalized
    }
    
    var lastYearUsed = 0
    @IBAction func action_incrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        sidebarPageController.navigateBack(self)
        
        semButtonAnimBotConstraint.constant = -30
        if self.semesterButton.title == "Spring" {
            self.semesterButtonAnimated.title = "Fall"
        } else {
            self.semesterButtonAnimated.title = "Spring"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
            yrButtonAnimBotConstraint.constant = -30
        }
//        let recoloredText = NSMutableAttributedString(attributedString: self.semesterButtonAnimated.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButtonAnimated.attributedTitle.length))
//        self.semesterButtonAnimated.attributedTitle = recoloredText
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            if self.semesterButton.title == "Spring" {
                self.semesterButton.title = "Fall"
            } else {
                self.semesterButton.title = "Spring"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
                self.yrButtonBotConstraint.constant = 0
            }
//            let recoloredText = NSMutableAttributedString(attributedString: self.semesterButton.attributedTitle)
//            recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButton.attributedTitle.length))
//            self.semesterButton.attributedTitle = recoloredText
            self.semButtonBotConstraint.constant = 0
            self.updateDate()
            sender.isEnabled = true
        }
        self.semButtonBotConstraint.animator().constant = -semesterButton.frame.height
        if self.semesterButton.title == "Fall" {
            self.yrButtonBotConstraint.animator().constant = semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_decrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        sidebarPageController.navigateBack(self)
        
        semButtonAnimBotConstraint.constant = 30
        yrButtonAnimBotConstraint.constant = 30
        if self.semesterButton.title == "Fall" {
            self.semesterButtonAnimated.title = "Spring"
        } else {
            self.semesterButtonAnimated.title = "Fall"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
        }
//        let recoloredText = NSMutableAttributedString(attributedString: self.semesterButtonAnimated.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButtonAnimated.attributedTitle.length))
//        self.semesterButtonAnimated.attributedTitle = recoloredText
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            if self.semesterButton.title == "Fall" {
                self.semesterButton.title = "Spring"
                
            } else {
                self.semesterButton.title = "Fall"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
                self.yrButtonBotConstraint.constant = 0
            }
//            let recoloredText = NSMutableAttributedString(attributedString: self.semesterButton.attributedTitle)
//            recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButton.attributedTitle.length))
//            self.semesterButton.attributedTitle = recoloredText
            self.semButtonBotConstraint.constant = 0
            self.updateDate()
            sender.isEnabled = true
        }
        self.semButtonBotConstraint.animator().constant = semesterButton.frame.height
        if self.semesterButton.title == "Spring" {
            self.yrButtonBotConstraint.animator().constant = -semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    
    @IBAction func action_semesterButton(_ sender: NSButton) {
        if semesterButton.title == "Fall" {
            action_decrementTime(sender)
        } else {
            action_incrementTime(sender)
        }
    }
    @IBAction func action_editYear(_ sender: Any) {
        NSApp.keyWindow?.makeFirstResponder(self)
        updateDate()
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
    /// From EditorVC to SidebarVC
    func notifyLectureFocus(is lectureCVI: LectureCollectionViewItem?) {
        if lectureCVI == nil {
//            sidebarViewController.focus(lecture: nil)
        } else {
//            sidebarViewController.focus(lecture: lectureCVI!.lecture)
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
    func notifySemester(_ semester: Semester, is scheduling: Bool) {
        if scheduling {
            
            if schedulerViewController == nil {
                // Only push a new calendar if the editor is showing.
                popEditor()
                pushCalendar(semester: semester)
            } else {
                schedulerViewController.initialize(with: semester)
                schedulerViewController.notifyTimeSlotChange()
            }
            
        } else {
            
            if editorViewController == nil {
                // Only push a new editor if the calendar is showing.
                popCalendar()
                pushEditor()
                
            } else {
                editorViewController.selectedCourse = nil
            }
            
        }
    }
    ///
    func notifyTimeSlotChange() {
        if schedulerViewController != nil {
            schedulerViewController.notifyTimeSlotChange()
        }
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
    ///
    func notifyInvalidSemester() {
        editSemesterButton.isEnabled = false
    }
    ///
    func notifyValidSemester() {
        editSemesterButton.isEnabled = true
    }
}
