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
    @IBOutlet weak var splitView_sidebar: NSView!
    @IBOutlet weak var splitView_content: NSView!
    
    // Children controllers
    var sidebarPageController: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSApp.keyWindow?.makeFirstResponder(self)
        NSApp.keyWindow?.initialFirstResponder = self.view
        
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
//        for case let lectureEditorVC as LectureEditorViewController in self.childViewControllers {
//            self.lectureEditorVC = lectureEditorVC
//            lectureEditorVC.masterVC = self
//        }
        
        // Listen for window resizes
        NotificationCenter.default.addObserver(self, selector: #selector(checkMagnetRegion), name: .NSWindowDidResize, object: self.view.window!)
        
        // Listen for sidebar resizes
//        NotificationCenter.default.addObserver(self, selector: #selector(checkMagnetRegion), name: .split, object: self.view.window!)
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
    @IBOutlet weak var prefToggle: NSButton!
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
            pref.view.frame = splitView_content.frame
            pref.view.widthAnchor.constraint(equalTo: splitView_content.widthAnchor).isActive = true
            pref.view.topAnchor.constraint(equalTo: splitView_content.topAnchor).isActive = true
            pref.view.bottomAnchor.constraint(equalTo: splitView_content.bottomAnchor).isActive = true
            prefTrailingAnchor = pref.view.trailingAnchor.constraint(equalTo: splitView_content.trailingAnchor, constant: splitView_content.frame.width)
            prefTrailingAnchor.isActive = true
            
            prefNav = PreferencesNavViewController(nibName: "PreferencesNavView", bundle: nil)!
            self.addChildViewController(prefNav)
            splitView_sidebar.addSubview(prefNav.view)
            prefNav.view.frame = splitView_sidebar.frame
            prefNav.view.widthAnchor.constraint(equalToConstant: prefNav.view.frame.width).isActive = true
            prefNav.view.topAnchor.constraint(equalTo: splitView_sidebar.topAnchor, constant: 29).isActive = true
            prefNav.view.bottomAnchor.constraint(equalTo: splitView_sidebar.bottomAnchor).isActive = true
            prefNavLeadingAnchor = prefNav.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -splitView_sidebar.frame.width)
            prefNavLeadingAnchor.isActive = true
            prefNav.preferencesVC = pref
            
            // Animate the box to reveal it since its initially off-screen (and fade stuff behind it)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            NSAnimationContext.current().completionHandler = {
                self.editSemesterButton.isEnabled = false
                self.prefToggle.isEnabled = true
            }
            prefNavLeadingAnchor.animator().constant = 0
            prefTrailingAnchor.animator().constant = 0
            editSemesterButton.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func action_preferencesToggle(_ sender: NSButton) {
        prefToggle.isEnabled = false
        // Toggle between hiding and showing preference views
        if prefNav == nil {
            displayPreferences()
        } else {
            self.editSemesterButton.isEnabled = true
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            NSAnimationContext.current().completionHandler = {
                self.prefToggle.isEnabled = true
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
//                if self.editorViewController != nil {
//                    self.editorViewController.loadPreferences()
//                    self.editorViewController.collectionView.collectionViewLayout?.invalidateLayout()
//                }
                self.sidebarPageController.loadPreferences()
                self.sidebarPageController.selectedSemester.validateSchedule()
                self.sidebarPageController.notifyTimeSlotChange()
            }
            prefNavLeadingAnchor.animator().constant = -splitView_sidebar.frame.width
            prefTrailingAnchor.animator().constant = splitView_content.frame.width
            editSemesterButton.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: ––– Scheduler Visuals –––
    
    @IBOutlet weak var semesterLabel: NSTextField!
    @IBOutlet weak var scheduleBox: HXScheduleBox!
    
    // The following references are all used to adjust the scheduler
    // beyond its default bounds. Allowing it to only show Saturday or
    // Sunday if a time slot is on that day or shifting its start/end time
    // of day if necessary.
    @IBOutlet weak var dayLabelStack: NSStackView!
    @IBOutlet weak var verticalLineStack: NSStackView!
    @IBOutlet weak var timeLabelStack: NSStackView!
    @IBOutlet weak var horizontalLineStack: NSStackView!
    
    var sundayLabel: NSTextField!
    var saturdayLabel: NSTextField!
    var prefixedTimeLabels = [NSTextField]()
    var suffixedTimeLabels = [NSTextField]()
    
    private var displaySunday = false {
        didSet {
            if oldValue == displaySunday || !displaySunday {
                return
            }
            sundayLabel = NSTextField(labelWithString: "Sunday")
            sundayLabel.alignment = NSTextAlignment.center
            sundayLabel.textColor = NSColor.gray
            dayLabelStack.insertArrangedSubview(sundayLabel, at: 0)
            let newLine = NSBox()
            newLine.boxType = NSBoxType.separator
            newLine.frame = NSMakeRect(0, 0, 0, 100)
            verticalLineStack.addArrangedSubview(newLine)
        }
    }
    private var displaySaturday = false {
        didSet {
            if oldValue == displaySaturday || !displaySaturday {
                return
            }
            saturdayLabel = NSTextField(labelWithString: "Saturday")
            saturdayLabel.alignment = NSTextAlignment.center
            saturdayLabel.textColor = NSColor.gray
            dayLabelStack.addArrangedSubview(saturdayLabel)
            let newLine = NSBox()
            newLine.boxType = NSBoxType.separator
            newLine.frame = NSMakeRect(0, 0, 0, 100)
            verticalLineStack.addArrangedSubview(newLine)
        }
    }
    private let DEFAULT_EARLIEST = 480 // 8:00A
    private let DEFAULT_LATEST = 1319 // 9:59P
    private var earliestTime = 480 {
        didSet {
            if earliestTime == DEFAULT_EARLIEST {
                for v in prefixedTimeLabels {
                    v.removeFromSuperview()
                    horizontalLineStack.arrangedSubviews.last!.removeFromSuperview()
                }
                prefixedTimeLabels = [NSTextField]()
                return
            }
            let defaultHour = Int(DEFAULT_EARLIEST/60)
            while prefixedTimeLabels.count != defaultHour - Int(earliestTime/60) {
                
                let newLine = NSBox()
                newLine.boxType = NSBoxType.separator
                newLine.frame = NSMakeRect(0, 0, 100, 0)
                horizontalLineStack.addArrangedSubview(newLine)
                
                let newLabel = NSTextField(labelWithString: "\(HXTimeFormatter.formatHour(defaultHour - prefixedTimeLabels.count - 1)):00")
                newLabel.textColor = NSColor.lightGray
                newLabel.setContentHuggingPriority(NSLayoutPriority(100), for: .vertical)
                timeLabelStack.insertArrangedSubview(newLabel, at: 0)
                prefixedTimeLabels.append(newLabel)
            }
        }
    }
    private var latestTime = 1319 {
        didSet {
            print("latestTime: \(latestTime)")
            if latestTime == DEFAULT_LATEST {
                for v in suffixedTimeLabels {
                    v.removeFromSuperview()
                    horizontalLineStack.arrangedSubviews.last!.removeFromSuperview()
                }
                suffixedTimeLabels = [NSTextField]()
                return
            }
            let defaultHour = Int(DEFAULT_LATEST/60)
            while suffixedTimeLabels.count != Int(latestTime/60) - defaultHour {
                
                let newLine = NSBox()
                newLine.boxType = NSBoxType.separator
                newLine.frame = NSMakeRect(0, 0, 100, 0)
                horizontalLineStack.addArrangedSubview(newLine)
                
                let newLabel = NSTextField(labelWithString: "\(HXTimeFormatter.formatHour(1 + defaultHour + suffixedTimeLabels.count)):00")
                newLabel.textColor = NSColor.lightGray
                newLabel.setContentHuggingPriority(NSLayoutPriority(100), for: .vertical)
                timeLabelStack.addArrangedSubview(newLabel)
                suffixedTimeLabels.append(newLabel)
            }
        }
    }
    
    /// This flushes the HXScheduleBox's timeSlotVisuals array and reloads
    /// all timeSlots in the currently selected semester.
    private func reloadScheduler() {
        
        displaySunday = false
        displaySaturday = false
        earliestTime = DEFAULT_EARLIEST
        latestTime = DEFAULT_LATEST
        scheduleBox.clearTimeSlotVisuals()
        if saturdayLabel != nil {
            saturdayLabel.removeFromSuperview()
        }
        if sundayLabel != nil {
            sundayLabel.removeFromSuperview()
        }
        while verticalLineStack.arrangedSubviews.count > 6 {
            verticalLineStack.arrangedSubviews.last!.removeFromSuperview()
        }
        
        
        for case let course as Course in sidebarPageController.selectedSemester.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                
                let start = Int(timeSlot.startMinute)
                let stop = Int(timeSlot.stopMinute)
                
                // Extend the scheduler outside its normal bounds if required
                if start < earliestTime {
                    earliestTime = Int(start / 60) * 60
                }
                if stop > latestTime {
                    latestTime = Int(stop / 60 + 1) * 60 - 1
                }
                if timeSlot.weekday == 1 {
                    displaySunday = true
                }
                if timeSlot.weekday == 7 {
                    displaySaturday = true
                }
                
                scheduleBox.addTimeSlotVisual(timeSlot)
            }
        }
        scheduleBox.needsDisplay = true
    }
    
    // MARK: ––– Lecture Editing Visuals –––
    
    /// Prevent user from clicking too fast and causing animations glitches
    private var lectureEditorRunningDisplay = false
    
    private var lectureEditorVC: LectureEditorViewController!
    
    private func displayLectureEditor(for lecture: Lecture) {
        
        if lectureEditorVC != nil {
            lectureEditorVC.notifySelected(lecture: lecture)
            return
        }
        
        lectureEditorVC = LectureEditorViewController(nibName: "LectureEditor", bundle: nil)!
        self.addChildViewController(lectureEditorVC)
        splitView_content.addSubview(lectureEditorVC.view)
        lectureEditorVC.view.frame = splitView_content.bounds
        lectureEditorVC.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        lectureEditorVC.masterVC = self
        
    }
    
    private func hideLectureEditor() {
        if lectureEditorVC == nil || lectureEditorRunningDisplay {
            return
        }
        
        lectureEditorRunningDisplay = true
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.25
        NSAnimationContext.current().completionHandler = {
            self.lectureEditorVC.view.removeFromSuperview()
            self.lectureEditorVC.removeFromParentViewController()
            self.lectureEditorVC = nil
            self.lectureEditorRunningDisplay = false
        }
        lectureEditorVC.backdropBox.animator().alphaValue = 0
        lectureEditorVC.overlayTopConstraint.animator().constant = -splitView_content.frame.height
        NSAnimationContext.endGrouping()
    }
    
