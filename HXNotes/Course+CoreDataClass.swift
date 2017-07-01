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

@objc(Course)
public class Course: NSManagedObject {
    
    /// Will return a printable version of this courses schedule. Includes days and times.
    func schedulePrintable() -> String {
        var constructedString = ""
        
        var daysOfWeek = [0, 0, 0, 0, 0]
        let dayNames = ["M", "T", "W", "Th", "F"]
        for d in 0...4 {
            var times = [Int16]()
            for case let time as TimeSlot in self.timeSlots! {
                if time.day == Int16(d) {
                    // Insert day name first time
                    if daysOfWeek[d] == 0 {
                        daysOfWeek[d] = 1
                        constructedString += dayNames[d] + ":"
                    }
                    //
                    times.append(time.hour)
                }
            }
            if times.count == 0 {
                continue
            } else if times.count == 1 {
                constructedString += " \(HXTimeFormatter.formatTime(times[0]+8))-\(HXTimeFormatter.formatTime(times[0]+9))      "
                continue
            }
            times.sort()
            var prevTime: Int16 = times[0] + 8
            var timeSpan: Int16 = 0
            for t in 1..<times.count {
                if (times[t]+8) == (prevTime + 1){
                    // Adjacent time
                    if t == times.count - 1 {
                        constructedString += " \(HXTimeFormatter.formatTime(prevTime - timeSpan))-\(HXTimeFormatter.formatTime(prevTime + 2))"
                    }
                    timeSpan += 1
                } else {
                    // Not adjacent time
                    constructedString += " \(HXTimeFormatter.formatTime(prevTime - timeSpan))-\(HXTimeFormatter.formatTime(prevTime + 1))"
                    // Reset time span
                    timeSpan = 0
                    if t == times.count - 1 {
                        constructedString += " \(HXTimeFormatter.formatTime(times[t] + 8 - timeSpan))-\(HXTimeFormatter.formatTime(times[t] + 9))"
                    }
                    
                }
                // Update previous time
                prevTime = times[t] + 8
            }
            constructedString += "      "
        }
        
        return constructedString
    }
    
    /// Will return how many days in a week the course takes place.
    /// This does not take into account a course that may occur multiple times in
    /// one day during the week. Any times found on a given day equates to incrementing the return by 1.
    func daysPerWeek() -> Int {
        var daysOfWeek = [0, 0, 0, 0, 0]
        for case let time as TimeSlot in self.timeSlots! {
            daysOfWeek[Int(time.day)] = 1
        }
        return daysOfWeek.filter({$0 == 1}).count
    }
    
    /// Will return a printable version of the days that the course occupies. Ex: "M,W".
    func daysPerWeekPrintable() -> String {
        var daysOfWeek = [0, 0, 0, 0, 0]
        let dayNames = ["M", "T", "W", "Th", "F"]
        for case let time as TimeSlot in self.timeSlots! {
            daysOfWeek[Int(time.day)] += 1
        }
        var constructedString = ""
        // Consecutive additions need a comma
        for d in 0..<daysOfWeek.count {
            if daysOfWeek[d] > 0 {
                if constructedString == "" {
                    constructedString = (dayNames[d])
                }else {
                    constructedString += ("," + dayNames[d])
                }
            }
        }
        return constructedString
    }
    /// The number of lectures there should be up to today's date. This can only be 
    /// calculated after the first lecture has been added. This theoretical number is
    /// deduced based on daysPerWeek and the first lecture.
    public func theoreticalLectureCount() -> Int {
        print("theoreticalLectureCount,,,,,,,,,,,,,,")
        if lectures!.count != 0 {
            if let firstLecture = lectures![0] as? Lecture {
                let weekOfYearLecture = firstLecture.weekOfYear
                print("    The week of yeare of first lecture: \(weekOfYearLecture)")
                let weekOfYearToday = NSCalendar.current.component(.weekOfYear, from: NSDate() as Date)
                let weekdayToday = NSCalendar.current.component(.weekday, from: NSDate() as Date)
                print("    Current week of year: \(weekOfYearToday)")
                print("    weekdayToday: \(weekdayToday)")
                
                // Initial count is based on weeks.
                var count = (weekOfYearToday - Int(weekOfYearLecture)) * self.daysPerWeek()
                print("    Uncorrected count: \(count)")
                // Then adjust for if opening app when its not perfectly a week from previous lecture.
                count += lectureInWeek(for: weekdayToday) - lectureInWeek(for: Int(firstLecture.weekDay))
                print("    The first lecture was on this lecture day: \(lectureInWeek(for: Int(firstLecture.weekDay)))")
                print("    lectureInWeek(for: weekdayToday): \(lectureInWeek(for: weekdayToday))")
                print("    The new count is: \(count)")
                
                // Finally, check if a lecture is today to verify if the lecture passed per hour
                if let time = earliestTimeSlot(for: weekdayToday) {
                    print("Earliest time slot is today at: \(time.hour + 8)")
                    let currentHour = NSCalendar.current.component(.hour, from: NSDate() as Date)
                    if currentHour <= Int(time.hour + 8) {
                        count -= 1
                    }
                } else {
                    print("No timeslots today.")
                }
                
                return count + 1
            }
        }
        return 0
    }
    /// If there are 2 lectures in a week, this will return which number this lecture
    /// should correspond to for this course. Example: If the weekday is Thursday(5) and 
    /// the course has timeslots on Tuesday(3) and Thursday(5), this will return 2.
    /// If a timeslot is not present on the given weekday, it will return previous most lecture
    /// day, even looping around past Sunday, if necessary. Return domain [1, 5]
    public func lectureInWeek(for weekday: Int) -> Int {
        var days = [Int]()
        for case let time as TimeSlot in self.timeSlots! {
            if !days.contains(Int(time.day) + 2) {
                days.append(Int(time.day) + 2)
            }
        }
        days.sort()
        if days.index(of: weekday) == nil {
            for prevDay in stride(from: 7, to: 0, by: -1) {
                if let day = days.index(of: (prevDay + weekday) % 7) {
                    return day + 1
                }
            }
            return 0
        }
        return days.index(of: weekday)! + 1
    }
    /// Will return a day of the week [2, 6], but can return nil if user
    /// requests a lecture number that is greater than the total number of lectures,
    /// as this is an invalid request.
    public func weekdayForLecture(number: Int) -> Int! {
        var days = [Int]()
        for case let time as TimeSlot in self.timeSlots! {
            if !days.contains(Int(time.day) + 2) {
                days.append(Int(time.day) + 2)
            }
        }
        if days.count >= (number + 1) {
            return nil
        }
        days.sort()
        return days[number]
    }
    /// Return the earliest timeslot for the given weekday.
    private func earliestTimeSlot(for weekday: Int) -> TimeSlot! {
        var earliestHour: Int16 = 24
        var theTimeSlot: TimeSlot!
        for case let time as TimeSlot in self.timeSlots! {
            if Int(time.day + 2) == weekday  && time.hour < earliestHour {
                theTimeSlot = time
                earliestHour = time.hour
            }
        }
        return theTimeSlot
    }
}
