//
//  Lecture+CoreDataClass.swift
//  HXNotes
//
//  Created by Harrison Balogh on 9/15/17.
//  Copyright © 2017 Harxer. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Lecture)
public class Lecture: NSManagedObject {
    
    /// Populates and returns a date object by extracting date components
    /// from target lecture's TimeSlot and owning Course's Semester's attributes.
    func date() -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: course!.semester!.start!)
        dateComponents.month = Int(self.month)
        dateComponents.day = Int(self.day)
        dateComponents.weekday = Int(self.timeSlot!.weekday)
        dateComponents.hour = Int(self.timeSlot!.startMinute / 60)
        dateComponents.minute = Int(self.timeSlot!.startMinute % 60)
        
        return Calendar.current.date(from: dateComponents)!
    }

}