//    private func push
    
    
//    private func pushScheduler(semester: Semester) {
//        print("push")
//        schedulerViewController = SchedulerViewController(nibName: "HXScheduler", bundle: nil)!
//        self.addChildViewController(schedulerViewController)
//        splitView_content.addSubview(schedulerViewController.view)
//        schedulerViewController.view.frame = splitView_content.bounds
//        schedulerViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
//        schedulerViewController.initialize(with: semester)
//    }
    
    // MARK: ––– Sidebar Visuals ––– 
    
    @IBOutlet weak var editSemesterButton: NSButton!
    
    @IBAction func action_sidebarMode(_ sender: NSButton) {
        if sender.state == NSOnState {
            sidebarPageController.notifyScheduling(is: false)
            editSemesterButton.state = NSOnState
        } else {
            sidebarPageController.notifyScheduling(is: true)
            editSemesterButton.state = NSOffState
        }
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
                let semester = Semester.produceSemester(titled: "spring", in: Int(yearLabel.stringValue)!)
                sidebarPageController.notifySelected(semester: semester)
            } else {
                let semester = Semester.produceSemester(titled: "fall", in: Int(yearLabel.stringValue)!)
                self.sidebarPageController.notifySelected(semester: semester)
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
            notiftySelected(semester: "Fall \(self.yearLabel.stringValue)")
        } else {
            self.semesterButtonAnimated.title = "Spring"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
            notiftySelected(semester: "Spring \(Int(self.yearLabel.stringValue)! + 1)")
            yrButtonAnimBotConstraint.constant = -30
        }
        
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
            notiftySelected(semester: "Spring \(self.yearLabel.stringValue)")
        } else {
            self.semesterButtonAnimated.title = "Fall"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
            notiftySelected(semester: "Fall \(Int(self.yearLabel.stringValue)! - 1)")
        }
        
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
    
    // MARK: ––– Window Magnet Functionality –––
    
    /// Performed as Window is being resized.
    func checkMagnetRegion() {
        
        if lectureEditorVC == nil || !self.view.window!.inLiveResize {
            return
        }
        
        let sidebarWidth = sidebarPageController.view.frame.width
        let windowWidth = self.view.window!.frame.width
        let mouseX = self.view.window!.mouseLocationOutsideOfEventStream.x
        
        let MAX_LECTURE_EDITOR_WIDTH: CGFloat = 800
        let MAGNET_REGION: CGFloat = 30
        
        if windowWidth >= (MAX_LECTURE_EDITOR_WIDTH + sidebarWidth) {
            
            if mouseX >= MAX_LECTURE_EDITOR_WIDTH + sidebarWidth + MAGNET_REGION {
                self.view.window!.setContentSize(NSSize(width: mouseX, height: self.view.frame.height))
            } else {
                self.view.window!.setContentSize(NSSize(width: MAX_LECTURE_EDITOR_WIDTH + sidebarWidth, height: self.view.frame.height))
            }
        }
    }
    
    // MARK: ––– Notifiers –––
    
    ///
    func notiftySelected(semester: String) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            self.semesterLabel.stringValue = semester
            self.semesterLabel.animator().alphaValue = 1
        }
        semesterLabel.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }
    
    /// Request the MasterVC tell the LectureEditorVC that a new
    /// lecture has been selected for editing.
    func notifySelected(lecture: Lecture?) {
        
        if lecture == nil {
            hideLectureEditor()
        } else {
            displayLectureEditor(for: lecture!)
        }
        
    }
    
    /// Inform the MasterVC that the selected semester is now
    /// being scheduled or not scheduled.
