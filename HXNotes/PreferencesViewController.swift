//
//  PreferencesViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    
    var masterVC: MasterViewController!
    
    /// This is set by the cancel button if the preferences should be saved or not.
    var cancel = false
    
    @IBOutlet weak var nilResponderButton: NSButton!
    @IBOutlet weak var clipView: HXFlippedClipView!
    var lastSettingLabelYPos: CGFloat = 0
    
    // MARK: General Settings
    @IBOutlet weak var labelGeneral: NSTextField!
    @IBOutlet weak var checkBoxMenuBar: NSButton!
    @IBOutlet weak var checkBoxLaunchWithSystem: NSButton!
    @IBOutlet weak var checkBoxBackgroundRun: NSButton!
    @IBOutlet weak var checkBoxRememberLastSemester: NSButton!
    @IBOutlet weak var checkBoxRememberLastCourse: NSButton!
    @IBOutlet weak var checkBoxLaunchCurrentlyHappening: NSButton!
    
    @IBAction func action_launchWithSystem(_ sender: NSButton) {
        
    }
    @IBAction func action_menuBar(_ sender: NSButton) {
        if sender.state == NSOnState {
            if let appDel = NSApp.delegate as? AppDelegate {
                appDel.createMenuBarIcon()
            }
        } else {
            if let appDel = NSApp.delegate as? AppDelegate {
                appDel.removeMenuBarIcon()
            }
        }
    }
    @IBAction func action_backgroundRun(_ sender: NSButton) {
        
    }
    @IBAction func action_rememberLastSemester(_ sender: NSButton) {
        if sender.state == NSOnState {
            checkBoxRememberLastCourse.isEnabled = true
            if AppPreference.rememberLastCourse {
                checkBoxRememberLastCourse.state = NSOnState
            }
        } else {
            checkBoxRememberLastCourse.isEnabled = false
            checkBoxRememberLastCourse.state = NSOffState
        }
    }
    
    // MARK: Editor Settings
    @IBOutlet weak var labelEditor: NSTextField!
    @IBOutlet weak var checkBoxRecentLecture: NSButton!
    @IBOutlet weak var checkBoxAutoScroll: NSButton!
    @IBOutlet weak var sliderAutoScrollPercent: NSSlider!
    @IBOutlet weak var labelAutoScrollPercent: NSTextField!
    @IBOutlet weak var sliderBottomBufferSpace: NSSlider!
    @IBOutlet weak var labelBottomBufferSpace: NSTextField!
    @IBOutlet weak var checkBoxMagnetizedEffect: NSButton!
    
    @IBAction func action_toggleAutoScroll(_ sender: NSButton) {
        if sender.state == NSOnState {
            sliderAutoScrollPercent.isEnabled = true
            labelAutoScrollPercent.alphaValue = 1
        } else {
            sliderAutoScrollPercent.isEnabled = false
            labelAutoScrollPercent.alphaValue = 0.4
        }
    }
    @IBAction func action_sliderAutoScroll(_ sender: NSSlider) {
        labelAutoScrollPercent.stringValue = "\(Int(sender.doubleValue))%"
    }
    @IBAction func action_sliderBufferSpace(_ sender: NSSlider) {
        labelBottomBufferSpace.stringValue = "\(Int(clipView.enclosingScrollView!.frame.height * CGFloat(sliderBottomBufferSpace.doubleValue) / 100))px"
    }
    
    // MARK: Alert Settings
    @IBOutlet weak var labelAlerts: NSTextField!
    @IBOutlet weak var textFieldLectureAlertTime: NSTextField!
    @IBOutlet weak var radioButtonAlways: NSButton!
    @IBOutlet weak var radioButtonNoLectures: NSButton!
    @IBOutlet weak var radioButtonNoTimeslots: NSButton!
    @IBOutlet weak var radioButtonNever: NSButton!
    
    @IBAction func action_lectureAlertTime(_ sender: NSTextField) {
        sender.window!.makeFirstResponder(nilResponderButton)
    }
    @IBAction func action_radioButtonFrequency(_ sender: NSButton) {
        // NSButton's with radio style need to have same target:action to update each other.
    }
    
    // MARK: Scheduler Settings
    @IBOutlet weak var labelScheduler: NSTextField!
    @IBOutlet weak var textFieldDefaultTimeslotTime: NSTextField!
    @IBOutlet weak var textFieldTimeslotBufferTime: NSTextField!
    @IBOutlet weak var checkBoxCurrentTimeScheduler: NSButton!
    
    @IBAction func action_timeslotDefaultLength(_ sender: NSTextField) {
        sender.window!.makeFirstResponder(nilResponderButton)
    }
    @IBAction func action_timeslotBuffertime(_ sender: NSTextField) {
        sender.window!.makeFirstResponder(nilResponderButton)
    }
    
    // MARK: Sidebar Settings
    @IBOutlet weak var labelSidebar: NSTextField!
    @IBOutlet weak var checkBoxSingleCourseSelect: NSButton!
    @IBOutlet weak var textFieldAssumeCompleteDays: NSTextField!
    @IBOutlet weak var textFieldAssumeCompleteHours: NSTextField!
    @IBOutlet weak var textFieldAssumeCompleteMinutes: NSTextField!
    @IBOutlet weak var textFieldAssumeTakenDays: NSTextField!
    @IBOutlet weak var textFieldAssumeTakenHours: NSTextField!
    @IBOutlet weak var textFieldAssumeTakenMinutes: NSTextField!
    
    @IBAction func action_AssumeCompleteDays(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeCompleteHours)
    }
    @IBAction func action_AssumeCompleteHrs(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeCompleteMinutes)
    }
    @IBAction func action_AssumeCompleteMins(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeCompleteDays)
    }
    
    @IBAction func action_AssumeTakenDays(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeTakenHours)
    }
    @IBAction func action_AssumeTakenHrs(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeTakenMinutes)
    }
    @IBAction func action_AssumeTakenMins(_ sender: NSTextField) {
        
        NSApp.keyWindow?.makeFirstResponder(textFieldAssumeTakenDays)
    }
    
    @IBOutlet weak var toggleAssumeTaken: NSButton!
    @IBOutlet weak var toggleAssumeComplete: NSButton!
    
    @IBAction func action_AssumeTaken(_ sender: NSButton) {
        if sender.state == NSOnState {
            textFieldAssumeTakenDays.isEnabled = true
            textFieldAssumeTakenHours.isEnabled = true
            textFieldAssumeTakenMinutes.isEnabled = true
        } else {
            textFieldAssumeTakenDays.isEnabled = false
            textFieldAssumeTakenHours.isEnabled = false
            textFieldAssumeTakenMinutes.isEnabled = false
        }
    }
    @IBAction func action_AssumeComplete(_ sender: NSButton) {
        if sender.state == NSOnState {
            textFieldAssumeCompleteDays.isEnabled = true
            textFieldAssumeCompleteHours.isEnabled = true
            textFieldAssumeCompleteMinutes.isEnabled = true
        } else {
            textFieldAssumeCompleteDays.isEnabled = false
            textFieldAssumeCompleteHours.isEnabled = false
            textFieldAssumeCompleteMinutes.isEnabled = false
        }
    }
    
    
    // MARK: - Loading / Unloading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Retain the initial y position otherwise errors would occur if 
        // trying to get the origin.y after moving its position
        lastSettingLabelYPos = labelScheduler.frame.origin.y - labelScheduler.frame.height
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        if cancel {
            cancel = false
            return
        }
        
        // Save preferences
        AppPreference.autoScroll = (checkBoxAutoScroll.state == NSOnState)
        AppPreference.autoScrollPositionPercent = Int(sliderAutoScrollPercent.doubleValue)
        AppPreference.bottomBufferSpace = Int(sliderBottomBufferSpace.doubleValue)
        AppPreference.launchWithSystem = (checkBoxLaunchWithSystem.state == NSOnState)
        AppPreference.launchWithHappeningCourse = (checkBoxLaunchCurrentlyHappening.state == NSOnState)
        AppPreference.showInMenuBar = (checkBoxMenuBar.state == NSOnState)
        AppPreference.runAfterClose = (checkBoxBackgroundRun.state == NSOnState)
        if let alertTime = Int(textFieldLectureAlertTime.stringValue) {
            AppPreference.futureAlertTimeMinutes = alertTime
        }
        if radioButtonAlways.state == NSOnState {
            AppPreference.courseDeletionConfirmation = .ALWAYS
        } else if radioButtonNoLectures.state == NSOnState {
            AppPreference.courseDeletionConfirmation = .NO_LECTURES
        } else if radioButtonNoTimeslots.state == NSOnState {
            AppPreference.courseDeletionConfirmation = .NO_TIMESLOTS
        } else if radioButtonNever.state == NSOnState {
            AppPreference.courseDeletionConfirmation = .NEVER
        }
        
        if let defaultLength = Int(textFieldDefaultTimeslotTime.stringValue) {
            AppPreference.defaultCourseTimeSpanMinutes = defaultLength
        }
        if let bufferTime = Int(textFieldTimeslotBufferTime.stringValue) {
            AppPreference.bufferTimeBetweenCoursesMinutes = bufferTime
        }
        AppPreference.magnetizedEditor = checkBoxMagnetizedEffect.state == NSOnState
        AppPreference.showCurrentTime = checkBoxCurrentTimeScheduler.state == NSOnState
        AppPreference.openLastSemester = checkBoxRememberLastSemester.state == NSOnState
        AppPreference.rememberLastCourse = checkBoxRememberLastCourse.state == NSOnState
        AppPreference.assumeSingleSelection = (checkBoxSingleCourseSelect.state == NSOnState)
        if toggleAssumeComplete.state == NSOnState {
            if let days = Int(textFieldAssumeCompleteDays.stringValue),
                let hours = Int(textFieldAssumeCompleteHours.stringValue),
                let mins = Int(textFieldAssumeCompleteMinutes.stringValue) {
                AppPreference.assumePassedCompletion = "\(days):\(hours):\(mins)"
            }
        } else {
            AppPreference.assumePassedCompletion = "nil"
        }
        if toggleAssumeTaken.state == NSOnState {
            if let days = Int(textFieldAssumeTakenDays.stringValue),
                let hours = Int(textFieldAssumeTakenHours.stringValue),
                let mins = Int(textFieldAssumeTakenMinutes.stringValue) {
                AppPreference.assumePassedTaken = "\(days):\(hours):\(mins)"
            }
        } else {
            AppPreference.assumePassedTaken = "nil"
        }
        AppPreference.assumeRecentLecture = (checkBoxRecentLecture.state == NSOnState)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Load preferences
        if AppPreference.launchWithSystem {
            checkBoxLaunchWithSystem.state = NSOnState
        } else {
            checkBoxLaunchWithSystem.state = NSOffState
        }
        if AppPreference.showInMenuBar {
            checkBoxMenuBar.state = NSOnState
        } else {
            checkBoxMenuBar.state = NSOffState
        }
        if AppPreference.runAfterClose {
            checkBoxBackgroundRun.state = NSOnState
        } else {
            checkBoxBackgroundRun.state = NSOffState
        }
        if AppPreference.autoScroll {
            checkBoxAutoScroll.state = NSOnState
        } else {
            checkBoxAutoScroll.state = NSOffState
        }
        if AppPreference.magnetizedEditor {
            checkBoxMagnetizedEffect.state = NSOnState
        } else {
            checkBoxMagnetizedEffect.state = NSOffState
        }
        if AppPreference.launchWithHappeningCourse {
            checkBoxLaunchCurrentlyHappening.state = NSOnState
        } else {
            checkBoxLaunchCurrentlyHappening.state = NSOffState
        }
        if AppPreference.openLastSemester {
            checkBoxRememberLastSemester.state = NSOnState
            checkBoxRememberLastCourse.isEnabled = true
            if AppPreference.rememberLastCourse {
                checkBoxRememberLastCourse.state = NSOnState
            } else {
                checkBoxRememberLastCourse.state = NSOffState
            }
        } else {
            checkBoxRememberLastSemester.state = NSOffState
            checkBoxRememberLastCourse.isEnabled = false
            checkBoxRememberLastCourse.state = NSOffState
        }
        if AppPreference.showCurrentTime {
            checkBoxCurrentTimeScheduler.state = NSOnState
        } else {
            checkBoxCurrentTimeScheduler.state = NSOffState
        }
        sliderAutoScrollPercent.isEnabled = AppPreference.autoScroll
        sliderAutoScrollPercent.doubleValue = Double(AppPreference.autoScrollPositionPercent)
        labelAutoScrollPercent.stringValue = "\(AppPreference.autoScrollPositionPercent)%"
        sliderBottomBufferSpace.doubleValue = Double(AppPreference.bottomBufferSpace)
        labelBottomBufferSpace.stringValue = "\(Int(clipView.enclosingScrollView!.frame.height * CGFloat(AppPreference.bottomBufferSpace) / 100))px"
        textFieldLectureAlertTime.stringValue = "\(AppPreference.futureAlertTimeMinutes)"
        radioButtonAlways.state = NSOffState
        radioButtonNoTimeslots.state = NSOffState
        radioButtonNoLectures.state = NSOffState
        radioButtonNever.state = NSOffState
        switch AppPreference.courseDeletionConfirmation {
            case .ALWAYS: radioButtonAlways.state = NSOnState
            case .NO_LECTURES: radioButtonNoLectures.state = NSOnState
            case .NO_TIMESLOTS: radioButtonNoTimeslots.state = NSOnState
            case .NEVER: radioButtonNever.state = NSOnState
        }
        textFieldDefaultTimeslotTime.stringValue = "\(AppPreference.defaultCourseTimeSpanMinutes)"
        textFieldTimeslotBufferTime.stringValue = "\(AppPreference.bufferTimeBetweenCoursesMinutes)"
        if AppPreference.assumeSingleSelection {
            checkBoxSingleCourseSelect.state = NSOnState
        } else {
            checkBoxSingleCourseSelect.state = NSOffState
        }
        if AppPreference.assumePassedCompletion == "nil" {
            toggleAssumeComplete.state = NSOffState
            textFieldAssumeCompleteDays.isEnabled = false
            textFieldAssumeCompleteHours.isEnabled = false
            textFieldAssumeCompleteMinutes.isEnabled = false
        } else {
            let assumeComplete = AppPreference.assumePassedCompletion
            let parseDays = assumeComplete.substring(to: (assumeComplete.range(of: ":")?.lowerBound)!)
            let remain = assumeComplete.substring(from: (assumeComplete.range(of: ":")?.upperBound)!)
            let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
            let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
            textFieldAssumeCompleteDays.stringValue = parseDays
            textFieldAssumeCompleteHours.stringValue = parseHrs
            textFieldAssumeCompleteMinutes.stringValue = parseMins
        }
        if AppPreference.assumePassedTaken == "nil" {
            toggleAssumeComplete.state = NSOffState
            textFieldAssumeCompleteDays.isEnabled = false
            textFieldAssumeCompleteHours.isEnabled = false
            textFieldAssumeCompleteMinutes.isEnabled = false
        } else {
            let assumeTaken = AppPreference.assumePassedTaken
            let parseDays = assumeTaken.substring(to: (assumeTaken.range(of: ":")?.lowerBound)!)
            let remain = assumeTaken.substring(from: (assumeTaken.range(of: ":")?.upperBound)!)
            let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
            let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
            textFieldAssumeTakenDays.stringValue = parseDays
            textFieldAssumeTakenHours.stringValue = parseHrs
            textFieldAssumeTakenMinutes.stringValue = parseMins
        }
        if AppPreference.assumeRecentLecture {
            checkBoxRecentLecture.state = NSOnState
        } else {
            checkBoxRecentLecture.state = NSOffState
        }
    }
}






