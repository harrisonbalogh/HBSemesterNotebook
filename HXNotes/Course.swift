//
//  course.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/19/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation
import Cocoa

class Course {
    
    var title: String = "New Course"
    
    var timeSlotsOccupied = [TimeSlot]()
    
    var index: Int!
    
    var color: NSColor!
    
    
    init(withColor color: NSColor) {
        self.color = color
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
