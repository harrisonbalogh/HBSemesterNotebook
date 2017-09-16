//
//  TimeSlot+CoreDataClass.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(TimeSlot)
public class TimeSlot: NSManagedObject {
    
    // Note about timeslots, the basis for adding lectures and absent lectures revolves around
    // returning the theoretical lecture count. The only way this works properly is if the TimeSlot
    // objects are guaranteed to be sorted in order. From Sunday to Saturday and then from time of day.
    
    func validate(against timeB: TimeSlot) {
        // Don't validate timeslot against itself
        if timeB == self {
            return
        }
        
        // Load preference value
        var bufferTime = 5
        if let bufferTimePref = CFPreferencesCopyAppValue(NSString(string: "bufferTimeBetweenCoursesMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(bufferTimePref) {
                bufferTime = max(time, 5)
            }
        }
        
        let dayA = self.weekday
        let startA = self.startMinute
        let stopA = self.stopMinute
        
        let dayB = timeB.weekday
        let startB = timeB.startMinute
        let stopB = timeB.stopMinute
        
        if dayA == dayB &&
            ((startA <= startB - bufferTime && startB - bufferTime < stopA) ||
            (startA < stopB + bufferTime && stopB + bufferTime < stopB) ||
            (startB <= startA && startA <= stopB) ||
            (startB <= stopA && stopA <= stopB)) {
            // The above checks for any kind of overlap including buffer time
            
            // If this course has already began (lectures have been added) the user
            // is unable to change time slots in the scheduler, so don't invalidate the
            // slots.
            if self.course!.lectures!.count == 0 {
                self.valid = false
                self.course!.valid = false
                self.course!.semester!.valid = false
            }
            if timeB.course!.lectures!.count == 0 {
                timeB.valid = false
                timeB.course!.valid = false
                timeB.course!.semester!.valid = false
            }
        }
    }
    
    /// Returns the difference in minutes between the target TimeSlot and TimeSlot passed
    /// as parameter. Target must be later in time than passed TimeSlot.
    func timeDifference(to timeB: TimeSlot) -> Int {

        let minutesSumA = self.weekday * 24 * 60 + self.startMinute
        let minutesSumB = timeB.weekday * 24 * 60 + timeB.startMinute
        var minuteDifference = 0
        
        // Check if on seperate weeks
        if minutesSumA < minutesSumB {
            minuteDifference = 7 * 24 * 60 + minutesSumA - minutesSumB
        } else {
            minuteDifference = minutesSumA - minutesSumB
        }
        
        return minuteDifference
    }
}
























