//
//  course.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/19/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class Course {
    
    var title: String = "New Course"
    
    var timeSlotsOccupied: [TimeSlot]!
    
    
    init() {
        
    }
    
    deinit {
        for t in timeSlotsOccupied {
            t.occupyingCourse = nil
        }
    }
    
    func assignTime(withTimeSlot time: TimeSlot) {

        timeSlotsOccupied.append(time)
        time.occupyingCourse = self

    }
}
