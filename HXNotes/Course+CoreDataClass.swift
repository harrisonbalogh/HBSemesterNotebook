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
        var numberOfDaysInWeek = 0
        for day in daysOfWeek {
            numberOfDaysInWeek = numberOfDaysInWeek + day
        }
        return numberOfDaysInWeek
    }
    /// Will return a printable version of the days that the course occupies.
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
}
