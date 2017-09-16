//
//  MasterViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/24/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Darwin

class MasterViewController: NSViewController, SelectionDelegate, SchedulingDelegate, SidebarDelegate {
    
    // MARK: View references
    @IBOutlet weak var splitView_sidebar: NSView!
    @IBOutlet weak var splitView_content: SplitViewContent!
    
    // Children controllers
    var sidebarPageController: SidebarPageController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Mark: Initialize the viewController ..................................................................
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSApp.keyWindow?.makeFirstResponder(self)
        NSApp.keyWindow?.initialFirstResponder = self.view
        
        Alert.masterViewController = self
        
        loadPreferences()
        
        view.wantsLayer = true
        
        AppDelegate.scheduleAssistant = ScheduleAssistant(masterController: self)
        
        // Get the current real time semester
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        // Set the current semester displayed in the SidebarVC - might want to remeber last selected semester
        semesterToday = Semester.produceSemester(titled: semesterTitle, in: yearComponent)
        
        // Check if there was a previously opened semester when last quit the app
        if let prevOpenCourse = CFPreferencesCopyAppValue(NSString(string: "previouslyOpenedCourse"), kCFPreferencesCurrentApplication) as? String {
            if prevOpenCourse != "nil" {
                let parseSem = prevOpenCourse.substring(to: (prevOpenCourse.range(of: ":")?.lowerBound)!)
                let remain = prevOpenCourse.substring(from: (prevOpenCourse.range(of: ":")?.upperBound)!)
                let parseYr = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseCourse = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                
                let semester = Semester.produceSemester(titled: parseSem.lowercased(), in: Int(parseYr)!)
                setDate(semester: semester)
                
                // Check if there was a course selected when last quit
                if parseCourse != "nil" {
                    if let course = semester.retrieveCourse(named: parseCourse) {
                        selectedCourse = course
                    }
                }
            } else {
                // Use today's date if there was not a previously selected course
                setDate(semester: semesterToday)
            }
        } else {
            // Use today's date if there was not a previously selected course
            setDate(semester: semesterToday)
        }
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        for case let sidebarPC as SidebarPageController in self.childViewControllers {
            sidebarPC.schedulingDelegate = self
            sidebarPC.selectionDelegate = self
            sidebarPC.sidebarDelegate = self
            self.sidebarPageController = sidebarPC
            
            // Jump to semester view if opening app and schedule is valid.
            if selectedSemester != nil && selectedSemester.valid {
                sidebarPageController.schedulerVC.isPastSemester = selectedSemester.isEarlier(than: self.semesterToday)
                sidebarPageController.schedulerVC.loadCourses(from: selectedSemester)
                scheduleBox.isHighlighting = true
                
                sidebarPageController.selectedIndex = sidebarPageController.SBSemesterIndex

                if selectedCourse != nil {
                    sidebarPageController.selectedIndex = sidebarPageController.SBCourseIndex
                    if assumeRecentLecture {
                        isEditing(lecture: (selectedCourse.lectures!.lastObject as! Lecture))
                    }
                    reloadScheduler(with: selectedCourse)
                } else {
                    reloadScheduler(with: nil)
                }
            }
        }
        
        scheduleBox.selectionDelegate = self
        
