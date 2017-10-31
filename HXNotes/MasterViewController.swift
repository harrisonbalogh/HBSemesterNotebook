//
//  MasterViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/24/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Darwin

class MasterViewController: NSViewController, NSSplitViewDelegate, SelectionDelegate, SchedulingDelegate, SidebarDelegate, DocumentsDropDelegate {
    
    // MARK: View references
    @IBOutlet weak var splitView_sidebar: NSView!
    @IBOutlet weak var splitView_content: SplitViewContent!
    @IBOutlet weak var splitView: NSSplitView!
    
    // Children controllers
    var sidebarPageController: SidebarPageController!
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        
        var semesterToUse: Semester!
        var courseToUse: Course?
        var lectureToUse: Lecture?

        // Set the current semester displayed in the SidebarVC - might want to remeber last selected semester
        self.semesterToday = Semester.produceSemester(during: Date(), createIfNecessary: true)!
        
        Alert.masterViewController = self
        
        AppDelegate.scheduleAssistant = ScheduleAssistant(masterController: self)
        
        let queueGroup = DispatchGroup()
        queueGroup.enter()
        DispatchQueue.global().async {
            
            let during = self.semesterToday.duringCourse()
            
            // 'launchWithHappeningCourse' preference overrides the preferences to recall last semester/course open when quit
            if AppPreference.launchWithHappeningCourse && during != nil {
                semesterToUse = self.semesterToday
                courseToUse = during!.course!
            } else {
                if AppPreference.openLastSemester {
                    semesterToUse = AppPreference.previouslyOpenedSemester
                    if semesterToUse == nil {
                        semesterToUse = self.semesterToday
                    } else if AppPreference.rememberLastCourse, let course = AppPreference.previouslyOpenedCourse{
                        courseToUse = course
                        if AppPreference.rememberLastLecture, let lecture = AppPreference.previouslyOpenedLecture {
                            lectureToUse = lecture
                        }
                    }
                } else {
                    semesterToUse = self.semesterToday
                }
            }
            queueGroup.leave()
        }
        
        queueGroup.notify(queue: .main, execute: {
            self.setDate(semester: semesterToUse)
            self.selectedCourse = courseToUse
            self.scrollToSemesterVCIfValid()
            if lectureToUse != nil {
                self.displayLectureEditor(for: lectureToUse!)
            }
        })
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        for case let sidebarPC as SidebarPageController in self.childViewControllers {
            sidebarPC.schedulingDelegate = self
            sidebarPC.selectionDelegate = self
            sidebarPC.sidebarDelegate = self
            sidebarPC.documentsDropDelegate = self
            self.sidebarPageController = sidebarPC
            
            scrollToSemesterVCIfValid()
        }
        
        scheduleBox.selectionDelegate = self
        
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()

