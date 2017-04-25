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
    
    let xDim: Int!
    let yDim: Int!
    
    init(hour: Int, minute: Int, lengthHour: Int, lengthMinute: Int, xDim x: Int!, yDim y: Int!) {
        
        self.hour = hour
        self.minute = minute
        
        self.lengthHour = lengthHour
        self.lengthMinute = lengthMinute
        
        self.xDim = x;
        self.yDim = y;
        
    }
    
    func clearCourse() {
        if let i = occupyingCourse.timeSlotsOccupied.index(where: {$0.xDim == xDim && $0.yDim == yDim}) {
            occupyingCourse.timeSlotsOccupied.remove(at: i)
            occupyingCourse = nil
        }
    }
}
