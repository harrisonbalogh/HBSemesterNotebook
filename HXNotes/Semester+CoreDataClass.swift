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
    
    var cachedDuring: TimeSlot! = nil
    var cachedFuture: TimeSlot! = nil
    
    /// Set to false whenever a TimeSlot is added, removed, or updated under
    /// the root Semester object. This ensures that validation will not be
    /// calculated on a Semester that has been previously validated without
    /// changes to its Courses' TimeSlots.
    var needsValidate = true
    
    // Note: about the object model and function names.
    // create'Object' returns a new object.
    // retrieve'Object' returns an object that already exists or nil if it doesn't.
    // produce'Object' returns an object that already exists or a new object if it doesn't.
    
    // MARK: - Creating/Retrieving/Producing Objects
    
    /// Creates and returns a new persistent Course object. Can never have the same title as another
    /// course.
    public func createCourse() -> Course {
        
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: managedObjectContext!) as! Course
        
        let color = NSEntityDescription.insertNewObject(forEntityName: "Color", into: managedObjectContext!) as! Color
        let nextColor = nextColorAvailable().usingColorSpace(.sRGB)!
        color.red = Float(nextColor.redComponent)
        color.green = Float(nextColor.greenComponent)
        color.blue = Float(nextColor.blueComponent)
        newCourse.color = color
        
        newCourse.title = "Untitled \(nextNumberAvailable())"
        newCourse.semester = self
        
        return newCourse
    }
    
    /// Retrieves the course with unique name for this semester. Return nil if
    /// course not found.
    public func retrieveCourse(named: String) -> Course! {
        for case let course as Course in self.courses! {
            if course.title!.lowercased() == named.lowercased() {
                return course
            }
        }
        return nil
    }
    
    /// Return the semester present at the given year and semester. Returns nil if none exists.
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
    
    /// Returns a single timeSlot that is currently happening or will start in 5 minutes.
    /// Returns nil if no course is happening at the moment.
    public func duringCourse() -> TimeSlot? {
        for case let course as Course in self.courses! {
            if let during = course.duringTimeSlot() {
                return during
            }
        }
        // no class
        return nil
    }
    
    /// Returns the earliest course to occur within the next 60 (default, user adjustable CFPreferences) minutes.
    /// Returns nil if no courses are happening for the receiving semester within the futureAlertTimeMinutes time span.
    public func futureTimeSlot() -> TimeSlot? {
        // Setup preference value
        var alertTimespan = 60
        if let alertTimePref = CFPreferencesCopyAppValue(NSString(string: "futureAlertTimeMinutes"), kCFPreferencesCurrentApplication) as? String {
            if let time = Int(alertTimePref) {
                alertTimespan = time
            }
        }
        // Date Today
        let cal = Calendar.current
        let date = Date()
        let weekday = Int16(cal.component(.weekday, from: date))
        let minuteOfDay = Int16(cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date))
        // Find soonest time slot
        var soonest: TimeSlot! = nil
        for case let course as Course in self.courses! {
            if self.needsValidate {
                self.validateSchedule()
            }
            // Only check valid courses
            if !self.valid {
                continue
            }
            // This func assumes course timeslots are sorted.
            if course.needsSort {
                course.sortTimeSlots()
            }
            for case let time as TimeSlot in course.timeSlots! {
                
                if weekday == time.weekday && minuteOfDay >= time.startMinute - alertTimespan && minuteOfDay < time.startMinute {
                    // Course approaching within timespan. Check if its earlier than previous find
                    if soonest == nil || time.startMinute < soonest.startMinute {
                        soonest = time
                    }
                } else {
                    print("Engh. Not in the correct time.")
                }
            }
        }
        return soonest
    }
    
    // MARK: - Validation
    
    /// Does a validation check on every TimeSlot for all Course objects in the receiving Semester.
    /// If any invalid TimeSlots are found, this function will return false and update the valid flag
    /// to false on all offending TimeSlots, Course, and Semester - or update valid flags to true.
    @discardableResult func validateSchedule() -> Bool {
        
        var timeQueue = [TimeSlot]()
        
        self.valid = true
        for case let course as Course in self.courses! {
            course.valid = true
            for case let time as TimeSlot in course.timeSlots! {
                time.valid = true
                timeQueue.append(time)
            }
        }
        
        for t in 0..<timeQueue.count {
            for s in (t+1)..<timeQueue.count {
                timeQueue[t].validate(against: timeQueue[s])
            }
        }
        
        // All code should check if semester needs validation before calling validateSchedule
        needsValidate = false
        return self.valid
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
                
                if Int(color.redComponent * 1000) == Int(course.color!.red * 1000) &&
                    Int(color.greenComponent * 1000) == Int(course.color!.green * 1000) &&
                    Int(color.blueComponent * 1000) == Int(course.color!.blue * 1000) {
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
