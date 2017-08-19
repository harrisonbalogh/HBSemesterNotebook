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
    let currentSemester: Semester
    
    // MARK: ___ Initialization ___
    init(masterController: MasterViewController) {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        self.currentSemester = Semester.produceSemester(titled: semesterTitle, in: yearComponent)
        
        super.init()
        
        masterVC = masterController
        
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
        
        // Continue only if we can get the current semester and if a course will happen in future
        guard
            let currentSemester = Semester.retrieveSemester(titled: semesterTitle, in: yearComponent),
            let futureTimeSlot = currentSemester.futureTimeSlot()
            else { return }
        print("Gotteee")
        let hour = NSCalendar.current.component(.hour, from: Date())
        let minute = NSCalendar.current.component(.minute, from: Date())
        
        if minute % 5 == 0 {
            
            let timeTill = Int(futureTimeSlot.startMinute % 60) - minute
            
            let _ = Alert(hour: hour, minute: minute, course: futureTimeSlot.course!, content: "is starting in \(timeTill) minutes.", question: nil, deny: "Close", action: nil, target: nil, type: .future)
        }
    }
    
    /// Check if a course is currently happening. This is used to display a "Start Lecture" alert.
    func checkHappening() {
        
        let cal = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = cal.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if cal.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        
        // Proceed only if found semester and a course lecture is underway
        guard
            let currentSemester = Semester.retrieveSemester(titled: semesterTitle, in: yearComponent),
            let timeSlotHappening = currentSemester.duringCourse()
            else { return }
        
        if timeSlotHappening.course!.lectures!.count == 0 {
            // This is the first lecture

            let timeHour = Int(timeSlotHappening.startMinute / 60)
            let timeMinute = Int(timeSlotHappening.startMinute % 60)
            let timeStart = timeHour * 60 + timeMinute
            let minuteOfDay = cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date())
            
            // Adjust alert phrasing for various time scenarios
            var appendTimeUntilLecture = ""
            if minuteOfDay < timeStart - 1 {
                appendTimeUntilLecture = "is starting in \(timeStart - minuteOfDay) minutes."
            } else if minuteOfDay < timeStart {
                appendTimeUntilLecture = "is starting in \(timeStart - minuteOfDay) minute."
            } else if minuteOfDay == timeStart || minuteOfDay == timeStart + 1 {
                appendTimeUntilLecture = "is starting now."
            } else {
                appendTimeUntilLecture = "started \(minuteOfDay - timeStart) minutes ago."
            }
            
            let _ = Alert(hour: timeHour, minute: timeMinute, course: timeSlotHappening.course!, content: appendTimeUntilLecture + " Create first lecture?", question: "Yes (Start Course)", deny: "No (Not Yet)", action: #selector(masterVC.sidebarViewController.addLecture), target: masterVC.sidebarViewController, type: .happening)
        
        } else {
            // This is not the first lecture
            let theoLecCount = timeSlotHappening.course!.theoreticalLectureCount()
            
            if theoLecCount != timeSlotHappening.course!.lectures!.count {
                let date = Date()
                let minuteOfDay = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
                let timeHour = Int(timeSlotHappening.startMinute / 60)
                let timeMinute = Int(timeSlotHappening.startMinute % 60)
                let timeStart = timeHour * 60 + timeMinute
                
                // Adjust alert phrasing for various time scenarios
                var appendTimeUntilLecture = ""
                if minuteOfDay < timeStart - 1 {
                    appendTimeUntilLecture = "is starting in \(timeStart - minuteOfDay) minutes."
                } else if minuteOfDay < timeStart {
                    appendTimeUntilLecture = "is starting in \(timeStart - minuteOfDay) minute."
                } else if minuteOfDay == timeStart || minuteOfDay == timeStart + 1 {
                    appendTimeUntilLecture = "is starting now."
                } else {
                    appendTimeUntilLecture = "started \(minuteOfDay - timeStart) minutes ago."
                }
                
                // No lecture exists for this time so give alert
                let _ = Alert(hour: timeHour, minute: timeMinute, course: timeSlotHappening.course!, content: appendTimeUntilLecture + " Create lecture \(theoLecCount)?", question: "Create Lecture \(timeSlotHappening.course!.theoreticalLectureCount())", deny: "Ignore", action: #selector(masterVC.sidebarViewController.addLecture), target: masterVC.sidebarViewController, type: .happening)
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
        // regress to recalculating the minute
        let remainingMinute = 60 - Calendar.current.component(.second, from: Date())
        self.perform(#selector(self.notifyMinute), with: nil, afterDelay: TimeInterval(remainingMinute))
        // Place below anything to happen on the minute marker...
        
        checkFuture()
        checkHappening()
        checkMissed()
    }
}
