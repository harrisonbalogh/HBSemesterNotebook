//
//  Course+CoreDataClass.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import Cocoa

@objc(Course)
public class Course: NSManagedObject {
    
    /// Set to false whenever a TimeSlot is added, removed, or updated for
    /// the owning Course object. This ensures that sorting will not occur
    /// on a Course that is already sorted.
    var needsSort = true
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    // MARK: - Creating/Retrieving/Producing Objects
    
    /// Returns a newly created TimeSlot object model for this course. Will fail and return nil
    /// if the requested time overlaps another timeSlot in the semester or is within 5 minutes (default, pref value) of
    /// another TimeSlot - this will be ignored if the timeSlot has a -1 weekday. This represents that
    /// the course has not been placed on the schedule - the user cannot go into lectures with any
    /// timeSlots having a -1 weekday property field. NOTE: Temporarily disabled checks since new time slots
    /// should be created using nextTimeSlot(), not newTimeSlot() - in which case nextTimeSlot already checked.
    /// Old description. TimeSlots now have valid flags
    private func createTimeSlot(on weekday: Int, from start: Int, to stop: Int, valid: Bool) -> TimeSlot? {
        
        let newTimeSlot = NSEntityDescription.insertNewObject(forEntityName: "TimeSlot", into: appDelegate.managedObjectContext) as! TimeSlot
        
        newTimeSlot.weekday = Int16(weekday)
        newTimeSlot.startMinute = Int16(start)
        newTimeSlot.stopMinute = Int16(stop)
        newTimeSlot.valid = valid
        newTimeSlot.course = self
        
        return newTimeSlot
    }
    
    /// Returns a newly created Lecture object model for this course following the previous lecture with
    /// the current date. If this is not an absent lecture, then provide nil in the day and month field so
    /// it can be retrieved based on the current date. Otherwise, for the case of an absent lecture, provide
    /// the day and month that this lecture occurred on.
    @discardableResult func createLecture(during timeSlot: TimeSlot, on day: Int?, in month: Int?) -> Lecture {
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        
        // The first theo count will return 0 so change this to lecture 1.
        let lecNumber = max(Int16(self.theoreticalLectureCount()), 1)
        
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        
        newLecture.course = self
        newLecture.timeSlot = timeSlot
        newLecture.number = lecNumber
        newLecture.title = ""
        newLecture.content = NSAttributedString(string: "")
        
        if day == nil || month == nil {
            let cal = Calendar.current
            let date = Date()
            
            newLecture.absent = false
            newLecture.day = Int16(cal.component(.day, from: date))
            newLecture.month = Int16(cal.component(.month, from: date))
        } else {
            // Absent
            newLecture.absent = true
            newLecture.day = Int16(day!)
            newLecture.month = Int16(month!)
        }
        
        return newLecture
    }
    
    /// Returns a newly created Work object model for this course.
    func createWork() -> Work {
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        
        let newWork = NSEntityDescription.insertNewObject(forEntityName: "Work", into: appDelegate.managedObjectContext) as! Work
        
        newWork.course = self
        newWork.title = nextWorkTitleAvailable(with: "Undated Work ")
        newWork.content = ""
        newWork.customTitle = false
        newWork.createDate = Date()
        
        return newWork
    }
    
    /// Returns a newly created Test object model for this course.
    func createTest() -> Test {
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        
        let newTest = NSEntityDescription.insertNewObject(forEntityName: "Test", into: appDelegate.managedObjectContext) as! Test
        
        newTest.course = self
        newTest.title = nextTestTitleAvailable(with: "Undated Test ")
        newTest.content = ""
        newTest.customTitle = false
        newTest.createDate = Date()
        
        return newTest
    }
    
    /// Return the lecture at the given date, or nil if none exists.
    func retrieveLecture(on date: Date) -> Lecture? {
        
        let cal = Calendar.current

        let weekday = Int16(cal.component(.weekday, from: date))
        let minuteOfDay = Int16(cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date))
        
