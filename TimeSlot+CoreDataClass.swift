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
    

    /// Similar to what nextTimeSlot does but instead of finding the next time slot available, it will
    /// return false if it fails at all.
    func validateTimeSlot(on weekday: Int16, from startTime: Int16, to stopTime: Int16) -> Bool {
        
        if startTime > stopTime - 5 {
            // Start time is earlier than stop time, try and push back stop time
            return false
        }
        
        for case let course as Course in self.course!.semester!.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if self != timeSlot && weekday == timeSlot.weekday {
                    // Check collisions with 5 minute buffer
                    if (timeSlot.startMinuteOfDay <= startTime && startTime < timeSlot.stopMinuteOfDay + 5) ||
                        (timeSlot.startMinuteOfDay < stopTime + 5 && stopTime + 5 < timeSlot.stopMinuteOfDay) ||
                        (startTime <= timeSlot.startMinuteOfDay && timeSlot.startMinuteOfDay < stopTime + 5) ||
                        (startTime < timeSlot.stopMinuteOfDay + 5 && timeSlot.stopMinuteOfDay + 5 < stopTime) {
                        // Conflicting time
                        timeSlot.valid = false
                        return false
                    }
                }
            }
        }
        return true
    }
    
}
