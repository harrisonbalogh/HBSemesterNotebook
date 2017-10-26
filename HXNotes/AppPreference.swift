//
//  AppPreferences.swift
//  HXNotes
//
//  Created by Harrison Balogh on 10/13/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class AppPreference {
    
    // MARK: -
    private static var cached_autoScroll: Bool!
    public static var autoScroll: Bool {
        set {
            if cached_autoScroll != nil && cached_autoScroll == newValue { return }
            
            cached_autoScroll = newValue
            CFPreferencesSetAppValue("autScroll" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_autoScroll != nil {
                return cached_autoScroll!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("autoScroll" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_autoScroll = pref
            } else {
                // Setup default
                self.autoScroll = true
            }
            return cached_autoScroll
        }
    }
    
    // MARK: -
    private static var cached_autoScrollPositionPercent: Int!
    public static var autoScrollPositionPercent: Int {
        set {
            if cached_autoScrollPositionPercent != nil && cached_autoScrollPositionPercent == newValue { return }
            
            cached_autoScrollPositionPercent = newValue
            CFPreferencesSetAppValue("autoScrollPositionPercent" as CFString,
                                     newValue as CFNumber, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_autoScrollPositionPercent != nil {
                return cached_autoScrollPositionPercent!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("autoScrollPositionPercent" as CFString, kCFPreferencesCurrentApplication) as? Int {
                cached_autoScrollPositionPercent = pref
            } else {
                // Setup default
                self.autoScrollPositionPercent = 50
            }
            return cached_autoScrollPositionPercent
        }
    }
    
    // MARK: -
    private static var cached_bottomBufferSpace: Int!
    public static var bottomBufferSpace: Int {
        set {
            if cached_bottomBufferSpace != nil && cached_bottomBufferSpace == newValue { return }
            
            cached_bottomBufferSpace = newValue
            CFPreferencesSetAppValue("bottomBufferSpace" as CFString,
                                     newValue as CFNumber, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_bottomBufferSpace != nil {
                return cached_bottomBufferSpace!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("bottomBufferSpace" as CFString, kCFPreferencesCurrentApplication) as? Int {
                cached_bottomBufferSpace = pref
            } else {
                // Setup default
                self.bottomBufferSpace = 30
            }
            return cached_bottomBufferSpace
        }
    }

    // MARK: -
    private static var cached_launchWithSystem: Bool!
    public static var launchWithSystem: Bool {
        set {
            if cached_launchWithSystem != nil && cached_launchWithSystem == newValue { return }
            
            cached_launchWithSystem = newValue
            CFPreferencesSetAppValue("launchWithSystem" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_launchWithSystem != nil {
                return cached_launchWithSystem!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("launchWithSystem" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_launchWithSystem = pref
            } else {
                // Setup default
                self.launchWithSystem = false
            }
            return cached_launchWithSystem
        }
    }

    // MARK: -
    private static var cached_showInMenuBar: Bool!
    public static var showInMenuBar: Bool {
        set {
            if cached_showInMenuBar != nil && cached_showInMenuBar == newValue { return }
            
            cached_showInMenuBar = newValue
            CFPreferencesSetAppValue("showInMenuBar" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_showInMenuBar != nil {
                return cached_showInMenuBar!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("showInMenuBar" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_showInMenuBar = pref
            } else {
                // Setup default
                self.showInMenuBar = true
            }
            return cached_showInMenuBar
        }
    }

    // MARK: -
    private static var cached_runAfterClose: Bool!
    public static var runAfterClose: Bool {
        set {
            if cached_runAfterClose != nil && cached_runAfterClose == newValue { return }
            
            cached_runAfterClose = newValue
            CFPreferencesSetAppValue("runAfterClose" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_runAfterClose != nil {
                return cached_runAfterClose!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("runAfterClose" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_runAfterClose = pref
            } else {
                // Setup default
                self.runAfterClose = false
            }
            return cached_runAfterClose
        }
    }

    // MARK: -
    private static var cached_futureAlertTimeMinutes: Int!
    public static var futureAlertTimeMinutes: Int {
        set {
            if cached_futureAlertTimeMinutes != nil && cached_futureAlertTimeMinutes == newValue { return }
            
            cached_futureAlertTimeMinutes = newValue
            CFPreferencesSetAppValue("futureAlertTimeMinutes" as CFString,
                                     newValue as CFNumber, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_futureAlertTimeMinutes != nil {
                return cached_futureAlertTimeMinutes!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("futureAlertTimeMinutes" as CFString, kCFPreferencesCurrentApplication) as? Int {
                cached_futureAlertTimeMinutes = pref
            } else {
                // Setup default
                self.futureAlertTimeMinutes = 5
            }
            return cached_futureAlertTimeMinutes
        }
    }

    // MARK: -
    enum CourseDeletionConfirmationFrequency {
        case ALWAYS
        case NO_LECTURES
        case NO_TIMESLOTS
        case NEVER
    }
    private static var cached_courseDeletionConfirmation: CourseDeletionConfirmationFrequency!
    public static var courseDeletionConfirmation: CourseDeletionConfirmationFrequency {
        set {
            if cached_courseDeletionConfirmation != nil && cached_courseDeletionConfirmation == newValue { return }
            
            cached_courseDeletionConfirmation = newValue
            CFPreferencesSetAppValue("courseDeletionConfirmation" as CFString,
                                     "\(newValue)" as CFString, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_courseDeletionConfirmation != nil {
                return cached_courseDeletionConfirmation!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("courseDeletionConfirmation" as CFString, kCFPreferencesCurrentApplication) as? String {
                switch (pref) {
                    case "ALWAYS": cached_courseDeletionConfirmation = .ALWAYS
                    case "NO_TIMESLOTS": cached_courseDeletionConfirmation = .NO_TIMESLOTS
                    case "NEVER": cached_courseDeletionConfirmation = .NEVER
                default: cached_courseDeletionConfirmation = .NO_LECTURES
                }
            } else {
                // Setup default
                self.courseDeletionConfirmation = .NO_LECTURES
            }
            return cached_courseDeletionConfirmation
        }
    }

    // MARK: -
    private static var cached_alertLocation: Alert.AlertLocation!
    public static var alertLocation: Alert.AlertLocation {
        set {
            if cached_alertLocation != nil && cached_alertLocation == newValue { return }
            
            cached_alertLocation = newValue
            CFPreferencesSetAppValue("alertLocation" as CFString,
                                     "\(newValue)" as CFString, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_alertLocation != nil {
                return cached_alertLocation!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("alertLocation" as CFString, kCFPreferencesCurrentApplication) as? String {
                switch (pref) {
                case "overlay": cached_alertLocation = Alert.AlertLocation.overlay
                case "sidebar": cached_alertLocation = Alert.AlertLocation.sidebar
                default: cached_alertLocation = Alert.AlertLocation.dropdown
                }
            } else {
                // Setup default
                self.cached_alertLocation = Alert.AlertLocation.dropdown
            }
            return cached_alertLocation
        }
    }
    
    // MARK: -
    private static var cached_defaultCourseTimeSpanMinutes: Int!
    public static var defaultCourseTimeSpanMinutes: Int {
        set {
            if cached_defaultCourseTimeSpanMinutes != nil && cached_defaultCourseTimeSpanMinutes != nil && cached_defaultCourseTimeSpanMinutes == newValue { return }
            
            cached_defaultCourseTimeSpanMinutes = newValue
            CFPreferencesSetAppValue("defaultCourseTimeSpanMinutes" as CFString,
                                     newValue as CFNumber, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_defaultCourseTimeSpanMinutes != nil {
                return cached_defaultCourseTimeSpanMinutes!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("defaultCourseTimeSpanMinutes" as CFString, kCFPreferencesCurrentApplication) as? Int {
                cached_defaultCourseTimeSpanMinutes = pref
            } else {
                // Setup default
                self.defaultCourseTimeSpanMinutes = 55
            }
            return cached_defaultCourseTimeSpanMinutes
        }
    }

    // MARK: -
    private static var cached_bufferTimeBetweenCoursesMinutes: Int!
    public static var bufferTimeBetweenCoursesMinutes: Int {
        set {
            if cached_bufferTimeBetweenCoursesMinutes != nil && cached_bufferTimeBetweenCoursesMinutes == newValue { return }
            
            cached_bufferTimeBetweenCoursesMinutes = newValue
            CFPreferencesSetAppValue("bufferTimeBetweenCoursesMinutes" as CFString,
                                     newValue as CFNumber, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_bufferTimeBetweenCoursesMinutes != nil {
                return cached_bufferTimeBetweenCoursesMinutes!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("bufferTimeBetweenCoursesMinutes" as CFString, kCFPreferencesCurrentApplication) as? Int {
                cached_bufferTimeBetweenCoursesMinutes = pref
            } else {
                // Setup default
                self.bufferTimeBetweenCoursesMinutes = 5
            }
            return cached_bufferTimeBetweenCoursesMinutes
        }
    }
    
    // MARK: -
    public static var previouslyOpenedCourse: Course? {
        set {
            if newValue == nil {
                CFPreferencesSetAppValue("previouslyOpenedCourse" as CFString,
                                         nil, kCFPreferencesCurrentApplication)
            } else {
                CFPreferencesSetAppValue("previouslyOpenedCourse" as CFString,
                                         newValue!.title! as CFString, kCFPreferencesCurrentApplication)
                previouslyOpenedSemester = newValue!.semester!
            }
        }
        get {
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("previouslyOpenedCourse" as CFString, kCFPreferencesCurrentApplication) as? String {
                if let prevCourse = previouslyOpenedSemester?.retrieveCourse(named: pref) {
                    return prevCourse
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
    
    // MARK: -
    private static var cached_rememberLastCourse: Bool!
    public static var rememberLastCourse: Bool {
        set {
            if cached_rememberLastCourse != nil && cached_rememberLastCourse == newValue { return }
            
            cached_rememberLastCourse = newValue
            CFPreferencesSetAppValue("rememberLastCourse" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_rememberLastCourse != nil {
                return cached_rememberLastCourse!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("rememberLastCourse" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_rememberLastCourse = pref
            } else {
                // Setup default
                self.rememberLastCourse = true
            }
            return cached_rememberLastCourse
        }
    }
    
    // MARK: -
    public static var previouslyOpenedSemester: Semester? {
        set {
            if newValue == nil {
                CFPreferencesSetAppValue("previouslyOpenedSemester" as CFString,
                                         "nil" as CFString, kCFPreferencesCurrentApplication)
            } else {
                CFPreferencesSetAppValue("previouslyOpenedSemester" as CFString,
                                         "\(newValue!.title!):\(newValue!.year)" as CFString, kCFPreferencesCurrentApplication)
            }
            
        }
        get {
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("previouslyOpenedSemester" as CFString, kCFPreferencesCurrentApplication) as? String {
                if pref == "nil" {
                    return nil
                }
                if let index = pref.range(of: ":") {
                    let title = pref.substring(to: index.lowerBound)
                    let year = pref.substring(from: index.upperBound)
                    print(" Parsing : \(title) - \(year)")
                    
                    return Semester.produceSemester(titled: title, in: Int(year)!)
                }
                return nil
                
            } else {
                return Semester.produceSemester(during: Date(), createIfNecessary: true)!
            }
        }
    }
    
    // MARK: -
    private static var cached_openLastSemester: Bool!
    public static var openLastSemester: Bool {
        set {
            if cached_openLastSemester != nil && cached_openLastSemester == newValue { return }
            
            cached_openLastSemester = newValue
            CFPreferencesSetAppValue("openLastSemester" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_openLastSemester != nil {
                return cached_openLastSemester!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("openLastSemester" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_openLastSemester = pref
            } else {
                // Setup default
                self.openLastSemester = true
            }
            return cached_openLastSemester
        }
    }
    
    // MARK: -
    private static var cached_launchWithHappeningCourse: Bool!
    public static var launchWithHappeningCourse: Bool {
        set {
            if cached_launchWithHappeningCourse != nil && cached_launchWithHappeningCourse == newValue { return }
            
            cached_launchWithHappeningCourse = newValue
            CFPreferencesSetAppValue("launchWithHappeningCourse" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_launchWithHappeningCourse != nil {
                return cached_launchWithHappeningCourse!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("launchWithHappeningCourse" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_launchWithHappeningCourse = pref
            } else {
                // Setup default
                self.launchWithHappeningCourse = true
            }
            return cached_launchWithHappeningCourse
        }
    }
    
    // MARK: -
    private static var cached_assumeSingleSelection: Bool!
    public static var assumeSingleSelection: Bool {
        set {
            if cached_assumeSingleSelection != nil && cached_assumeSingleSelection == newValue { return }
            
            cached_assumeSingleSelection = newValue
            CFPreferencesSetAppValue("assumeSingleSelection" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_assumeSingleSelection != nil {
                return cached_assumeSingleSelection!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("assumeSingleSelection" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_assumeSingleSelection = pref
            } else {
                // Setup default
                self.assumeSingleSelection = true
            }
            return cached_assumeSingleSelection
        }
    }

    // MARK: -
    private static var cached_assumePassedCompletion: String!
    /// DAYS:HOURS:MINUTES or nil if never auto completed work
    public static var assumePassedCompletion: String {
        set {
            if cached_assumePassedCompletion != nil && cached_assumePassedCompletion == newValue { return }
            
            cached_assumePassedCompletion = newValue
            CFPreferencesSetAppValue("assumePassedCompletion" as CFString,
                                     newValue as CFString, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_assumePassedCompletion != nil {
                return cached_assumePassedCompletion!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("assumePassedCompletion" as CFString, kCFPreferencesCurrentApplication) as? String {
                cached_assumePassedCompletion = pref
            } else {
                // Setup default
                self.assumePassedCompletion = "0:0:55"
            }
            return cached_assumePassedCompletion
        }
    }
    
    // MARK: -
    private static var cached_assumePassedTaken: String!
    /// DAYS:HOURS:MINUTES or nil if never auto completed exams
    public static var assumePassedTaken: String {
        set {
            if cached_assumePassedTaken != nil && cached_assumePassedTaken == newValue { return }
            
            cached_assumePassedTaken = newValue
            CFPreferencesSetAppValue("assumePassedTaken" as CFString,
                                     newValue as CFString, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_assumePassedTaken != nil {
                return cached_assumePassedTaken!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("assumePassedTaken" as CFString, kCFPreferencesCurrentApplication) as? String {
                cached_assumePassedTaken = pref
            } else {
                // Setup default
                self.assumePassedTaken = "0:0:30"
            }
            return cached_assumePassedTaken
        }
    }

    // MARK: -
    private static var cached_assumeRecentLecture: Bool!
    public static var assumeRecentLecture: Bool {
        set {
            if cached_assumeRecentLecture != nil && cached_assumeRecentLecture == newValue { return }
            
            cached_assumeRecentLecture = newValue
            CFPreferencesSetAppValue("assumeRecentLecture" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_assumeRecentLecture != nil {
                return cached_assumeRecentLecture!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("assumeRecentLecture" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_assumeRecentLecture = pref
            } else {
                // Setup default
                self.assumeRecentLecture = false
            }
            return cached_assumeRecentLecture
        }
    }
    
    // MARK: -
    private static var cached_defaultFallDateRange: ClosedRange<Date>!
    public static var defaultFallDateRange: ClosedRange<Date> {
        set {
            print("Storing new value to defaultFallDateRange: \(newValue.lowerBound) to \(newValue.upperBound)")
            if cached_defaultFallDateRange != nil && cached_defaultFallDateRange == newValue { return }
            
            cached_defaultFallDateRange = newValue
            CFPreferencesSetAppValue("defaultFallStart" as CFString,
                                     newValue.lowerBound as CFDate, kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue("defaultFallEnd" as CFString,
                                     newValue.upperBound as CFDate, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_defaultFallDateRange != nil {
                print("defaultFallDateRange Value was cached.")
                return cached_defaultFallDateRange!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if
                let prefStart = CFPreferencesCopyAppValue("defaultFallStart" as CFString,
                                                         kCFPreferencesCurrentApplication) as? Date,
                let prefEnd = CFPreferencesCopyAppValue("defaultFallEnd" as CFString,
                                                        kCFPreferencesCurrentApplication) as? Date {
                cached_defaultFallDateRange = prefStart...prefEnd
            } else {
                // Setup default
                var comps = DateComponents()
                comps.year = Calendar.current.component(.year, from: Date())
                comps.minute = 0
                comps.hour = 0
                comps.second = 0
                comps.day = 1
                comps.month = 7
                comps.calendar = Calendar.current
                let startDate = Calendar.current.date(from: comps)! // Jul 1, 0:00:00
                comps.minute = 59
                comps.hour = 23
                comps.second = 59
                comps.day = 31
                comps.month = 12
                let endDate = Calendar.current.date(from: comps)! // Dec 31, 23:59:59
                self.defaultFallDateRange = startDate...endDate
            }
            return cached_defaultFallDateRange
        }
    }
    
    // MARK: -
    private static var cached_defaultSpringDateRange: ClosedRange<Date>!
    public static var defaultSpringDateRange: ClosedRange<Date> {
        set {
            if cached_defaultSpringDateRange != nil && cached_defaultSpringDateRange == newValue { return }
            
            cached_defaultSpringDateRange = newValue
            CFPreferencesSetAppValue("defaultSpringStart" as CFString,
                                     newValue.lowerBound as CFDate, kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue("defaultSpringEnd" as CFString,
                                     newValue.upperBound as CFDate, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_defaultSpringDateRange != nil {
                return cached_defaultSpringDateRange!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if
                let prefStart = CFPreferencesCopyAppValue("defaultSpringStart" as CFString,
                                                          kCFPreferencesCurrentApplication) as? Date,
                let prefEnd = CFPreferencesCopyAppValue("defaultSpringEnd" as CFString,
                                                        kCFPreferencesCurrentApplication) as? Date {

                cached_defaultSpringDateRange = prefStart...prefEnd
            } else {
                // Setup default
                var comps = DateComponents()
                comps.year = Calendar.current.component(.year, from: Date())
                comps.minute = 3
                comps.hour = 3
                comps.second = 3
                comps.day = 1
                comps.month = 1
                comps.year = 1993
                comps.calendar = Calendar.current
                let startDate = Calendar.current.date(from: comps)! // Jan 1, 0:00:00
                comps.minute = 59
                comps.hour = 23
                comps.second = 59
                comps.day = 30
                comps.month = 6
                let endDate = Calendar.current.date(from: comps)! // Jun 30, 23:59:59
                self.defaultSpringDateRange = startDate...endDate
            }
            return cached_defaultSpringDateRange
        }
    }
    
    // MARK: -
    private static var cached_waitForFirstLecture: Bool!
    public static var waitForFirstLecture: Bool {
        set {
            if cached_waitForFirstLecture != nil && cached_waitForFirstLecture == newValue { return }
            
            cached_waitForFirstLecture = newValue
            CFPreferencesSetAppValue("waitForFirstLecture" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_waitForFirstLecture != nil {
                return cached_waitForFirstLecture!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("waitForFirstLecture" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_waitForFirstLecture = pref
            } else {
                // Setup default
                self.waitForFirstLecture = false
            }
            return cached_waitForFirstLecture
        }
    }
    
    // MARK: -
    private static var cached_showCurrentTime: Bool!
    public static var showCurrentTime: Bool {
        set {
            if cached_showCurrentTime != nil && cached_showCurrentTime == newValue { return }
            
            cached_showCurrentTime = newValue
            CFPreferencesSetAppValue("showCurrentTime" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_showCurrentTime != nil {
                return cached_showCurrentTime!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("showCurrentTime" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_showCurrentTime = pref
            } else {
                // Setup default
                self.showCurrentTime = true
            }
            return cached_showCurrentTime
        }
    }
    
    // MARK: -
    private static var cached_magnetizedEditor: Bool!
    public static var magnetizedEditor: Bool {
        set {
            if cached_magnetizedEditor != nil && cached_magnetizedEditor == newValue { return }
            
            cached_magnetizedEditor = newValue
            CFPreferencesSetAppValue("magnetizedEditor" as CFString,
                                     newValue as CFBoolean, kCFPreferencesCurrentApplication)
        }
        get {
            if cached_magnetizedEditor != nil {
                return cached_magnetizedEditor!
            }
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
            if let pref = CFPreferencesCopyAppValue("magnetizedEditor" as CFString, kCFPreferencesCurrentApplication) as? Bool {
                cached_magnetizedEditor = pref
            } else {
                // Setup default
                self.magnetizedEditor = true
            }
            return cached_magnetizedEditor
        }
    }
}
