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
    /// Returns a single course that is happening soon. Returns nill if no course is happening soon.
    public func futureCourse() -> Course? {
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        let day = NSCalendar.current.component(.weekday, from: NSDate() as Date)
        print("Checking future course.")
        for case let course as Course in self.courses! {
            for case let time as TimeSlot in course.timeSlots! {
                if Int16(day - 2) == time.day && ((Int16(hour - 8) == (time.hour - 1) && Int16(minute) > 30)) {
                    // during class
                    print("Found 'em. \(time.course!.title!)")
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
