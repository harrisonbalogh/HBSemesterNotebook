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
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    // MARK: Creating/Retrieving/Producing Objects
    
    /// Returns a newly created TimeSlot object model for this course. Will fail and return nil
    /// if the requested time overlaps another timeSlot in the semester or is within 5 minutes of
    /// another TimeSlot - this will be ignored if the timeSlot has a -1 weekday. This represents that
    /// the course has not been placed on the schedule - the user cannot go into lectures with any
    /// timeSlots having a -1 weekday property field. NOTE: Temporarily disabled checks since new time slots
    /// should be created using nextTimeSlot(), not newTimeSlot() - in which case nextTimeSlot already checked.
    private func createTimeSlot(on weekday: Int16, from startMinuteOfDay: Int16, to stopMinuteOfDay: Int16, valid: Bool) -> TimeSlot? {
        
        let newTimeSlot = NSEntityDescription.insertNewObject(forEntityName: "TimeSlot", into: appDelegate.managedObjectContext) as! TimeSlot
        
        newTimeSlot.startMinuteOfDay = startMinuteOfDay
        newTimeSlot.stopMinuteOfDay = stopMinuteOfDay
        newTimeSlot.weekday = weekday
        newTimeSlot.valid = valid
        
        newTimeSlot.course = self
        
        sortTimeSlots()
        
        return newTimeSlot
    }
    
    /// Returns a newly created Lecture object model for this course following the previous lecture with
    /// the current date. If this is not an absent lecture, then provide nil in the weekOfYear field so
    /// it can be retrieved based on the current date. Otherwise, for the case of an absent lecture, provide
    /// the weekOfYear that this lecture occurred on.
    func createLecture(during timeSlot: TimeSlot, absent weekOfYear: Int16?) -> Lecture {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        newLecture.course = self
        newLecture.timeSlot = timeSlot
        if weekOfYear != nil {
            newLecture.weekOfYear = weekOfYear!
        } else {
            newLecture.number = Int16(self.lectures!.count)
            newLecture.weekOfYear = Int16(NSCalendar.current.component(.weekOfYear, from: Date()))
        }
        
        
        return newLecture
    }
    
    /// Return the lecture at the given date, or nil if none exists.
    func retrieveLecture(on weekday: Int, in weekOfYear: Int, at minuteOfDay: Int) -> Lecture? {
        
        for case let lecture as Lecture in self.lectures! {
            if Int16(weekday) == lecture.timeSlot!.weekday && Int16(minuteOfDay) > lecture.timeSlot!.startMinuteOfDay - 5 && Int16(minuteOfDay) < lecture.timeSlot!.stopMinuteOfDay {
                // during class lecture
                return lecture
            }
        }
        // no lecture
        return nil
    }
    
    // MARK: - Schedule Assistant Helper Functions
    
    /// Returns the time slot that is currently happening for this course
    func duringTimeSlot() -> TimeSlot? {
        let hour = NSCalendar.current.component(.hour, from: Date())
        let minute = NSCalendar.current.component(.minute, from: Date())
        
        let weekday = NSCalendar.current.component(.weekday, from: Date())
        let minuteOfDay = hour * 60 + minute
        
        for case let time as TimeSlot in self.timeSlots! {
            if Int16(weekday) == time.weekday && Int16(minuteOfDay) > time.startMinuteOfDay - 5 && Int16(minuteOfDay) < time.stopMinuteOfDay {
                // during class period
                return time
            }
        }
        return nil
    }
    
    // MARK: - Calculated Properties
    
    /// The number of lectures there should be up to the current time. This can only be
    /// calculated after the first lecture has been added. This method only works if the 
    /// lectures orderedSet is sorted. If this function returns zero, it means there aren't
    /// any courses yet. Verified multiple times to be performing the correct logic.
    func theoreticalLectureCount() -> Int {
        var count = 0
        
        //
        if lectures!.count != 0 {
            
            if let firstLecture = lectures![0] as? Lecture {
                
                // Today's date
                let weekOfYearToday = NSCalendar.current.component(.weekOfYear, from: Date())
                let weekdayToday = NSCalendar.current.component(.weekday, from: Date())
                
                // Initial count is based on weeks and timeslots for that class per week
                count = (weekOfYearToday - Int(firstLecture.weekOfYear)) * self.timeSlots!.count
                
                // Adjust count if the first lecture was offset from the start of the week
                print("    Adjusting theoretical count due to offset by: \(self.timeSlots!.index(of: firstLecture.timeSlot!))")
                count -= self.timeSlots!.index(of: firstLecture.timeSlot!)
                
                // Adjust count if the current day is midway through the week
                let hour = NSCalendar.current.component(.hour, from: Date())
                let minute = NSCalendar.current.component(.minute, from: Date())
                let minuteOfDay = hour * 60 + minute
                // Iterate through times
                for case let timeSlot as TimeSlot in self.timeSlots! {
                    if timeSlot.weekday < Int16(weekdayToday) {
                        count += 1
                    } else if timeSlot.weekday == Int16(weekdayToday) && timeSlot.startMinuteOfDay - 5 < Int16(minuteOfDay) {
                        count += 1
                    } else {
                        break
                    }
                }
            }
            
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
            
            // First element being sorted, don't check, just add it.
            if sortedSet.count != 0 {
                
                var index = 0
                for case let sortedTimeSlot as TimeSlot in sortedSet {
                    // If the unsortedTimeSlot is earlier than the sortedTimeSlot, insert it.
                    if unsortedTimeSlot.weekday == sortedTimeSlot.weekday {
                        if unsortedTimeSlot.startMinuteOfDay < sortedTimeSlot.startMinuteOfDay {
                            sortedSet.insert(unsortedTimeSlot, at: index)
                            break
                        }
                    } else if unsortedTimeSlot.weekday < sortedTimeSlot.weekday {
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
            if time.weekday != -1 {
                daysOfWeek[Int(time.weekday)] = 1
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
    
    /// Similar to what nextTimeSlot does but instead of finding the next time slot available, it will
    /// return false if it fails at all.
    private func validateTimeSlot(on weekday: Int16, from startTime: Int16, to stopTime: Int16) -> Bool {
        for case let course as Course in self.semester!.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if weekday == timeSlot.weekday {
                    if (timeSlot.startMinuteOfDay <= startTime && startTime < timeSlot.stopMinuteOfDay + 5) ||
                        (timeSlot.startMinuteOfDay < stopTime + 5 && stopTime + 5 < timeSlot.stopMinuteOfDay) ||
                        (startTime <= timeSlot.startMinuteOfDay && timeSlot.startMinuteOfDay < stopTime + 5) ||
                        (startTime < timeSlot.stopMinuteOfDay + 5 && timeSlot.stopMinuteOfDay + 5 < stopTime) {
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
        
        self.sortTimeSlots()
        
        // This function doesn't do anything if course hasn't started yet.
        if self.lectures!.count == 0 {
            return
        }
        
        var lecturesToFill = self.theoreticalLectureCount() - self.lectures!.count
        
        // No lectures to create if the amount of lectures is the same as the expected amount of lectures to this date
        if lecturesToFill <= 0 {
            return
        }
        
        // If there is a time slot currently in progress, do not yet add an absent lecture for it, so reduce number
        // to fill in
        if self.duringTimeSlot() != nil {
            lecturesToFill -= 1
        }
        
        let lastTimeSlotIndex = self.timeSlots!.index(of: (self.lectures!.lastObject as! Lecture).timeSlot!)
        let lastTimeSlotWeekOfYear = (self.lectures!.lastObject as! Lecture).weekOfYear
        for x in 0..<(lecturesToFill) {
            let _ = createLecture(
                during: self.timeSlots![(lastTimeSlotIndex + 1 + x) % self.timeSlots!.count] as! TimeSlot,
                absent: lastTimeSlotWeekOfYear + Int16((lastTimeSlotIndex + 1 + x)/timeSlots!.count))
        }
//        
//        var startIndex = -1
//        var weekOfYear: Int16 = 0
//        // Get which timeSlot the last lecture used.
//        if lectures!.count > 0 {
//            // Shift start index if it didn't begin on first timeslot in week
//            startIndex = self.timeSlots!.index(of: (self.lectures!.lastObject as! Lecture).timeSlot!)
//            weekOfYear = (self.lectures!.lastObject as! Lecture).weekOfYear
//        } else {
//            // In the future, the user will probably be able to specify course start day, so
//            // if they miss it, this will fill absent lectures from the starting day, but for
//            // now it only works if there is at least 1 lecture.
//            return
//        }
//        
//        var addLatestCourse = 0
//        // If there isn't a lecture happening, user missed the most recent lecture
//        if duringTimeSlot() == nil {
//            addLatestCourse = 1 // so create 1 more absentLecture
//        }
//        
//        // Add absent lectures if there is more than 1 missing lecture based on the theoretical lecture count.
//        if self.theoreticalLectureCount() - self.lectures!.count + addLatestCourse < 0 {
//            return
//        }
//        for missing in 0..<(self.theoreticalLectureCount() - self.lectures!.count + addLatestCourse) {
//            let _ = createLecture(
//                during: self.timeSlots![(startIndex + missing + 1) % timeSlots!.count] as! TimeSlot,
//                absent: weekOfYear + Int16((startIndex + missing + 1)/timeSlots!.count))
//        }
    }
    
    /// Will produce the next available time slot with a default length of 55 minutes. Can still return
    /// nil but this would mean every day has a full schedule... Starts at 8:00AM and searches each day
    /// before 10:00PM.
    func nextTimeSlot() -> TimeSlot {
        
        var courseLength = 55
        if let defaultTimeSpan = CFPreferencesCopyAppValue(NSString(string: "defaultCourseTimeSpanMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(defaultTimeSpan) {
                courseLength = time
            }
        }
        
        var startTime: Int16 = 480
        var stopTime: Int16 = startTime + courseLength
        var weekday: Int16 = 1
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
                timeAvailableOnDay = validateTimeSlot(on: weekday, from: startTime, to: stopTime)
                if !timeAvailableOnDay {
                    startTime += 60
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
}
