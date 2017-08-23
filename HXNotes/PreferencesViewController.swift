//
//  PreferencesViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var nilResponderButton: NSButton!
    @IBOutlet weak var clipView: HXFlippedClipView!
    var lastSettingLabelYPos: CGFloat = 0
    
    // MARK: General Settings
    @IBOutlet weak var labelGeneral: NSTextField!
    @IBOutlet weak var checkBoxMenuBar: NSButton!
    @IBOutlet weak var checkBoxLaunchWithSystem: NSButton!
    @IBOutlet weak var checkBoxBackgroundRun: NSButton!
    
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
    
    // MARK: Editor Settings
    @IBOutlet weak var labelEditor: NSTextField!
    @IBOutlet weak var checkBoxAutoScroll: NSButton!
    @IBOutlet weak var sliderAutoScrollPercent: NSSlider!
    @IBOutlet weak var labelAutoScrollPercent: NSTextField!
    @IBOutlet weak var sliderBottomBufferSpace: NSSlider!
    @IBOutlet weak var labelBottomBufferSpace: NSTextField!
    
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
        
        // Save preferences
        CFPreferencesSetAppValue(NSString(string: "autoScroll"), NSString(string: "\(checkBoxAutoScroll.state == NSOnState)"), kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue(NSString(string: "autoScrollPositionPercent"), NSString(string: "\(Int(sliderAutoScrollPercent.doubleValue))"), kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue(NSString(string: "bottomBufferSpace"), NSString(string: "\(Int(sliderBottomBufferSpace.doubleValue))"), kCFPreferencesCurrentApplication)
        
        CFPreferencesSetAppValue(NSString(string: "launchWithSystem"),NSString(string: "\(checkBoxLaunchWithSystem.state == NSOnState)"), kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue(NSString(string: "showInMenuBar"),NSString(string: "\(checkBoxMenuBar.state == NSOnState)"), kCFPreferencesCurrentApplication)
        CFPreferencesSetAppValue(NSString(string: "runAfterClose"),NSString(string: "\(checkBoxBackgroundRun.state == NSOnState)"), kCFPreferencesCurrentApplication)
        
        if let alertTime = Int(textFieldLectureAlertTime.stringValue) {
            CFPreferencesSetAppValue(NSString(string: "futureAlertTimeMinutes"),NSString(string: "\(alertTime)"), kCFPreferencesCurrentApplication)
        }
        if radioButtonAlways.state == NSOnState {
            CFPreferencesSetAppValue(NSString(string: "courseDeletionConfirmation"),NSString(string: "ALWAYS"), kCFPreferencesCurrentApplication)
        } else if radioButtonNoLectures.state == NSOnState {
            CFPreferencesSetAppValue(NSString(string: "courseDeletionConfirmation"),NSString(string: "NO_LECTURES"), kCFPreferencesCurrentApplication)
        } else if radioButtonNoTimeslots.state == NSOnState {
            CFPreferencesSetAppValue(NSString(string: "courseDeletionConfirmation"),NSString(string: "NO_TIMESLOTS"), kCFPreferencesCurrentApplication)
        } else if radioButtonNever.state == NSOnState {
            CFPreferencesSetAppValue(NSString(string: "courseDeletionConfirmation"),NSString(string: "NEVER"), kCFPreferencesCurrentApplication)
        }
        
        if let defaultLength = Int(textFieldDefaultTimeslotTime.stringValue) {
            CFPreferencesSetAppValue(NSString(string: "defaultCourseTimeSpanMinutes"),NSString(string: "\(defaultLength)"), kCFPreferencesCurrentApplication)
        }
        if let bufferTime = Int(textFieldTimeslotBufferTime.stringValue) {
            CFPreferencesSetAppValue(NSString(string: "bufferTimeBetweenCoursesMinutes"),NSString(string: "\(bufferTime)"), kCFPreferencesCurrentApplication)
        }
        CFPreferencesSetAppValue(NSString(string: "assumeSingleSelection"), NSString(string: "\(checkBoxSingleCourseSelect.state == NSOnState)"), kCFPreferencesCurrentApplication)
        if toggleAssumeComplete.state == NSOnState {
            if let days = Int(textFieldAssumeCompleteDays.stringValue),
                let hours = Int(textFieldAssumeCompleteHours.stringValue),
                let mins = Int(textFieldAssumeCompleteMinutes.stringValue) {
                CFPreferencesSetAppValue(NSString(string: "assumePassedCompletion"),NSString(string:
                    "\(days):\(hours):\(mins)"), kCFPreferencesCurrentApplication)
            }
        } else {
            CFPreferencesSetAppValue(NSString(string: "assumePassedCompletion"),NSString(string: "nil"), kCFPreferencesCurrentApplication)
        }
        if toggleAssumeTaken.state == NSOnState {
            if let days = Int(textFieldAssumeTakenDays.stringValue),
                let hours = Int(textFieldAssumeTakenHours.stringValue),
                let mins = Int(textFieldAssumeTakenMinutes.stringValue) {
                CFPreferencesSetAppValue(NSString(string: "assumePassedTaken"),NSString(string:
                    "\(days):\(hours):\(mins)"), kCFPreferencesCurrentApplication)
            }
        } else {
            CFPreferencesSetAppValue(NSString(string: "assumePassedTaken"),NSString(string: "nil"), kCFPreferencesCurrentApplication)
        }
        
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // Load preferences
        if let launchWithSystem = CFPreferencesCopyAppValue(NSString(string: "launchWithSystem"), kCFPreferencesCurrentApplication) as? String {
            if launchWithSystem == "true" {
                checkBoxLaunchWithSystem.state = NSOnState
            } else if launchWithSystem == "false" {
                checkBoxLaunchWithSystem.state = NSOffState
            }
        }
        if let menuBarShown = CFPreferencesCopyAppValue(NSString(string: "showInMenuBar"), kCFPreferencesCurrentApplication) as? String {
            if menuBarShown == "true" {
                checkBoxMenuBar.state = NSOnState
            } else if menuBarShown == "false" {
                checkBoxMenuBar.state = NSOffState
            }
        }
        if let backgroundRun = CFPreferencesCopyAppValue(NSString(string: "runAfterClose"), kCFPreferencesCurrentApplication) as? String {
            if backgroundRun == "true" {
                checkBoxBackgroundRun.state = NSOnState
            } else if backgroundRun == "false" {
                checkBoxBackgroundRun.state = NSOffState
            }
        }
        if let autoScrollPref = CFPreferencesCopyAppValue(NSString(string: "autoScroll"), kCFPreferencesCurrentApplication) as? String {
            if autoScrollPref == "true" {
                checkBoxAutoScroll.state = NSOnState
            } else if autoScrollPref == "false" {
                checkBoxAutoScroll.state = NSOffState
                sliderAutoScrollPercent.isEnabled = false
            }
        }
        if let autoScrollPercent = CFPreferencesCopyAppValue(NSString(string: "autoScrollPositionPercent"), kCFPreferencesCurrentApplication) as? String {
            if let percent = Int(autoScrollPercent) {
                sliderAutoScrollPercent.doubleValue = Double(percent)
                labelAutoScrollPercent.stringValue = "\(percent)%"
            }
        }
        if let bottomBufferPercent = CFPreferencesCopyAppValue(NSString(string: "bottomBufferSpace"), kCFPreferencesCurrentApplication) as? String {
            if let percent = Int(bottomBufferPercent) {
                sliderBottomBufferSpace.doubleValue = Double(percent)
                labelBottomBufferSpace.stringValue = "\(Int(clipView.enclosingScrollView!.frame.height * CGFloat(percent) / 100))px"
            }
        }
        if let futureAlertTime = CFPreferencesCopyAppValue(NSString(string: "futureAlertTimeMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(futureAlertTime) {
                textFieldLectureAlertTime.stringValue = "\(time)"
            }
        }
        if let deletionConfirmation = CFPreferencesCopyAppValue(NSString(string: "courseDeletionConfirmation"), kCFPreferencesCurrentApplication) as? String {
            
            radioButtonAlways.state = NSOffState
            radioButtonNoTimeslots.state = NSOffState
            radioButtonNoLectures.state = NSOffState
            radioButtonNever.state = NSOffState
            
            switch deletionConfirmation {
                case "ALWAYS":
                    radioButtonAlways.state = NSOnState
                case "NO_LECTURES":
                    radioButtonNoLectures.state = NSOnState
                case "NO_TIMESLOTS":
                    radioButtonNoTimeslots.state = NSOnState
                case "NEVER":
                    radioButtonNever.state = NSOnState
                default:
                    radioButtonAlways.state = NSOnState
            }
        }
        if let timeSpanDefault = CFPreferencesCopyAppValue(NSString(string: "defaultCourseTimeSpanMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(timeSpanDefault) {
                textFieldDefaultTimeslotTime.stringValue = "\(time)"
            }
        }
        if let bufferTime = CFPreferencesCopyAppValue(NSString(string: "bufferTimeBetweenCoursesMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(bufferTime) {
                textFieldTimeslotBufferTime.stringValue = "\(time)"
            }
        }
        if let singleSelect = CFPreferencesCopyAppValue(NSString(string: "assumeSingleSelection"), kCFPreferencesCurrentApplication) as? String {
            if singleSelect == "true" {
                checkBoxSingleCourseSelect.state = NSOnState
            } else if singleSelect == "false" {
                checkBoxSingleCourseSelect.state = NSOffState
            }
        }
        if let assumeComplete = CFPreferencesCopyAppValue(NSString(string: "assumePassedCompletion"), kCFPreferencesCurrentApplication) as? String {
            if assumeComplete == "nil" {
                toggleAssumeComplete.state = NSOffState
                textFieldAssumeCompleteDays.isEnabled = false
                textFieldAssumeCompleteHours.isEnabled = false
                textFieldAssumeCompleteMinutes.isEnabled = false
            } else {
                let parseDays = assumeComplete.substring(to: (assumeComplete.range(of: ":")?.lowerBound)!)
                let remain = assumeComplete.substring(from: (assumeComplete.range(of: ":")?.upperBound)!)
                let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                textFieldAssumeCompleteDays.stringValue = parseDays
                textFieldAssumeCompleteHours.stringValue = parseHrs
                textFieldAssumeCompleteMinutes.stringValue = parseMins
            }
        }
        if let assumeTaken = CFPreferencesCopyAppValue(NSString(string: "assumePassedTaken"), kCFPreferencesCurrentApplication) as? String {
            if assumeTaken == "nil" {
                toggleAssumeComplete.state = NSOffState
                textFieldAssumeCompleteDays.isEnabled = false
                textFieldAssumeCompleteHours.isEnabled = false
                textFieldAssumeCompleteMinutes.isEnabled = false
            } else {
                print("assume taken is \(assumeTaken)")
                let parseDays = assumeTaken.substring(to: (assumeTaken.range(of: ":")?.lowerBound)!)
                let remain = assumeTaken.substring(from: (assumeTaken.range(of: ":")?.upperBound)!)
                let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                textFieldAssumeTakenDays.stringValue = parseDays
                textFieldAssumeTakenHours.stringValue = parseHrs
                textFieldAssumeTakenMinutes.stringValue = parseMins
            }
        }
    }
    
//    @IBAction func action_closePreferences(_ sender: NSButton) {
//        let appDelegate = NSApp.delegate as! AppDelegate
//        appDelegate.closeModal()
//    }
}