        // Listen for window resizes
        NotificationCenter.default.addObserver(self, selector: #selector(checkMagnetRegion), name: .NSWindowDidResize, object: self.view.window!)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        var course = ""
        if self.selectedCourse == nil {
            course = "nil"
        } else {
            course = self.selectedCourse.title!
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
    
    var assumeRecentLecture = true
    var singleSelectPref = true
    
    func loadPreferences() {
        
        if let singleSelect = CFPreferencesCopyAppValue(NSString(string: "assumeSingleSelection"), kCFPreferencesCurrentApplication) as? String {
            if singleSelect == "true" {
                singleSelectPref = true
            } else if singleSelect == "false" {
                singleSelectPref = false
            }
        }
        
        if let assumeRecent = CFPreferencesCopyAppValue(NSString(string: "assumeRecentLecture"), kCFPreferencesCurrentApplication) as? String {
            if assumeRecent == "true" {
                assumeRecentLecture = true
            } else {
                assumeRecentLecture = false
            }
        }
    }
    
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
            loadPreferences()
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
    
    @IBAction func action_showCurrentTime(_ sender: NSButton) {
        if sender.state == NSOnState {
            drawTimeBox.notifyDrawsTimeOfDay(true)
        } else {
            drawTimeBox.notifyDrawsTimeOfDay(false)
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
    
    @IBOutlet weak var editBox: NSBox!
    let DEFAULT_TOP_CONSTRAINT: CGFloat = 22
    @IBOutlet weak var editBoxTopConstraint: NSLayoutConstraint!
    
    func collapseTitlebar() {
        editBoxTopConstraint.constant = 0
    }
    func revealTitlebar() {
        editBoxTopConstraint.constant = DEFAULT_TOP_CONSTRAINT
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
    
    /// The current semester displayed in the sidebar. Setting this value will update visuals.
    var selectedSemester: Semester! {
        didSet {
            print("selectedSemester")
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
        lastYearUsed = Int(semester.year)
        yearLabel.stringValue = "\(lastYearUsed)"
        self.selectedSemester = semester
        
        semesterButton.title = selectedSemester.title!.capitalized
    }
    
    var lastYearUsed = 0
    @IBAction func action_incrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        semButtonAnimBotConstraint.constant = -30
        if self.semesterButton.title == "Spring" {
            self.semesterButtonAnimated.title = "Fall"
        } else {
            self.semesterButtonAnimated.title = "Spring"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
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
            self.selectedSemester = Semester.produceSemester(titled: self.semesterButton.title, in: Int(self.yearLabel.stringValue)!)
            self.semesterLabel.stringValue = self.semesterButton.title + " " + self.yearLabel.stringValue
            self.semButtonBotConstraint.constant = 0
            self.semesterLabel.animator().alphaValue = 1
            self.scheduleBox.animator().alphaValue = 1
            sender.isEnabled = true
        }
        scheduleBox.animator().alphaValue = 0
        semesterLabel.animator().alphaValue = 0
        self.semButtonBotConstraint.animator().constant = -semesterButton.frame.height
        if self.semesterButton.title == "Fall" {
            self.yrButtonBotConstraint.animator().constant = semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_decrementTime(_ sender: NSButton) {
        sender.isEnabled = false

        semButtonAnimBotConstraint.constant = 30
        yrButtonAnimBotConstraint.constant = 30
        if self.semesterButton.title == "Fall" {
            self.semesterButtonAnimated.title = "Spring"
        } else {
            self.semesterButtonAnimated.title = "Fall"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
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
            self.selectedSemester = Semester.produceSemester(titled: self.semesterButton.title, in: Int(self.yearLabel.stringValue)!)
            self.semesterLabel.stringValue = self.semesterButton.title + " " + self.yearLabel.stringValue
            self.semButtonBotConstraint.constant = 0
            self.semesterLabel.animator().alphaValue = 1
            self.scheduleBox.animator().alphaValue = 1
            sender.isEnabled = true
        }
        scheduleBox.animator().alphaValue = 0
        semesterLabel.animator().alphaValue = 0
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
//        updateDate()
    }
    
    // MARK: ––– Window Magnet Functionality –––
    
    /// Performed as Window is being resized.
    func checkMagnetRegion() {
        
        // THIS SHOULDN'T HAPPEN IF PREFERENCES IS SHOWING
        
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
        if lectureEditorVC == nil && lectureEditorVC.selectedLecture != nil {
            splitView_content.print(self)            
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
                print("selectedCourse: \(selectedCourse.title!)")
            } else {
                print("selectedCourse: nil")
            }
        }
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
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        
        // See if the current semester exists in the persistant store
        if let currentSemester = Semester.retrieveSemester(titled: semesterTitle, in: yearComponent) {
            if let timeSlotHappening = currentSemester.duringCourse() {
                if timeSlotHappening.course!.theoreticalLectureCount() != timeSlotHappening.course!.lectures!.count || timeSlotHappening.course!.theoreticalLectureCount() == 0 {
                    if selectedSemester != currentSemester {
                        selectedSemester = currentSemester
                    }
                    if selectedCourse != timeSlotHappening.course! {
                        selectedCourse = timeSlotHappening.course!
                    } else {
                        selectedCourse.fillAbsentLectures()
                    }
                    
                    courseWasSelected(selectedCourse)
                    
                    Alert.flushAlerts(for: selectedCourse)
                    
                    // Create new lecture
                    timeSlotHappening.course!.createLecture(during: timeSlotHappening.course!.duringTimeSlot()!, on: nil, in: nil)
                    
                    // Displays lecture in the lectureStackView
                    sidebarPageController.courseVC.loadLectures(from: selectedCourse)
                } else {
                    print("No lectures to add??? Theoretical count: \(timeSlotHappening.course!.theoreticalLectureCount())")
                }
            } else {
                // User probably waited too long to accept lecture, so display error
                let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
                let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
                let _ = Alert(hour: hour, minute: minute, course: nil, content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil, type: .custom)
            }
        }
    }
    
    // MARK: - Control Flow Delegation
    
    func courseWasSelected(_ course: Course?) {
        if course != nil {
            selectedCourse = course
            if sidebarPageController.selectedIndex == sidebarPageController.SBCourseIndex {
                sidebarCourseNeedsPopulating(sidebarPageController.courseVC)
            } else {
                sidebarPageController.selectedIndex = sidebarPageController.SBCourseIndex
            }
            if assumeRecentLecture {
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
            scheduleBox.isHighlighting = false
            displayLectureEditor(for: lecture!)
        } else {
            scheduleBox.isHighlighting = true
            hideLectureEditor()
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
    
    // MARK: - Scheduler Delegation
    
    func schedulingDidFinish() {
        scheduleBox.isHighlighting = true
        if singleSelectPref && selectedSemester.courses!.count == 1 {
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
    
    // MARK: - Sidebar Delegation
    
    func sidebarSchedulingNeedsPopulating(_ schedulerPVC: SchedulerPageViewController) {
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
        coursePVC.view.alphaValue = 1
        coursePVC.prepDisplay()
        
        perform(#selector(populateCourseAfterClearingOldInformation), with: nil, afterDelay: 0)
    }
    func populateCourseAfterClearingOldInformation() {
        let coursePVC = sidebarPageController.courseVC!
        
        coursePVC.loadLectures(from: self.selectedCourse)
        coursePVC.loadTests(from: self.selectedCourse, showingCompleted: false)
        coursePVC.loadWork(from: self.selectedCourse, showingCompleted: false)
        
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
}