//    func notifySelected(semester: Semester, is scheduling: Bool) {
//        
//        print("notifySelected: MASTERVC \(scheduling)")
//        
//        if scheduling {
//            
//            editSemesterButton.state = NSOffState
//            
//            lectureEditorVC.notifySelected(lecture: nil)
//            
//            if schedulerViewController == nil {
//                pushScheduler(semester: semester)
//            } else {
//                schedulerViewController.initialize(with: semester)
//            }
//            
//        } else {
//            
//            editSemesterButton.state = NSOnState
//            
//            popScheduler()
//        }
//    }
    
    ///
    func notifyRenamed(lecture: Lecture) {
        sidebarPageController.notifyRenamed(lecture: lecture)
    }
    
//    /// Notify the MasterVC that the semester being scheduled is invalid
//    /// and to update UI to prevent user from leaving the scheduler until rectified.
//    func notifyInvalidSemester() {
//        editSemesterButton.isEnabled = false
//    }
//    
//    /// Notify the MasterVC that the semester being scheduled is valid
//    /// and it should update UI to allow user to leave the scheduler.
//    func notifyValidSemester() {
//        editSemesterButton.isEnabled = true
//    }
    
    /// Inform the MasterVC to tell scheduler that there have been time slot changes.
    /// This could include changing, creating, or delete time slots - sometimes from
    /// a course being deleted.
    func notifyTimeSlotChange() {
//        schedulerViewController.notifyTimeSlotChange()
        reloadScheduler()
        
    }
    
    /// Notify MasterViewController that a course has been selected or deselected.
    /// Passes on course selection to EditorViewController
