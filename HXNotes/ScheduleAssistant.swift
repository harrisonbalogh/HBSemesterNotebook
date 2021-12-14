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

        self.currentSemester = Semester.produceSemester(during: Date(), createIfNecessary: true)!
        
        super.init()
        
        masterVC = masterController
        
        // Start minute checks
        let minuteComponent = Calendar.current.component(.second, from: Date())
        self.perform(#selector(self.notifyMinute), with: nil, afterDelay: Double(60 - minuteComponent))
    }
    
    // MARK: ––– Schedule Checks –––
    
    /// Check for upcoming courses - should be adjustable in settings. This is used to
    /// provide an alert that a course will be starting in x minutes.
    func checkFuture() {
        
        // Alerts only occur at 5 minute markers: 5,10,15,20,etc
        let minute = NSCalendar.current.component(.minute, from: Date())
        if minute % 5 == 0 {
            
            // Continue only if we can get the current semester and if a course will happen in future
            guard
                let currentSemester = Semester.produceSemester(during: Date(), createIfNecessary: false),
                let futureTimeSlot = currentSemester.futureTimeSlot()
                else { return }
            
            let hour = NSCalendar.current.component(.hour, from: Date())
            
            let timeTill = Int(futureTimeSlot.startMinute) - (hour*60 + minute)
            
            let _ = Alert(hour: hour, minute: minute, course: futureTimeSlot.course!, content: "lecture \(futureTimeSlot.course!.theoreticalLectureCount()) is starting in \(timeTill) minutes.", question: nil, deny: "Close", action: nil, target: nil, type: .future)
        }
    }
    
    /// Check if a course is currently happening. This is used to display a "Start Lecture" alert.
    /// Will return if a course is happening but it is discardable.
    @discardableResult func checkHappening() -> Bool {
        
        // Proceed only if found semester and a course lecture is underway
        guard
            let currentSemester = Semester.produceSemester(during: Date(), createIfNecessary: false),
            let timeSlotHappening = currentSemester.duringCourse()
            else { return false }
        
        if timeSlotHappening.course!.lectures!.count == 0 {
            // This is the first lecture
            let cal = Calendar.current
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
            
            // Notify the static button to appear if necessary
            if masterVC.selectedCourse == timeSlotHappening.course {
                masterVC.sidebarPageController.courseVC.addButton.isEnabled = true
                masterVC.sidebarPageController.courseVC.addButton.isHidden = false
            }
            
            let _ = Alert(hour: timeHour, minute: timeMinute, course: timeSlotHappening.course!, content: appendTimeUntilLecture + " Create first lecture?", question: "Yes (Start Course)", deny: "No (Not Yet)", action: #selector(masterVC.addLecture), target: masterVC, type: .happening)
            return true
            
        } else if Int((timeSlotHappening.course!.lectures?.lastObject as! Lecture).number) != timeSlotHappening.course!.theoreticalLectureCount() {
            // This is not the first lecture and the latest lecture has not been created
            let theoLecCount = timeSlotHappening.course!.theoreticalLectureCount()
            
            if theoLecCount != timeSlotHappening.course!.lectures!.count {
                let date = Date()
                let cal = Calendar.current
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
                
                // Notify the static button to appear if necessary
                if masterVC.selectedCourse == timeSlotHappening.course {
                    masterVC.sidebarPageController.courseVC.addButton.isEnabled = true
                    masterVC.sidebarPageController.courseVC.addButton.isHidden = false
                    masterVC.sidebarPageController.courseVC.addButton.title = "Lecture \(masterVC.selectedCourse.theoreticalLectureCount())"
                }
                
                // No lecture exists for this time so give alert
                let _ = Alert(hour: timeHour, minute: timeMinute, course: timeSlotHappening.course!, content: appendTimeUntilLecture + " Create lecture \(theoLecCount)?", question: "Create Lecture \(timeSlotHappening.course!.theoreticalLectureCount())", deny: "Ignore", action: #selector(masterVC.addLecture), target: masterVC, type: .happening)
                return true
            }
        }
        return false
    }
    
    /// Check if a course was just missed. This will remove any .happening alerts for the
    /// missed course and inform the SidebarVC that an absent course should be inserted.
    func checkMissed() {
        
        Alert.checkExpiredAlerts()
        
        if masterVC.selectedCourse != nil {
            if masterVC.selectedCourse.fillAbsentLectures() {
                masterVC.sidebarCourseNeedsPopulating(masterVC.sidebarPageController.courseVC)
            }
        }
        
    }
    
    // MARK: ––– Timers –––
    
    /// Do not call this method. A perform() is called and reset on this notifyMinute selector.
    @objc func notifyMinute() {
        // regress to recalculating the minute
        let remainingMinute = 60 - Calendar.current.component(.second, from: Date())
        self.perform(#selector(self.notifyMinute), with: nil, afterDelay: TimeInterval(remainingMinute))
        // Place below anything to happen on the minute marker...
        
        checkFuture()
        checkHappening()
//        checkMissed()
        
        if masterVC.selectedCourse != nil {
            if masterVC.selectedCourse.checkWork() {
                masterVC.schedulingUpdatedWork()
            }
            if masterVC.selectedCourse.checkTests() {
                masterVC.schedulingUpdateTest()
            }
        }
        
        masterVC.drawTimeBox.needsDisplay = true
        masterVC.drawTimeBox.display()
    }
}
