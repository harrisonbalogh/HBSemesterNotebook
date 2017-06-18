//
//  Semester+CoreDataClass.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import Cocoa

@objc(Semester)
public class Semester: NSManagedObject {
    
    /// Creates and returns a new persistent Course object.
    public func newCourse() -> Course {
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: managedObjectContext!) as! Course
        print("Hey")
        let assignedColor = nextColorAvailable()
        print("Never")
        newCourse.colorRed = Float(assignedColor.redComponent)
        newCourse.colorGreen = Float(assignedColor.greenComponent)
        newCourse.colorBlue = Float(assignedColor.blueComponent)
        newCourse.title = "Untitled \(nextNumberAvailable())"
        newCourse.semester = self
        return newCourse
    }
    
    /// Retrieves the course with unique name for this semester. Can return nil if
    /// course not found or if more than one course has that name.
    public func retrieveCourse(named: String) -> Course! {
        for case let course as Course in self.courses! {
            if course.title! == named {
                return course
            }
        }
        return nil
    }
    
    /// Returns a single course that is currently happening or will start in 5 minutes.
    /// Returns nil if no course is happening at the moment.
    public func duringCourse() -> Course? {
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        let day = NSCalendar.current.component(.weekday, from: NSDate() as Date)
        
        for case let course as Course in self.courses! {
            for case let time as TimeSlot in course.timeSlots! {
                if Int16(day - 2) == time.day && (Int16(hour - 8) == time.hour || (Int16(hour - 8) == (time.hour - 1) && Int16(minute) > 55)) {
                    // during class
                    return time.course
                }
            }
        }
        // no class
        return nil
    }
    
    /// Return the first number available in the semester for untitled courses.
    public func nextNumberAvailable() -> Int {
        // Find next available number for naming Course
        var nextCourseNumber = 1
        var seekingNumber = true
        repeat {
            if (retrieveCourse(named: "Untitled \(nextCourseNumber)")) == nil {
                seekingNumber = false
            } else {
                nextCourseNumber += 1
            }
        } while(seekingNumber)
        return nextCourseNumber
    }

    // Colors used to give courses unique colors
    private let COLORS_ORDERED: [NSColor] = [
        NSColor.init(red: 88/255, green: 205/255, blue: 189/255, alpha: 1),
        NSColor.init(red: 114/255, green: 205/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 89/255, green: 138/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 204/255, green: 88/255, blue: 127/255, alpha: 1),
        NSColor.init(red: 205/255, green: 142/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 161/255, green: 88/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 54/255, green: 255/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 0/255, green: 240/255, blue: 255/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 210/255, alpha: 1)]
    /// Return the first color available, or gray if all colors taken
    public func nextColorAvailable() -> NSColor {
        for color in COLORS_ORDERED {
            for case let course as Course in self.courses! {
                if Float(color.redComponent) != course.colorRed || Float(color.greenComponent) != course.colorGreen || Float(color.blueComponent) != course.colorBlue {
                    return color
                }
            }
        }
        return NSColor.gray
    }
}