        for case let lecture as Lecture in self.lectures! {

            let lecWeekday = Int16(cal.component(.weekday, from: Date()))
            let lecStartMinute = lecture.timeSlot!.startMinute
            let lecStopMinute = lecture.timeSlot!.stopMinute
            
            if weekday == lecWeekday && minuteOfDay >= lecStartMinute - 5 && minuteOfDay < lecStopMinute {
                // during class lecture
                return lecture
            }
        }
        // no lecture
        return nil
    }
    
    /// Retrieves the course with unique name for this semester. Return nil if
    /// course not found. Will not return work that has been marked as completed.
    public func retrieveWork(named: String) -> Work! {
        for case let work as Work in self.work! {
            if !work.completed && work.title!.lowercased() == named.lowercased() {
                return work
            }
        }
        return nil
    }
    
    /// Retrieves the course with unique name for this semester. Return nil if
    /// course not found. Will not return a test that has been marked as completed.
    public func retrieveTest(named: String) -> Test! {
        for case let test as Test in self.tests! {
            if !test.completed && test.title!.lowercased() == named.lowercased() {
                return test
            }
        }
        return nil
    }
    
    // MARK: - Schedule Assistant Helper Functions
    
    /// Returns the time slot that is currently happening for this course
    func duringTimeSlot() -> TimeSlot? {
        
        if self.semester!.needsValidate {
            self.semester!.validateSchedule()
        }
        if !self.valid {
            return nil
        }
        
        // This func assumes course timeslots are sorted.
        if self.needsSort {
            self.sortTimeSlots()
        }
        
        let cal = Calendar.current
        
        let weekday = Int16(cal.component(.weekday, from: Date()))
        let minuteOfDay = Int16(cal.component(.hour, from: Date()) * 60 + cal.component(.minute, from: Date()))
        
        for case let time as TimeSlot in self.timeSlots! {
            let timeDay = time.weekday
            let timeStart = time.startMinute
            let timeStop = time.stopMinute
            
            if weekday == timeDay && timeStart - 5 < minuteOfDay && minuteOfDay < timeStop {
                // during class period
                return time
            } else if weekday < timeDay || (weekday == timeDay && minuteOfDay < timeStart - 5){
                // Timeslots are sorted, so we don't need to continue searching past today's date
                break
            }
        }
        return nil
    }
    
    /// Will return true if work had to be marked as completed. Will return false if no work
    /// was updated.
    @discardableResult func checkWork() -> Bool {
        
        var needsReload = false
        
        var autoDays = 0
        var autoHours = 0
        var autoMins = 55
        if let assumeComplete = CFPreferencesCopyAppValue(NSString(string: "assumePassedCompletion"), kCFPreferencesCurrentApplication) as? String {
            if assumeComplete == "nil" {
                // Preference has been set to not automatically complete work. So return false
                return false
            } else {
                let parseDays = assumeComplete.substring(to: (assumeComplete.range(of: ":")?.lowerBound)!)
                let remain = assumeComplete.substring(from: (assumeComplete.range(of: ":")?.upperBound)!)
                let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                autoDays = Int(parseDays)!
                autoHours = Int(parseHrs)!
                autoMins  = Int(parseMins)!
            }
        }
        
        let date = Date()
        
        for case let work as Work in self.work! {
            
            if work.completed {
                continue
            }

            guard let workDate = work.date else { continue }
            
            var workDateWithAssume = workDate.addingTimeInterval(TimeInterval(autoDays * 24 * 60 * 60))
            workDateWithAssume = workDateWithAssume.addingTimeInterval(TimeInterval(autoHours * 60 * 60))
            workDateWithAssume = workDateWithAssume.addingTimeInterval(TimeInterval(autoMins * 60))
            
            if date.timeIntervalSince(workDateWithAssume) >= 0 {
                // Reached or passed the due date for this work
                needsReload = true
                work.completed = true
                let _ = Alert(course: self, content: "\(work.title!) has been marked as completed.", question: nil, deny: "Close", action: nil, target: nil, type: .completed)
            }
        }

        return needsReload
    }
    
    /// Will return true if a test had to be marked as completed. Will return false if no test
    /// was updated.
    @discardableResult func checkTests() -> Bool {
        
        var needsReload = false
        
        var autoDays = 0
        var autoHours = 0
        var autoMins = 55
        if let assumeTaken = CFPreferencesCopyAppValue(NSString(string: "assumePassedTaken"), kCFPreferencesCurrentApplication) as? String {
            if assumeTaken == "nil" {
                // Preference has been set to not automatically complete work. So return false
                return false
            } else {
                let parseDays = assumeTaken.substring(to: (assumeTaken.range(of: ":")?.lowerBound)!)
                let remain = assumeTaken.substring(from: (assumeTaken.range(of: ":")?.upperBound)!)
                let parseHrs = remain.substring(to: (remain.range(of: ":")?.lowerBound)!)
                let parseMins = remain.substring(from: (remain.range(of: ":")?.upperBound)!)
                autoDays = Int(parseDays)!
                autoHours = Int(parseHrs)!
                autoMins  = Int(parseMins)!
            }
        }
        
        let date = Date()
        
        for case let test as Test in self.tests! {
            
            if test.completed {
               continue
            }
            
            guard let testDate = test.date else { continue }
            
            var testDateWithAssume = testDate.addingTimeInterval(TimeInterval(autoDays * 24 * 60 * 60))
            testDateWithAssume = testDateWithAssume.addingTimeInterval(TimeInterval(autoHours * 60 * 60))
            testDateWithAssume = testDateWithAssume.addingTimeInterval(TimeInterval(autoMins * 60))
            
            if date.timeIntervalSince(testDateWithAssume) >= 0 {
                // Reached or passed the due date for this work
                needsReload = true
                test.completed = true
                
                let _ = Alert(course: self, content: "\(test.title!) has been marked as completed.", question: nil, deny: "Close", action: nil, target: nil, type: .completed)
            }
        }
        
        return needsReload
    }
    
    // MARK: - Calculated Properties
    
    /// The number of lectures there should be up to the current time. This can only be
    /// calculated after the first lecture has been added. This method only works if the 
    /// lectures orderedSet is sorted. If this function returns zero, it means there aren't
    /// any courses yet. Verified multiple times to be performing the correct logic.
    func theoreticalLectureCount() -> Int {
        // Zero is only returned for a course that hasn't started yet.
        if lectures!.count == 0 {
            return 0
        }
        
        guard let firstLecture = self.lectures![0] as? Lecture else { return 0 }
        
        let cal = Calendar.current
        let date = Date()
        var count = 0
        
        var monthDays: [Int16] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        if cal.component(.year, from: date) == 2020 {
            // Leap year
            monthDays[2] = 29
        }
        
        // Calculate week disparity...
        // ... start with day/month dates
        let monthToday = Int16(cal.component(.month, from: date))
        let dayToday = Int16(cal.component(.day, from: date))
        let monthFirst = firstLecture.month
        let dayFirst = firstLecture.day
    
        // ... calculate days between two dates
        var days: Int16 = 0
        if monthToday - monthFirst >= 0 {
            for m in monthFirst...monthToday {
                days += monthDays[Int(m)]
            }
        } else {
            // Correct for special case where monthLast to monthToday rolls over a calendar year
            for m in monthFirst...12 {
                days += monthDays[Int(m)]
            }
            for m in 1...monthToday {
                days += monthDays[Int(m)]
            }
        }
        days -= dayFirst
        days -= monthDays[Int(monthToday)] - dayToday
        
        // ... weeks between two dates
        count = Int(days / 7)
        
        // ... use lectures-per-week as unadjusted count
        count *= self.timeSlots!.count

        // ... first adjustment: if first lecture was offset from the start of the week.
        if self.needsSort {
            // Timeslots msut be sorted for this to proceed properly
            self.sortTimeSlots()
        }
        let indexFirst = self.timeSlots!.index(of: firstLecture.timeSlot!)
        
        var indexToday = 0
        let minuteOfDay = Int16(cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date))
        let weekdayToday = Int16(cal.component(.weekday, from: date))
        for case let time as TimeSlot in self.timeSlots! {
            let timeDay = time.weekday
            let timeStart = time.startMinute
            // count increases with number of timeslots that passed for a week
            if timeDay < weekdayToday {
                indexToday += 1
            } else if timeDay == weekdayToday && timeStart - 5 < minuteOfDay {
                indexToday += 1
            } else {
                break
            }
        }
        if indexToday == 0 {
            indexToday = self.timeSlots!.count - 1
        } else {
            indexToday -= 1
        }
        
        if indexToday - indexFirst < 0 {
            // Rolled over to next week
            count += self.timeSlots!.count - indexFirst + indexToday + 1
        } else {
            count += indexToday - indexFirst + 1
        }
        
        return count
    }
    
    /// Sort the time slots of this course to be in order of weekday and then by startMinuteOfDay.
    /// This runs slower than an insertion sort but is not called often and doesn't have many elements.
    /// Must be called before returning the theoreticalLectureCount() of a course. Logic verified.
    func sortTimeSlots() {
        
        // Re-sort the timeslots for this course object. Inefficient, backwards insertion sort.
        let sortedSet = NSMutableOrderedSet()
        for case let unsortedTimeSlot as TimeSlot in self.timeSlots! {
            
            let unsortedDay = unsortedTimeSlot.weekday
            let unsortedStart = unsortedTimeSlot.startMinute
            
            // First element being sorted, don't check, just add it.
            if sortedSet.count != 0 {
                
                var index = 0
                for case let sortedTimeSlot as TimeSlot in sortedSet {
                    
                    let sortedDay = sortedTimeSlot.weekday
                    let sortedStart = sortedTimeSlot.startMinute
                    
                    // If the unsortedTimeSlot is earlier than the sortedTimeSlot, insert it.
                    if unsortedDay == sortedDay {
                        if unsortedStart < sortedStart {
                            sortedSet.insert(unsortedTimeSlot, at: index)
                            break
                        }
                    } else if unsortedDay < sortedDay {
                        sortedSet.insert(unsortedTimeSlot, at: index)
                        break
                    }
                    // Otherwise continue to check next sortedTimeSlot... unless it was the last sorted element.
                    index += 1
                    if index == sortedSet.count {
                        // Reached end of inner loop, append this time slot
                        sortedSet.add(unsortedTimeSlot)
                    }
                }
            } else {
                // First element being added
                sortedSet.add(unsortedTimeSlot)
            }
        }
        
        self.timeSlots = sortedSet
        appDelegate.saveAction(self)
    }
    
    /// Will return a printable version of the days that the course occupies. Ex: "M,W".
    func daysPerWeekPrintable() -> String {
        var daysOfWeek = [0, 0, 0, 0, 0, 0, 0, 0]
        let dayNames = ["", "Su", "M", "T", "W", "Th", "F", "Su"]
        for case let time as TimeSlot in self.timeSlots! {
            let timeDay = Int(time.weekday)
            if timeDay != -1 {
                daysOfWeek[Int(timeDay)] = 1
            }
        }
        var constructedString = ""
        // Consecutive additions need a comma
        for d in 1...7 {
            if daysOfWeek[d] == 1 {
                if constructedString == "" {
                    constructedString = (dayNames[d])
                }else {
                    constructedString += ("," + dayNames[d])
                }
            }
        }
        return constructedString
    }
    
    /// Will return a printable version of this courses schedule. Includes days and times.
    func schedulePrintable() -> String {
//        var constructedString = ""
        
//        var daysOfWeek = [0, 0, 0, 0, 0, 0, 0, 0] // daysOfWeek[0] isn't used. Index starts at 1.
//        let dayNames = ["", "Sun.", "Mon.", "Tue.", "Wed.", "Thu.", "Fri.", "Sat."] // Index starts at 1.
//        for d in 1...7 {
//            var times = [TimeSlot]()
//            for case let time as TimeSlot in self.timeSlots! {
//                
//                if time.day == Int16(d) {
//                    // Insert day name first time
//                    if daysOfWeek[d] == 0 {
//                        daysOfWeek[d] = 1
//                        constructedString += dayNames[d] + ":"
//                    }
//                    //
//                    times.append(time)
//                }
//            }
//            if times.count == 0 {
//                continue
//            } else if times.count == 1 {
//                constructedString += " \(HXTimeFormatter.formatTime(times[0]+8))-\(HXTimeFormatter.formatTime(times[0]+9))      "
//                continue
//            }
//            times.sort()
//            var prevTime: Int16 = times[0] + 8
//            var timeSpan: Int16 = 0
//            for t in 1..<times.count {
//                if (times[t]+8) == (prevTime + 1){
//                    // Adjacent time
//                    if t == times.count - 1 {
//                        constructedString += " \(HXTimeFormatter.formatTime(prevTime - timeSpan))-\(HXTimeFormatter.formatTime(prevTime + 2))"
//                    }
//                    timeSpan += 1
//                } else {
//                    // Not adjacent time
//                    constructedString += " \(HXTimeFormatter.formatTime(prevTime - timeSpan))-\(HXTimeFormatter.formatTime(prevTime + 1))"
//                    // Reset time span
//                    timeSpan = 0
//                    if t == times.count - 1 {
//                        constructedString += " \(HXTimeFormatter.formatTime(times[t] + 8 - timeSpan))-\(HXTimeFormatter.formatTime(times[t] + 9))"
//                    }
//                    
//                }
//                // Update previous time
//                prevTime = times[t] + 8
//            }
//            constructedString += "      "
//        }
        
        return ""
    }
    
    /// Checks if using the given attributes to create a TimeSlot will conflict with any other
    /// TimeSlots.
    private func proposeTimeSlot(on weekday: Int, from startA: Int, to stopA: Int) -> Bool {
        for case let course as Course in self.semester!.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                
                let timeDay = Int(timeSlot.weekday)
                
                if weekday == timeDay {
                    
                    let startB = Int(timeSlot.startMinute)
                    let stopB = Int(timeSlot.stopMinute)
                    
                    if (startA <= startB && startB < stopA) ||
                        (startA < stopB && stopB < stopB) ||
                        (startB <= startA && startA <= stopB) {
                        // Conflicting time
                        return false
                    }
                }
            }
        } 
        return true
    }
    
    // MARK: - Convenience Functions
    
    /// Will fill all the absent lectures for a given course. Note this runs
    /// the duringTimeSlot method. May be inefficient if fillAbsentLectures is always called
    /// after duringCourse or duringTimeSlot gets called. The TimeSlots for this course must
    /// be guaranteed to be sorted else it will produce incorrect results.
    func fillAbsentLectures() {
        
        print("filAbsentLectures")
        return
        
        // This function doesn't do anything if course hasn't started yet.
        if self.lectures!.count == 0 {
            return
        }
        
        guard let lastLecture = self.lectures!.lastObject as? Lecture else { return }
        
        var lecturesToFill = self.theoreticalLectureCount() - self.lectures!.count
        
        // If there is a time slot currently in progress, do not yet add an absent lecture for it, so reduce number
        // to fill in since theoreticalLectureCount includes courses based on start time - not finish time.
        if self.duringTimeSlot() != nil {
            lecturesToFill -= 1
        }
        
        // No lectures to create if the amount of lectures is the same as the expected amount of lectures to this date
        if lecturesToFill <= 0 {
            return
        }
        
        if needsSort {
            self.sortTimeSlots()
        }
        
        let monthDays = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        
        let lastTimeSlotIndex = self.timeSlots!.index(of: lastLecture.timeSlot!)
        for x in 0..<(lecturesToFill) {
            let nextTimeDay = (self.timeSlots![(lastTimeSlotIndex + x + 1) % self.timeSlots!.count] as! TimeSlot).weekday
            let thisTimeDay = (self.timeSlots![(lastTimeSlotIndex + x) % self.timeSlots!.count] as! TimeSlot).weekday
            
            let daysBtwnLec = nextTimeDay - thisTimeDay
            
            let nextLecMonth = Int(lastLecture.month) + Int(Int(lastLecture.day + daysBtwnLec) / monthDays[Int(lastLecture.month)])
            let nextLecDay = Int(lastLecture.day + daysBtwnLec) % monthDays[Int(lastLecture.month)]
            
            let _ = createLecture(during: self.timeSlots![(lastTimeSlotIndex + 1 + x) % self.timeSlots!.count] as! TimeSlot,
                                  on: nextLecDay, in: nextLecMonth)
        }
    }
    
    /// Will produce the next available time slot with a default length (pref changeable) of 55 minutes. Can still return
    /// nil but this would mean every day has a full schedule... Starts at 8:00AM and searches each day
    /// before 10:00PM.
    func nextTimeSlotSpace() -> TimeSlot {
        
        var courseLength = 55
        if let defaultTimeSpan = CFPreferencesCopyAppValue(NSString(string: "defaultCourseTimeSpanMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(defaultTimeSpan) {
                courseLength = time
            }
        }
        
        var bufferTime = 5
        if let bufferTimePref = CFPreferencesCopyAppValue(NSString(string: "bufferTimeBetweenCoursesMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(bufferTimePref) {
                bufferTime = time
            }
        }
        
        var startTime = 480
        var stopTime = startTime + courseLength
        var weekday = 1
        var timeAvailableOnDay = true
        
        for _ in 1...7 {
            timeAvailableOnDay = false
            weekday += 1
            if weekday == 8 {
                weekday = 1 // Reset to Sunday if passing Saturday
            }
            // While statement ensures if the start/stopTime must be shifted, it will loop through everything again.
            // Unless it got through every course and accompanying timeslots that day without conflicts OR if past
            // 10:00PM stop time.
            while stopTime <= 1320 && !timeAvailableOnDay {
                timeAvailableOnDay = proposeTimeSlot(on: weekday, from: startTime - bufferTime, to: stopTime + bufferTime)
                if !timeAvailableOnDay {
                    startTime += courseLength + bufferTime
                    stopTime = startTime + courseLength
                }
            }
            if timeAvailableOnDay {
                // Got through every course:timeSlot pair for a given day without conflicts. So the time is available
                return createTimeSlot(on: weekday, from: startTime, to: stopTime, valid: true)!
            } else {
                // The time was not available today, so reset the start and stop time
                startTime = 480
                stopTime = startTime + courseLength
            }
        }
        return createTimeSlot(on: 2, from: 480, to: 535, valid: false)!
    }
    
    /// From the current date:time, get the next timeSlot that will occur.
    func nextTimeSlot() -> TimeSlot {
        if needsSort {
            self.sortTimeSlots()
        }
        
        let date = Date()
        let cal = Calendar.current
        
        let weekday = Int16(cal.component(.weekday, from: date))
        let minuteOfDay = Int16(cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date))
        
        // Iterate until the first TimeSlot that is not before the current time
        for case let timeSlot as TimeSlot in self.timeSlots! {
            if weekday < timeSlot.weekday || (weekday == timeSlot.weekday && timeSlot.startMinute < minuteOfDay) {
                continue
            }
            return timeSlot
        }
        // Otherwise we're passed all TimeSlots, so roll over to next week and return the first TimeSlot.
        return self.timeSlots!.firstObject as! TimeSlot
    }
    /// See nextTimeSlot() - this version returns the index of the TimeSlot rather than the TimeSlot itself.
    func nextTimeSlotIndex() -> Int {
        if needsSort {
            self.sortTimeSlots()
        }
        
        let date = Date()
        let cal = Calendar.current
        
        let weekday = Int16(cal.component(.weekday, from: date))
        let minuteOfDay = Int16(cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date))
        
        var index = 0
        
        for case let timeSlot as TimeSlot in self.timeSlots! {
            if weekday > timeSlot.weekday || (weekday == timeSlot.weekday && timeSlot.startMinute < minuteOfDay) {
                index += 1
                continue
            }
            return index
        }
        return 0
    }
    
    // MARK: - Creation Helper Functions
    
    /// Return the first title available in the semester for work with the
    /// specified prefixed title text. Example: nextWorkTitleAvailable(with: "Undated Work ")
    public func nextWorkTitleAvailable(with prefix: String) -> String {
        // Find next available number for naming Work
        var nextWorkNumber = 1
        var seekingNumber = true
        repeat {
            if (retrieveWork(named: prefix + "\(nextWorkNumber)")) == nil {
                seekingNumber = false
            } else {
                nextWorkNumber += 1
            }
        } while(seekingNumber)
        
        return prefix + "\(nextWorkNumber)"
    }
    
    /// Return the first title available in the semester for a test with the
    /// specified prefixed title text. Example: nextTestTitleAvailable(with: "Undated Test ")
    public func nextTestTitleAvailable(with prefix: String) -> String {
        // Find next available number for naming Work
        var nextTestNumber = 1
        var seekingNumber = true
        repeat {
            if (retrieveTest(named: prefix + "\(nextTestNumber)")) == nil {
                seekingNumber = false
            } else {
                nextTestNumber += 1
            }
        } while(seekingNumber)
        
        return prefix + "\(nextTestNumber)"
    }
}
