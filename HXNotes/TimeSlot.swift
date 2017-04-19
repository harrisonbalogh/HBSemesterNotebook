//
//  timeSlot.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/19/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class TimeSlot {
    
    var occupyingCourse: Course! = nil
    
    let hour: Int!
    let minute: Int!
    
    let lengthHour: Int!
    let lengthMinute: Int!
    
    init(hour: Int, minute: Int, lengthHour: Int, lengthMinute: Int) {
        
        self.hour = hour
        self.minute = minute
        
        self.lengthHour = lengthHour
        self.lengthMinute = lengthMinute
        
    }
}
