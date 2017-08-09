//
//  ScheduleAssistant.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/5/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class ScheduleAssistant: NSObject {
    
    weak var masterVC: MasterViewController!
    
    // MARK: ___ Initialization ___
    init(masterController: MasterViewController) {
        super.init()
        
        masterVC = masterController
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Start minute checks
        let minuteComponent = calendar.component(.minute, from: Date())
        self.perform(#selector(self.notifyMinute), with: nil, afterDelay: Double(60 - minuteComponent))
    }
    
    // MARK: ––– Schedule Checks –––
    
    /// Check for upcoming courses - should be adjustable in settings. This is used to
    /// provide an alert that a course will be starting in x minutes.
    func checkFuture() {
        
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
            if let futureCourse = currentSemester.futureCourse() {
                
                let hour = NSCalendar.current.component(.hour, from: Date())
                let minute = NSCalendar.current.component(.minute, from: Date())
                
                if minute % 5 == 0 {
                    
                    let _ = Alert(hour: hour, minute: minute, course: futureCourse.title!, content: "is starting in \(60 - minute) minutes.", question: nil, deny: "Close", action: nil, target: nil, type: .future)
                } else {
                    print("   nope.")
                }
            }
        }
    }
    
    /// Check if a course is currently happening. This is used to display a "Start Lecture" alert.
    func checkHappening() {
        
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
                
                let hour = NSCalendar.current.component(.hour, from: Date())
                let minute = NSCalendar.current.component(.minute, from: Date())
                let minuteOfDay = hour * 60 + minute
                
                let weekDay = NSCalendar.current.component(.weekday, from: Date())
                let weekOfYear = NSCalendar.current.component(.weekOfYear, from: Date())
                
                // Check if this is the first lecture
                if timeSlotHappening.course!.theoreticalLectureCount() == 0 && timeSlotHappening.course!.lectures!.count == 0 {
                    
                    // Alert english details for specific time of lecture
                    var appendTimeUntilLecture = ""
                    if minuteOfDay < timeSlotHappening.startMinuteOfDay - 1 {
                        appendTimeUntilLecture = "is starting in \(timeSlotHappening.startMinuteOfDay - minuteOfDay) minutes."
                    } else if Int16(minuteOfDay) < timeSlotHappening.startMinuteOfDay {
                        appendTimeUntilLecture = "is starting in \(timeSlotHappening.startMinuteOfDay - minuteOfDay) minute."
                    } else if Int16(minuteOfDay) == timeSlotHappening.startMinuteOfDay || Int16(minuteOfDay) == timeSlotHappening.startMinuteOfDay + 1 {
                        appendTimeUntilLecture = "is starting now."
                    } else {
                        appendTimeUntilLecture = "started \(Int16(minuteOfDay) - timeSlotHappening.startMinuteOfDay) minutes ago."
                    }
                    
                    
                    let _ = Alert(hour: hour, minute: 0, course: timeSlotHappening.course!.title!, content: appendTimeUntilLecture + " Create first lecture?", question: "Yes (Start Course)", deny: "No (Not Yet)", action: #selector(masterVC.sidebarViewController.addLecture), target: masterVC.sidebarViewController, type: .happening)
                } else {
                    
                    // It's not the first lecture, so check if a lecture was already made for this course.
                    if timeSlotHappening.course!.retrieveLecture(on: weekDay, in: weekOfYear, at: minuteOfDay) == nil {
                        
                        // Alert english details for specific time of lecture
                        var appendTimeUntilLecture = ""
                        if minuteOfDay < timeSlotHappening.startMinuteOfDay - 1 {
                            appendTimeUntilLecture = "is starting in \(timeSlotHappening.startMinuteOfDay - minuteOfDay) minutes."
                        } else if Int16(minuteOfDay) < timeSlotHappening.startMinuteOfDay {
                            appendTimeUntilLecture = "is starting in \(timeSlotHappening.startMinuteOfDay - minuteOfDay) minute."
                        } else if Int16(minuteOfDay) == timeSlotHappening.startMinuteOfDay || Int16(minuteOfDay) == timeSlotHappening.startMinuteOfDay + 1 {
                            appendTimeUntilLecture = "is starting now."
                        } else {
                            appendTimeUntilLecture = "started \(Int16(minuteOfDay) - timeSlotHappening.startMinuteOfDay) minutes ago."
                        }
                        
                        // No lecture exists for this time so give alert
                        let _ = Alert(hour: hour, minute: 0, course: timeSlotHappening.course!.title!, content: appendTimeUntilLecture + " Create lecture \(timeSlotHappening.course!.theoreticalLectureCount())?", question: "Create Lecture \(timeSlotHappening.course!.theoreticalLectureCount())", deny: "Ignore", action: #selector(masterVC.sidebarViewController.addLecture), target: masterVC.sidebarViewController, type: .happening)
                    }
                }
            }
        }
    }
    
    /// Check if a course was just missed. This will remove any .happening alerts for the
    /// missed course and inform the SidebarVC that an absent course should be inserted.
    func checkMissed() {
        
        Alert.checkExpiredAlerts()
        
    }
    
    // MARK: ––– Timers –––
    
    /// Do not call this method. A perform() is called and reset on this notifyMinute selector.
    func notifyMinute() {
        
        checkFuture()
        checkHappening()
        checkMissed()
        
        // Place code above. The following resets timer. Do not alter.
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let dateComponent = calendar.component(.second, from: Date())
        self.perform(#selector(self.notifyMinute), with: nil, afterDelay: Double(60 - dateComponent))
    }
    
}
