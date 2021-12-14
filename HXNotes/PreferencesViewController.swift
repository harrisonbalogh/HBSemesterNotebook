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
    @IBOutlet weak var checkBoxRememberLastLecture: NSButton!
    @IBOutlet weak var checkBoxLaunchCurrentlyHappening: NSButton!
    
    @IBAction func action_launchWithSystem(_ sender: NSButton) {
        
    }
    @IBAction func action_menuBar(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
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
        if sender.state == NSControl.StateValue.on {
            checkBoxRememberLastCourse.isEnabled = true
            if AppPreference.rememberLastCourse {
                checkBoxRememberLastCourse.state = NSControl.StateValue.on
                checkBoxRememberLastLecture.isEnabled = true
                if AppPreference.rememberLastLecture {
                    checkBoxRememberLastLecture.state = NSControl.StateValue.on
                }
            } else {
                checkBoxRememberLastLecture.isEnabled = false
            }
        } else {
            checkBoxRememberLastCourse.isEnabled = false
            checkBoxRememberLastCourse.state = NSControl.StateValue.off
            checkBoxRememberLastLecture.isEnabled = false
            checkBoxRememberLastLecture.state = NSControl.StateValue.off
        }
    }
    @IBAction func action_rememberLastCourse(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            checkBoxRememberLastLecture.isEnabled = true
            if AppPreference.rememberLastLecture {
                checkBoxRememberLastLecture.state = NSControl.StateValue.on
            }
        } else {
            checkBoxRememberLastLecture.isEnabled = false
            checkBoxRememberLastLecture.state = NSControl.StateValue.off
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
    
    @IBAction func action_toggleAutoScroll(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
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
        if sender.state == NSControl.StateValue.on {
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
        if sender.state == NSControl.StateValue.on {
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
        AppPreference.autoScroll = (checkBoxAutoScroll.state == NSControl.StateValue.on)
        AppPreference.autoScrollPositionPercent = Int(sliderAutoScrollPercent.doubleValue)
        AppPreference.bottomBufferSpace = Int(sliderBottomBufferSpace.doubleValue)
        AppPreference.launchWithSystem = (checkBoxLaunchWithSystem.state == NSControl.StateValue.on)
        AppPreference.launchWithHappeningCourse = (checkBoxLaunchCurrentlyHappening.state == NSControl.StateValue.on)
        AppPreference.showInMenuBar = (checkBoxMenuBar.state == NSControl.StateValue.on)
        AppPreference.runAfterClose = (checkBoxBackgroundRun.state == NSControl.StateValue.on)
        if let alertTime = Int(textFieldLectureAlertTime.stringValue) {
            AppPreference.futureAlertTimeMinutes = alertTime
        }
        if radioButtonAlways.state == NSControl.StateValue.on {
            AppPreference.courseDeletionConfirmation = .ALWAYS
        } else if radioButtonNoLectures.state == NSControl.StateValue.on {
            AppPreference.courseDeletionConfirmation = .NO_LECTURES
        } else if radioButtonNoTimeslots.state == NSControl.StateValue.on {
            AppPreference.courseDeletionConfirmation = .NO_TIMESLOTS
        } else if radioButtonNever.state == NSControl.StateValue.on {
            AppPreference.courseDeletionConfirmation = .NEVER
        }
        
        if let defaultLength = Int(textFieldDefaultTimeslotTime.stringValue) {
            AppPreference.defaultCourseTimeSpanMinutes = defaultLength
        }
        if let bufferTime = Int(textFieldTimeslotBufferTime.stringValue) {
            AppPreference.bufferTimeBetweenCoursesMinutes = bufferTime
        }
        AppPreference.showCurrentTime = checkBoxCurrentTimeScheduler.state == NSControl.StateValue.on
        AppPreference.openLastSemester = checkBoxRememberLastSemester.state == NSControl.StateValue.on
        AppPreference.rememberLastCourse = checkBoxRememberLastCourse.state == NSControl.StateValue.on
        AppPreference.rememberLastLecture = checkBoxRememberLastLecture.state == NSControl.StateValue.on
        AppPreference.assumeSingleSelection = (checkBoxSingleCourseSelect.state == NSControl.StateValue.on)
        if toggleAssumeComplete.state == NSControl.StateValue.on {
            if let days = Int(textFieldAssumeCompleteDays.stringValue),
                let hours = Int(textFieldAssumeCompleteHours.stringValue),
                let mins = Int(textFieldAssumeCompleteMinutes.stringValue) {
                AppPreference.assumePassedCompletion = "\(days):\(hours):\(mins)"
            }
        } else {
            AppPreference.assumePassedCompletion = "nil"
        }
        if toggleAssumeTaken.state == NSControl.StateValue.on {
            if let days = Int(textFieldAssumeTakenDays.stringValue),
                let hours = Int(textFieldAssumeTakenHours.stringValue),
                let mins = Int(textFieldAssumeTakenMinutes.stringValue) {
                AppPreference.assumePassedTaken = "\(days):\(hours):\(mins)"
            }
        } else {
            AppPreference.assumePassedTaken = "nil"
        }
        AppPreference.assumeRecentLecture = (checkBoxRecentLecture.state == NSControl.StateValue.on)

        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Load preferences
        if AppPreference.launchWithSystem {
            checkBoxLaunchWithSystem.state = NSControl.StateValue.on
        } else {
            checkBoxLaunchWithSystem.state = NSControl.StateValue.off
        }
        if AppPreference.showInMenuBar {
            checkBoxMenuBar.state = NSControl.StateValue.on
        } else {
            checkBoxMenuBar.state = NSControl.StateValue.off
        }
        if AppPreference.runAfterClose {
            checkBoxBackgroundRun.state = NSControl.StateValue.on
        } else {
            checkBoxBackgroundRun.state = NSControl.StateValue.off
        }
        if AppPreference.autoScroll {
            checkBoxAutoScroll.state = NSControl.StateValue.on
        } else {
            checkBoxAutoScroll.state = NSControl.StateValue.off
        }
        if AppPreference.launchWithHappeningCourse {
            checkBoxLaunchCurrentlyHappening.state = NSControl.StateValue.on
        } else {
            checkBoxLaunchCurrentlyHappening.state = NSControl.StateValue.off
        }
        if AppPreference.openLastSemester {
            checkBoxRememberLastSemester.state = NSControl.StateValue.on
            checkBoxRememberLastCourse.isEnabled = true
            if AppPreference.rememberLastCourse {
                checkBoxRememberLastLecture.isEnabled = true
                checkBoxRememberLastCourse.state = NSControl.StateValue.on
                if AppPreference.rememberLastLecture {
                    checkBoxRememberLastLecture.state = NSControl.StateValue.on
                } else {
                    checkBoxRememberLastLecture.state = NSControl.StateValue.off
                }
            } else {
                checkBoxRememberLastCourse.state = NSControl.StateValue.off
                checkBoxRememberLastLecture.state = NSControl.StateValue.off
                checkBoxRememberLastLecture.isEnabled = false
            }
        } else {
            checkBoxRememberLastSemester.state = NSControl.StateValue.off
            checkBoxRememberLastCourse.isEnabled = false
            checkBoxRememberLastCourse.state = NSControl.StateValue.off
            checkBoxRememberLastLecture.isEnabled = false
            checkBoxRememberLastLecture.state = NSControl.StateValue.off
        }
        if AppPreference.showCurrentTime {
            checkBoxCurrentTimeScheduler.state = NSControl.StateValue.on
        } else {
            checkBoxCurrentTimeScheduler.state = NSControl.StateValue.off
        }
        sliderAutoScrollPercent.isEnabled = AppPreference.autoScroll
        sliderAutoScrollPercent.doubleValue = Double(AppPreference.autoScrollPositionPercent)
        labelAutoScrollPercent.stringValue = "\(AppPreference.autoScrollPositionPercent)%"
        sliderBottomBufferSpace.doubleValue = Double(AppPreference.bottomBufferSpace)
        labelBottomBufferSpace.stringValue = "\(Int(clipView.enclosingScrollView!.frame.height * CGFloat(AppPreference.bottomBufferSpace) / 100))px"
        textFieldLectureAlertTime.stringValue = "\(AppPreference.futureAlertTimeMinutes)"
        radioButtonAlways.state = NSControl.StateValue.off
        radioButtonNoTimeslots.state = NSControl.StateValue.off
        radioButtonNoLectures.state = NSControl.StateValue.off
        radioButtonNever.state = NSControl.StateValue.off
        switch AppPreference.courseDeletionConfirmation {
            case .ALWAYS: radioButtonAlways.state = NSControl.StateValue.on
            case .NO_LECTURES: radioButtonNoLectures.state = NSControl.StateValue.on
            case .NO_TIMESLOTS: radioButtonNoTimeslots.state = NSControl.StateValue.on
            case .NEVER: radioButtonNever.state = NSControl.StateValue.on
        }
        textFieldDefaultTimeslotTime.stringValue = "\(AppPreference.defaultCourseTimeSpanMinutes)"
        textFieldTimeslotBufferTime.stringValue = "\(AppPreference.bufferTimeBetweenCoursesMinutes)"
        if AppPreference.assumeSingleSelection {
            checkBoxSingleCourseSelect.state = NSControl.StateValue.on
        } else {
            checkBoxSingleCourseSelect.state = NSControl.StateValue.off
        }
        if AppPreference.assumePassedCompletion == "nil" {
            toggleAssumeComplete.state = NSControl.StateValue.off
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
            toggleAssumeComplete.state = NSControl.StateValue.off
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
            checkBoxRecentLecture.state = NSControl.StateValue.on
        } else {
            checkBoxRecentLecture.state = NSControl.StateValue.off
        }
    }
}






