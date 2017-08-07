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
    
    // Note: about the object model and function names.
    // create'Object' returns a new object.
    // retrieve'Object' returns an object that already exists or nil if it doesn't.
    // produce'Object' returns an object that already exists or a new object if it doesn't.
    
    // MARK: Creating/Retrieving/Producing Objects
    
    /// Creates and returns a new persistent Course object. Can never have the same title as another
    /// course.
    public func createCourse() -> Course {
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: managedObjectContext!) as! Course
        let assignedColor = nextColorAvailable().usingColorSpace(.sRGB)!
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
    
    /// Return the semester present at the given year and semester. Will return nil if none exists/
    static func retrieveSemester(titled title: String, in year: Int) -> Semester? {
        // Fetch semesters in persistent store. Return if found else return nil.
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            if let foundSemester = semesters.filter({$0.year == Int16(year) && $0.title == title}).first {
                // Found semester, return it.
                return foundSemester
            }
        } catch { fatalError("Failed to fetch semesters: \(error)") }
        return nil
    }
    
    /// Will return a semester that either has been newly created, or already exists for the given year and title.
    static func produceSemester(titled title: String, in year: Int) -> Semester {
        // Fetch semesters in persistent store. Return if found else create new.
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            if let foundSemester = semesters.filter({$0.year == Int16(year) && $0.title == title}).first {
                // This semester already present in store so return it
                return foundSemester
            } else {
                // Create semester since it wasn't found
                let newSemester = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
                newSemester.year = Int16(year)
                newSemester.title = title
                return newSemester
                
            }
        } catch { fatalError("Failed to fetch semesters: \(error)") }
    }
    
    // MARK: - Schedule Assistant Helper Functions
    
    /// Returns a single course that is currently happening or will start in 5 minutes.
    /// Returns nil if no course is happening at the moment.
    public func duringCourse() -> Course? {
        let hour = NSCalendar.current.component(.hour, from: Date())
        let minute = NSCalendar.current.component(.minute, from: Date())
        
        let weekday = NSCalendar.current.component(.weekday, from: Date())
        let minuteOfDay = hour * 60 + minute
        
        for case let course as Course in self.courses! {
            for case let time as TimeSlot in course.timeSlots! {
                
                // If any of the time slots are invalid, don't check them for alerts
                if !time.valid {
                    return nil
                }
                
                if Int16(weekday) == time.weekday && Int16(minuteOfDay) > time.startMinuteOfDay - 5 && Int16(minuteOfDay) < time.stopMinuteOfDay {
                    // during class period
                    return course
                }
            }
        }
        // no class
        return nil
    }
    
    let TEMP_TIMESPAN: Int16 = 60 // should be adjustable in settings, will...
    /// Returns the earliest course to occur within the next TEMP_TIMESPAN minutes.
    public func futureCourse() -> Course? {
        
        var soonestTimeSlot: TimeSlot!
        
        let hour = NSCalendar.current.component(.hour, from: Date())
        let minute = NSCalendar.current.component(.minute, from: Date())
        
        let weekday = NSCalendar.current.component(.weekday, from: Date())
        let minuteOfDay = hour * 60 + minute
        
        for case let course as Course in self.courses! {
            for case let time as TimeSlot in course.timeSlots! {
                
                // If any of the time slots are invalid, don't check them for alerts
                if !time.valid {
                    return nil
                }
                
                if Int16(weekday) == time.weekday && Int16(minuteOfDay) < time.startMinuteOfDay && Int16(minuteOfDay) > time.startMinuteOfDay - TEMP_TIMESPAN {
                    // Course approaching within timespan.
                    if soonestTimeSlot == nil || time.startMinuteOfDay < soonestTimeSlot.startMinuteOfDay {
                        soonestTimeSlot = time
                    }
                }
            }
        }
        if soonestTimeSlot == nil {
            return nil
        }
        return soonestTimeSlot.course
    }
    
    // MARK: - Course Creation Helper Functions
    
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
        NSColor(red: 88/255, green: 205/255, blue: 189/255, alpha: 1),
        NSColor(red: 114/255, green: 205/255, blue: 88/255, alpha: 1),
        NSColor(red: 89/255, green: 138/255, blue: 205/255, alpha: 1),
        NSColor(red: 204/255, green: 88/255, blue: 127/255, alpha: 1),
        NSColor(red: 205/255, green: 142/255, blue: 88/255, alpha: 1),
        NSColor(red: 161/255, green: 88/255, blue: 205/255, alpha: 1),
        NSColor(red: 254/255, green: 0/255, blue: 0/255, alpha: 1),
        NSColor(red: 54/255, green: 255/255, blue: 0/255, alpha: 1),
        NSColor(red: 0/255, green: 240/255, blue: 255/255, alpha: 1),
        NSColor(red: 254/255, green: 0/255, blue: 210/255, alpha: 1)]
    /// Return the first color available, or gray if all colors taken
    public func nextColorAvailable() -> NSColor {
        for color in COLORS_ORDERED {
            var colorAvailable = true
            for case let course as Course in self.courses! {
                if Int(color.redComponent * 1000) == Int(course.colorRed * 1000) &&
                    Int(color.greenComponent * 1000) == Int(course.colorGreen * 1000) &&
                    Int(color.blueComponent * 1000) == Int(course.colorBlue * 1000) {
                    colorAvailable = false
                    break
                }
            }
            if colorAvailable {
                return color
            }
        }
        return NSColor.gray
    }
}
