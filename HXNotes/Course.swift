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
    
    func remove() {
        for t in timeSlotsOccupied {
            t.occupyingCourse = nil
        }
        timeSlotsOccupied = []
    }
    
    /// Add a time slot to a course, will return a tuple in which
    /// the first value is the earliest start of course, and the
    /// second value is the end time of course, by grid y index
    func assignTime(withTimeSlot time: TimeSlot) -> (Int, Int) {

        // Find highest time connected in chain to this one
        var topMostTime = time.yDim!
        // No need to check if its already at start of day
        if time.yDim != 0 {
            // Travel up (earlier in day) times until not this course is reached
            for i in stride(from: (time.yDim - 1), through: 0, by: -1) {
                if timeSlotsOccupied.contains(where: {$0.xDim == time.xDim && $0.yDim == i}) {
                    topMostTime = i
                } else {
                    break
                }
            }
        }
        // Find lowest time connected in chain to this one
        var botMostTime = time.yDim!
        // No need to check if its already at end of day
        if time.yDim != 14 {
            // Travel down (later in day) times until not this course is reached
            for i in stride(from: (time.yDim + 1), through: 14, by: +1) {
                if timeSlotsOccupied.contains(where: {$0.xDim == time.xDim && $0.yDim == i}) {
                    botMostTime = i
                } else {
                    break
                }
            }
        }
        
        timeSlotsOccupied.append(time)
        time.occupyingCourse = self
        
        return (topMostTime, botMostTime)
    }
    
    /// Removes the given time slot from the course if it exists
    func removeTime(withTimeSlot time: TimeSlot) {
        if let i = timeSlotsOccupied.index(where: {$0.xDim == time.xDim && $0.yDim == time.yDim}) {
            timeSlotsOccupied.remove(at: i)
            time.occupyingCourse = nil
        }
    }
}