        AppPreference.previouslyOpenedCourse = selectedCourse
        AppPreference.previouslyOpenedSemester = selectedSemester
        if lectureEditorVC != nil {
            AppPreference.previouslyOpenedLecture = lectureEditorVC.selectedLecture
        } else {
            AppPreference.previouslyOpenedLecture = nil
        }
        
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        
//        Semester.cleanEmptySemesters()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if isSidebarOnly {
            splitView.setPosition(view.frame.width, ofDividerAt: 0)
        }
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
            pref.masterVC = self
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
            prefNav.view.widthAnchor.constraint(equalTo: splitView_sidebar.widthAnchor).isActive = true
            prefNav.view.topAnchor.constraint(equalTo: editBox.topAnchor).isActive = true
            prefNav.view.bottomAnchor.constraint(equalTo: splitView_sidebar.bottomAnchor).isActive = true
            prefNavLeadingAnchor = prefNav.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -splitView_sidebar.frame.width)
            prefNavLeadingAnchor.isActive = true
            prefNav.preferencesVC = pref
            
            // Animate the box to reveal it since its initially off-screen (and fade stuff behind it)
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            prefNavLeadingAnchor.animator().constant = 0
            prefTrailingAnchor.animator().constant = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func action_preferencesToggle(_ sender: NSButton) {
        // Toggle between hiding and showing preference views
        if prefNav == nil {
            displayPreferences()
        } else {
            // Should only do the following if user updated the time slot settings.
            self.schedulingUpdatedTimeSlot()
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
                self.reloadScheduler(with: self.selectedCourse)
            }
            prefNavLeadingAnchor.animator().constant = -splitView_sidebar.frame.width
            prefTrailingAnchor.animator().constant = splitView_content.frame.width
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: ––– Scheduler Visuals –––
    
    @IBOutlet weak var semesterLabel: NSTextField!
    @IBOutlet weak var scheduleBox: HXScheduleBox!
    @IBOutlet weak var schedulerBackgroundBox: NSBox!
    @IBOutlet weak var drawTimeBox: HXTimeDrawingBox!
    
    /// This determines whether or not the PageViewController is on the Semester or
    /// Scheduler page.
    private var isScheduling = true {
        didSet {
            if selectedCourse != nil {
                selectedCourse = nil
            }
        }
    }
    
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
            
            scheduleBox.showSunday = displaySunday
            drawTimeBox.showSunday = displaySunday
            
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
            
            scheduleBox.showSaturday = displaySaturday
            drawTimeBox.showSaturday = displaySaturday
            
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
            
            scheduleBox.earliestTime = earliestTime
            drawTimeBox.earliestTime = earliestTime
            
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
            
            scheduleBox.latestTime = latestTime
            drawTimeBox.latestTime = latestTime
            
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
    private func reloadScheduler(with selection: Course?) {
        
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
        
        
        for case let course as Course in selectedSemester.courses! {
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
                
                if selection == nil {
                    scheduleBox.addTimeSlotVisual(timeSlot, selected: true)
                    continue
                }
                if selection == course {
                    scheduleBox.addTimeSlotVisual(timeSlot, selected: true)
                } else {
                    scheduleBox.addTimeSlotVisual(timeSlot, selected: false)
                }
                
                
            }
        }
        drawTimeBox.notifyDrawsTimeOfDay(AppPreference.showCurrentTime)
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
        lectureEditorVC.selectionDelegate = self
        lectureEditorVC.notifySelected(lecture: lecture)
        
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
    
    // MARK: ––– Sidebar Visuals –––
    
    @IBOutlet weak var editBox: NSBox!
    let DEFAULT_TOP_CONSTRAINT: CGFloat = 22
    @IBOutlet weak var editBoxTopConstraint: NSLayoutConstraint!
    
    func collapseTitlebar() {
        editBoxTopConstraint.constant = 0
        if lectureEditorVC != nil {
            if lectureEditorVC.selectedLecture != nil {
                lectureEditorVC.topBarHeightConstraint.constant = 0
            }
        }
    }
    func revealTitlebar() {
        editBoxTopConstraint.constant = DEFAULT_TOP_CONSTRAINT
        lectureEditorVC.topBarHeightConstraint.constant = DEFAULT_TOP_CONSTRAINT + 1
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
    
    var scrollToSemesterVCIfValidAlreadyRan = false
    func scrollToSemesterVCIfValid() {
        
        // Jump to semester view if schedule is valid.
        if selectedSemester == nil {
            return
        }
        selectedSemester.validateSchedule()
        if selectedSemester.valid && !scrollToSemesterVCIfValidAlreadyRan {
            scrollToSemesterVCIfValidAlreadyRan = true
            sidebarPageController.schedulerVC.isPastSemester = selectedSemester.isEarlier(than: self.semesterToday)
            sidebarPageController.schedulerVC.loadCourses(from: selectedSemester)
            scheduleBox.isHighlighting = true
            
            sidebarPageController.selectedIndex = sidebarPageController.SBSemesterIndex
            
            if selectedCourse != nil {
                sidebarPageController.selectedIndex = sidebarPageController.SBCourseIndex
                if AppPreference.assumeRecentLecture {
                    isEditing(lecture: (selectedCourse.lectures!.lastObject as! Lecture))
                }
                reloadScheduler(with: selectedCourse)
            } else {
                reloadScheduler(with: nil)
            }
        }
    }
    
    /// The current semester displayed in the sidebar. Setting this value will update visuals.
    var selectedSemester: Semester! {
        didSet {
            self.isScheduling = true
            guard let sidebar = sidebarPageController else { return }
            sidebar.selectedIndex = 0
            sidebarSchedulingNeedsPopulating(sidebar.schedulerVC)
        }
    }
    /// The semester currently happening in real time. Initialized at app launch.
    var semesterToday: Semester!
    
    /// Updates MasterVC's selectedSemester as well as various visuals.
    private func setDate(semester: Semester) {
        lastYearUsed = semester.year
        yearLabel.stringValue = "\(lastYearUsed)"
        self.selectedSemester = semester
        
        semesterButton.title = selectedSemester.title!.capitalized
    }
    
    var lastYearUsed = 0
    @IBAction func action_incrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        semButtonAnimBotConstraint.constant = -30
        yrButtonAnimBotConstraint.constant = -30
        
        let nextSemester = selectedSemester.proceeding()
        semesterButtonAnimated.title = nextSemester.title!.capitalized
        yearLabelAnimated.stringValue = "\(nextSemester.year)"
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            self.semesterButton.title = nextSemester.title!.capitalized
            self.yearLabel.stringValue = "\(nextSemester.year)"
            self.yrButtonBotConstraint.constant = 0
            
            self.selectedSemester = nextSemester
            self.semesterLabel.stringValue = self.semesterButton.title + " " + self.yearLabel.stringValue
            self.semButtonBotConstraint.constant = 0
            self.semesterLabel.animator().alphaValue = 1
            self.scheduleBox.animator().alphaValue = 1
            sender.isEnabled = true
        }
        scheduleBox.animator().alphaValue = 0
        semesterLabel.animator().alphaValue = 0
        self.semButtonBotConstraint.animator().constant = -semesterButton.frame.height
        if self.semesterButton.title.lowercased() == "fall" {
            self.yrButtonBotConstraint.animator().constant = semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_decrementTime(_ sender: NSButton) {
        sender.isEnabled = false

        semButtonAnimBotConstraint.constant = 30
        yrButtonAnimBotConstraint.constant = 30
        
        let prevSemester = selectedSemester.preceeding()
        semesterButtonAnimated.title = prevSemester.title!.capitalized
        yearLabelAnimated.stringValue = "\(prevSemester.year)"
 
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            self.semesterButton.title = prevSemester.title!.capitalized
            self.yearLabel.stringValue = "\(prevSemester.year)"
            self.yrButtonBotConstraint.constant = 0
            
            self.selectedSemester = prevSemester
            self.semesterLabel.stringValue = self.semesterButton.title + " " + self.yearLabel.stringValue
            self.semButtonBotConstraint.constant = 0
            self.semesterLabel.animator().alphaValue = 1
            self.scheduleBox.animator().alphaValue = 1
            sender.isEnabled = true
        }
        scheduleBox.animator().alphaValue = 0
        semesterLabel.animator().alphaValue = 0
        self.semButtonBotConstraint.animator().constant = semesterButton.frame.height
        if self.semesterButton.title.lowercased() == "spring" {
            self.yrButtonBotConstraint.animator().constant = -semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    
    @IBAction func action_semesterButton(_ sender: NSButton) {
        if semesterButton.title.lowercased() == "fall" {
            action_decrementTime(sender)
        } else {
            action_incrementTime(sender)
        }
    }
    @IBAction func action_editYear(_ sender: Any) {
        NSApp.keyWindow?.makeFirstResponder(self)
//        updateDate()
    }
    
    // MARK: ––– Notifiers –––
    
    ///
    func notifySave() {
        if lectureEditorVC != nil && lectureEditorVC.selectedLecture != nil {
            lectureEditorVC.selectedLecture.content =
                NSAttributedString(attributedString: lectureEditorVC.textViewContent.attributedString())
        }
        appDelegate.saveAction(self) // Will check if there are changes
    }
    
    ///
    func notifyExport() {
//        if editorViewController != nil {
//            editorViewController.notifyExport()
//        }
        if lectureEditorVC != nil && lectureEditorVC.selectedLecture != nil {
            lectureEditorVC.isExporting = !lectureEditorVC.isExporting
        }
    }
    ///
    func notifyPrint() {
//        if editorViewController != nil {
//            editorViewController.notifyPrint()
//        }
        if lectureEditorVC == nil {
            splitView_content.print(self)            
        } else {
            lectureEditorVC.textViewContent.print(self)
        }
    }
    ///
    func notifyFind() {
//        if editorViewController != nil {
//            editorViewController.notifyFind()
//        }
        if lectureEditorVC != nil && lectureEditorVC.selectedLecture != nil {
            lectureEditorVC.isFinding = !lectureEditorVC.isFinding
        }
    }
    ///
    func notifyFindAndReplace() {
//        if editorViewController != nil {
//            editorViewController.notifyFindAndReplace()
//        }
        if lectureEditorVC != nil && lectureEditorVC.selectedLecture != nil {
            lectureEditorVC.isReplacing = !lectureEditorVC.isReplacing
        }
    }
    
    // MARK: - Course Selection
    
    /// The current course displayed in the sidebar. Setting this value will update visuals.
    var selectedCourse: Course! {
        didSet {
            if selectedCourse != nil {
                selectedCourse.fillAbsentLectures()
            }
        }
    }
    
    // MARK: - SplitView Delegate
    @IBOutlet weak var sidebarOnlyButton: NSButton!
    @IBOutlet weak var splitViewMinWidth: NSLayoutConstraint!
    @IBOutlet weak var splitViewMaxWidth: NSLayoutConstraint!
    @IBOutlet weak var splitViewTrailing: NSLayoutConstraint!
    var viewMinWidthConstraint: NSLayoutConstraint!
    var viewMaxWidthConstraint: NSLayoutConstraint!
    var isSidebarOnly = false {
        didSet {
            if isSidebarOnly == oldValue {
                return
            }
            if isSidebarOnly {

                viewMinWidthConstraint = self.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 150)
                viewMinWidthConstraint.isActive = true
                
                splitViewMaxWidth.constant = splitView.frame.width
                splitViewMinWidth.constant = splitView.frame.width
                splitViewTrailing.isActive = false
                view.window?.setContentSize(NSSize(width: splitView_sidebar.frame.width, height: view.frame.height))

                viewMaxWidthConstraint = self.view.widthAnchor.constraint(lessThanOrEqualToConstant: 350)
                viewMaxWidthConstraint.isActive = true
            } else {
                viewMinWidthConstraint.isActive = false
                viewMaxWidthConstraint.isActive = false
                splitViewMaxWidth.constant = 10000
                
                let mainScreen = NSScreen.main()
                let screenDescrip = mainScreen?.deviceDescription
                let screenSize = screenDescrip?[NSDeviceSize] as! NSSize
                
                // Limits width reset to be within screen bounds
                var adjustedWidth = splitView_sidebar.frame.width + splitView_content.frame.width + 2
                var extra = adjustedWidth + self.view.window!.frame.origin.x - screenSize.width
                adjustedWidth -= max(0, extra)
                
                if adjustedWidth < 600 {
                    adjustedWidth = 600
                    extra = adjustedWidth + self.view.window!.frame.origin.x - screenSize.width
                    if extra > 0 {
                        view.window?.setFrameOrigin(NSPoint(x: (view.window?.frame.origin.x)! - extra, y: (view.window?.frame.origin.y)!))
                    }

                }

                view.window?.setContentSize(NSSize(width: adjustedWidth, height: view.frame.height))
                
                splitViewMinWidth.constant = 600
                splitViewTrailing = splitView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                splitViewTrailing.isActive = true
            }
        }
    }
    
    @IBAction func action_sidebarOnly(_ sender: NSButton) {
        if sender.state == NSOnState {
            isSidebarOnly = true
        } else {
            isSidebarOnly = false
        }
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 150
    }
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 350
    }
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        if subview.identifier == "contentSplit" {
            return false
        }
        return true
    }
    func splitViewDidResizeSubviews(_ notification: Notification) {
        sidebarCollapsed = splitView.isSubviewCollapsed(splitView_sidebar)
    }
    var sidebarCollapsed = false {
        didSet { 
            if sidebarCollapsed {
                appDelegate.sidebarMenuItem.title = "Show Sidebar"
            } else {
                appDelegate.sidebarMenuItem.title = "Hide Sidebar"
            }
        }
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        if view.identifier == "sidebarSplit" {
            return false
        }
        return true
    }
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        return true
    }
    
    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        if isSidebarOnly {
            return NSZeroRect
        }
        return proposedEffectiveRect
    }
    
    // MARK: - Model
    
    /// Creates a new Lecture data object and updates lectureStackView visuals with a new HXLectureBox.
    /// This assumes that an alert called addLecture.
    public func addLecture() {
        
        // Hide the static button
        if selectedCourse != nil {
            sidebarPageController.courseVC.addButton.isHidden = true
            sidebarPageController.courseVC.addButton.isEnabled = false
        }
        
        if let timeSlotHappening = semesterToday.duringCourse() {
            if timeSlotHappening.course!.theoreticalLectureCount() != timeSlotHappening.course!.lectures!.count || timeSlotHappening.course!.theoreticalLectureCount() == 0 {
                if selectedSemester != semesterToday {
                    selectedSemester = semesterToday
                }
                if selectedCourse != timeSlotHappening.course! {
                    selectedCourse = timeSlotHappening.course!
                } else {
                    selectedCourse.fillAbsentLectures()
                }
                
                courseWasSelected(selectedCourse)
                
                Alert.flushAlerts(for: selectedCourse)
                
                // Create new lecture
                timeSlotHappening.course!.createLecture(during: timeSlotHappening.course!.duringTimeSlot()!, on: nil, in: nil, at: nil)
                
                // Displays lecture in the lectureStackView
                sidebarPageController.courseVC.loadLectures(from: selectedCourse)
            } else {
                print("No lectures to add? Theoretical count: \(timeSlotHappening.course!.theoreticalLectureCount())")
            }
        } else {
            // User probably waited too long to accept lecture, so display error
            let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
            let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
            let _ = Alert(hour: hour, minute: minute, course: nil, content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil, type: .custom)
            if selectedCourse != nil {
                selectedCourse.fillAbsentLectures()
            }
        }
    }
    
    // MARK: - Control Flow Delegation
    
    func courseWasSelected(_ course: Course?) {
        selectedCourse = course
        if course != nil {
            if sidebarPageController.selectedIndex == sidebarPageController.SBCourseIndex {
                sidebarCourseNeedsPopulating(sidebarPageController.courseVC)
            } else {
                sidebarPageController.selectedIndex = sidebarPageController.SBCourseIndex
            }
            if AppPreference.assumeRecentLecture {
                isEditing(lecture: (selectedCourse.lectures!.lastObject as! Lecture))
            }
            reloadScheduler(with: selectedCourse)
        } else {
            sidebarPageController.selectedIndex = sidebarPageController.SBSemesterIndex
            scheduleBox.isHighlighting = true
            hideLectureEditor()
            reloadScheduler(with: nil)
        }
        
    }
    
    func workWasSelected(_ work: Work) {
        courseWasSelected(work.course)
    }
    
    func testWasSelected(_ test: Test) {
        courseWasSelected(test.course)
    }
    
    var wasSidebarOnly = false
    func isEditing(lecture: Lecture?) {
        
        // Update visuals for all HXLectureBox's
        for case let lectureBox as CourseLectureBox in sidebarPageController.courseVC.lectureStackView.arrangedSubviews {
            if lectureBox.lecture == lecture {
                lectureBox.updateVisual(selected: true)
            } else {
                lectureBox.updateVisual(selected: false)
            }
        }
        
        if lecture != nil {
            sidebarOnlyButton.isEnabled = false
            scheduleBox.isHighlighting = false
            displayLectureEditor(for: lecture!)
            if isSidebarOnly {
                wasSidebarOnly = true
                isSidebarOnly = false
            }
        } else {
            sidebarOnlyButton.isEnabled = true
            scheduleBox.isHighlighting = true
            hideLectureEditor()
            isSidebarOnly = wasSidebarOnly
            wasSidebarOnly = false
        }
        
    }
    
    
    func isEditing(workBox: CourseWorkBox?) {
        if workBox == nil {
            sidebarPageController.courseVC.closeWorkPopover()
        } else {
            sidebarPageController.courseVC.showWorkPopover(for: workBox!)
        }
    }
    
    func isEditing(testBox: CourseTestBox?) {
        if testBox == nil {
            sidebarPageController.courseVC.closeTestPopover()
        } else {
            sidebarPageController.courseVC.showTestPopover(for: testBox!)
        }
    }
    
    func isExporting(with exportVC: HXExportViewController) {
        guard let lecture = lectureEditorVC.selectedLecture else { return }
        
        exportVC.textField_name.stringValue = lecture.course!.title! + " Lecture \(lecture.number) - \(lecture.course!.semester!.year) \(lecture.course!.semester!.title!.capitalized)"
    }
    
    func isFinding(with findVC: HXFindViewController) {
        
    }
    
    func isReplacing(with replacingVC: HXFindReplaceViewController) {
        
    }
    
    func courseWasHovered(_ course: Course) {
        for case let cBox as SemesterCourseBox in sidebarPageController.semesterVC.courseStackView.arrangedSubviews {
            cBox.hoverVisuals(false)
        }
    }
    
    func lectureWasHovered(_ lecture: Lecture) {
        for case let lBox as CourseLectureBox in sidebarPageController.courseVC.lectureStackView.arrangedSubviews {
            lBox.hoverVisuals(false)
        }
    }
    
    func workWasHovered(_ work: Work) {
        if sidebarPageController.selectedIndex == sidebarPageController.SBSemesterIndex {
            for case let wBox as SemesterWorkBox in sidebarPageController.semesterVC.workStackView.arrangedSubviews {
                wBox.hoverVisuals(false)
            }
        }
    }
    
    func testWasHovered(_ test: Test) {
        if sidebarPageController.selectedIndex == sidebarPageController.SBSemesterIndex {
            for case let tBox as SemesterTestBox in sidebarPageController.semesterVC.testStackView.arrangedSubviews {
                tBox.hoverVisuals(false)
            }
        }
    }
    
    // MARK: - Scheduler Delegation
    
    func schedulingDidFinish() {
        scheduleBox.isHighlighting = true
        if AppPreference.assumeSingleSelection && selectedSemester.courses!.count == 1 {
            selectedCourse = selectedSemester.courses!.firstObject as! Course
            sidebarPageController.selectedIndex = sidebarPageController.SBCourseIndex
        } else {
            sidebarPageController.selectedIndex = sidebarPageController.SBSemesterIndex
        }
    }
    
    func schedulingDidStart() {
        sidebarPageController.selectedIndex = 0
        scheduleBox.isHighlighting = false
//        sidebarPageController.navigateBack(self)
    }
    
    func schedulingNeedsValidation(_ schedulerPVC: SchedulerPageViewController) {
        selectedSemester.needsValidate = true
        schedulerPVC.loadCourses(from: selectedSemester)
        reloadScheduler(with: nil)
    }
    
    func schedulingAddCourse(_ schedulerPVC: SchedulerPageViewController) {
        selectedSemester.createCourse()
        schedulerPVC.loadCourses(from: selectedSemester)
    }
    
    func schedulingAddLecture() {
        if selectedCourse == nil {
            return
        }
        addLecture()
    }
    
    func schedulingAddWork() {
        let newBox = sidebarPageController.courseVC.push(work: selectedCourse.createWork())
        sidebarPageController.courseVC.showWorkPopover(for: newBox)
        sidebarPageController.courseVC.noWorkCheck()
    }
    
    func schedulingAddTest() {
        let newBox = sidebarPageController.courseVC.push(test: selectedCourse.createTest())
        sidebarPageController.courseVC.showTestPopover(for: newBox)
        sidebarPageController.courseVC.noTestsCheck()
    }
    
    func schedulingRenameCourse() {
        reloadScheduler(with: nil)
    }
    
    func schedulingRemove(course: Course) {
        Alert.flushAlerts(for: course)
        // Update model
        appDelegate.managedObjectContext.delete( course )
        appDelegate.saveAction(self)
        selectedSemester.validateSchedule()
        if sidebarPageController.selectedIndex == sidebarPageController.SBSchedulerIndex {
            sidebarPageController.schedulerVC.loadCourses(from: selectedSemester)
        }
        reloadScheduler(with: nil)
    }
    
    func schedulingRemove(timeSlot: TimeSlot) {
        // Update model
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
        selectedSemester.validateSchedule()
        if sidebarPageController.selectedIndex == sidebarPageController.SBSchedulerIndex {
            sidebarPageController.schedulerVC.loadCourses(from: selectedSemester)
        }
        reloadScheduler(with: nil)
    }
    
    func schedulingRemove(workBox: CourseWorkBox) {
        // Update model
        appDelegate.managedObjectContext.delete( workBox.work! )
        appDelegate.saveAction(self)
        // Update visuals
        sidebarPageController.courseVC.pop(workBox: workBox)
    }
    
    func schedulingRemove(testBox: CourseTestBox) {
        // Update model
        appDelegate.managedObjectContext.delete( testBox.test! )
        appDelegate.saveAction(self)
        // Update visuals
        sidebarPageController.courseVC.pop(testBox: testBox)
    }
    
    func schedulingUpdatedTimeSlot() {
        selectedSemester.validateSchedule()
        sidebarPageController.schedulerVC.checkSchedule(for: selectedSemester)
        reloadScheduler(with: nil)
    }
    
    func schedulingReloadScheduler() {
        reloadScheduler(with: nil)
    }
    
    func schedulingUpdatedWork() {
        if selectedCourse == nil || sidebarPageController.selectedIndex != sidebarPageController.SBCourseIndex{
            return
        }
        sidebarPageController.courseVC.loadWork(from: selectedCourse, showingCompleted:
            sidebarPageController.courseVC.toggleCompletedWork.state == NSOnState)
    }
    
    func schedulingUpdateTest() {
        if selectedCourse == nil || sidebarPageController.selectedIndex != sidebarPageController.SBCourseIndex{
            return
        }
        sidebarPageController.courseVC.loadTests(from: selectedCourse, showingCompleted:
            sidebarPageController.courseVC.toggleCompletedTests.state == NSOnState)
    }
    
    func schedulingUpdateStartDate(with start: Date) {
        selectedSemester.start = start
    }
    
    func schedulingUpdateEndDate(with end: Date) {
        selectedSemester.end = end
        
    }
    
    // MARK: - Sidebar Delegation
    
    func sidebarSchedulingNeedsPopulating(_ schedulerPVC: SchedulerPageViewController) {
        if self.semesterToday == nil || self.selectedSemester == nil {
            return
        }
        schedulerPVC.isPastSemester = selectedSemester.isEarlier(than: self.semesterToday)
        schedulerPVC.loadCourses(from: selectedSemester)
        reloadScheduler(with: nil)
    }
    
    func sidebarSemesterNeedsPopulating(_ semesterPVC: SemesterPageViewController) {
        
        semesterPVC.view.alphaValue = 1
        semesterPVC.prepDisplay()

        perform(#selector(populateSemesterAfterClearingOldInformation), with: nil, afterDelay: 0)
    }
    func populateSemesterAfterClearingOldInformation() {
        let semesterPVC = sidebarPageController.semesterVC!
        
        semesterPVC.loadCourses(from: selectedSemester)
        semesterPVC.loadWork(from: selectedSemester)
        semesterPVC.loadTests(from: selectedSemester)
        
        
        semesterPVC.optimizeSplitViewSpace()
        
        DispatchQueue.main.async {
            semesterPVC.display()
        }
    }
    
    func sidebarCourseNeedsPopulating(_ coursePVC: CoursePageViewController) {
        if selectedCourse == nil {
            return
        }
        coursePVC.courseLabel.stringValue = selectedCourse.title!
        
        let courseColor = NSColor(red: CGFloat(selectedCourse.color!.red), green: CGFloat(selectedCourse.color!.green), blue: CGFloat(selectedCourse.color!.blue), alpha: 1)
        coursePVC.colorBox.fillColor = courseColor
        
        coursePVC.view.alphaValue = 1
        coursePVC.prepDisplay()
        
        perform(#selector(populateCourseAfterClearingOldInformation), with: nil, afterDelay: 0.1)
    }
    func populateCourseAfterClearingOldInformation() {
        let coursePVC = sidebarPageController.courseVC!
        
        coursePVC.loadLectures(from: self.selectedCourse)
        coursePVC.loadTests(from: self.selectedCourse, showingCompleted: false)
        coursePVC.loadWork(from: self.selectedCourse, showingCompleted: false)
        coursePVC.loadDocs(from: self.selectedCourse)
        
        // Display the add button if a lecture is happening and it wasn't already created.
        if self.selectedCourse.duringTimeSlot() != nil && (self.selectedCourse.lectures?.count == 0 ||
            Int((self.selectedCourse.lectures?.lastObject as! Lecture).number) != self.selectedCourse.theoreticalLectureCount()) {
            coursePVC.addButton.isEnabled = true
            coursePVC.addButton.isHidden = false
            coursePVC.addButton.title = "Add Lecture \(max(self.selectedCourse.theoreticalLectureCount(), 1))"
        } else {
            coursePVC.addButton.isEnabled = false
            coursePVC.addButton.isHidden = true
        }
        //        // Fill in absent lectures since last course open
        //        sidebarVC.selectedCourse.fillAbsentLectures()
        
        coursePVC.optimizeSplitViewSpace()
        
        DispatchQueue.main.async {
            coursePVC.display()
        }
    }
    
    func sidebarCoursePopulateCompletedWork(_ coursePVC: CoursePageViewController) {
        if selectedCourse == nil {
            return
        }
        coursePVC.loadWork(from: selectedCourse, showingCompleted:
            sidebarPageController.courseVC.toggleCompletedWork.state == NSOnState)
    }
    
    func sidebarCoursePopulateCompletedTests(_ coursePVC: CoursePageViewController) {
        if selectedCourse == nil {
            return
        }
        coursePVC.loadTests(from: selectedCourse, showingCompleted:
            sidebarPageController.courseVC.toggleCompletedTests.state == NSOnState)
    }
    
    // MARK: - Document Drop Delegation
    
    /// Save a document to the selected course. Received from a drag and drop operation
    /// onto the documents scroll view. Also update the documents stack view.
    func dropDocument(at path: String) {
        guard
            let selectedCourse = selectedCourse,
            let selectedSemester = selectedSemester
            else { return }

        var loc = appDelegate.applicationDocumentsDirectory
        loc.appendPathComponent("\(selectedSemester.year)")
        loc.appendPathComponent("\(selectedSemester.title!)")
        loc.appendPathComponent("\(selectedCourse.title!)")
        loc.appendPathComponent("Documents/")
        
        let pathLoc = URL(fileURLWithPath: path)
        
        do {
            try FileManager.default.createDirectory(at: loc, withIntermediateDirectories: true, attributes: nil)
            loc.appendPathComponent(pathLoc.lastPathComponent)
            try FileManager.default.copyItem(at: pathLoc, to: loc)
        } catch { }
        sidebarPageController.courseVC.loadDocs(from: selectedCourse)
    }
}