//    func notifyCourseSelection(course: Course?) {
//        if editorViewController != nil {
//            editorViewController.selectedCourse = course
//        }
//    }

    /// Notify MasterViewController that a course has been renamed.
    /// Currently used to reload the label titles on time slots in the Calendar.
//    func notifyCourseRename(from oldName: String) {
////        calendarViewController.reloadTimeslotTitles(named: oldName)
//    }
    /// From EditorVC to SidebarVC
//    func notifyLectureFocus(is lectureCVI: LectureCollectionViewItem?) {
//        if lectureCVI == nil {
////            sidebarViewController.focus(lecture: nil)
//        } else {
////            sidebarViewController.focus(lecture: lectureCVI!.lecture)
//        }
//    }
    /// from SidebarVC to EditorVC
//    func notifyLectureSelection(lecture: String) {
//        editorViewController.notifyLectureSelection(lecture: lecture)
//    }
    ///
//    func notifyLectureAddition(lecture: Lecture) {
//        editorViewController.notifyLectureAddition(lecture: lecture)
//    }
    
    ///
    func notifyExport() {
//        if editorViewController != nil {
//            editorViewController.notifyExport()
//        }
    }
    ///
    func notifyPrint() {
//        if editorViewController != nil {
//            editorViewController.notifyPrint()
//        }
    }
    ///
    func notifyFind() {
//        if editorViewController != nil {
//            editorViewController.notifyFind()
//        }
    }
    ///
    func notifyFindAndReplace() {
//        if editorViewController != nil {
//            editorViewController.notifyFindAndReplace()
//        }
    }
}
