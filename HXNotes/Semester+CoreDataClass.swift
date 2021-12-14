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
    var year: Int {
        get {
            let diff = start!.timeIntervalSince(end!)
            let adjustedDate = start!.addingTimeInterval(-diff/2)
            return Calendar.current.component(.year, from: adjustedDate)
        }
    }
    var earliestStart: Date {
        get {
            let cal = Calendar.current
            let range = (self.title!.lowercased() == "fall") ?
                AppPreference.defaultFallDateRange : AppPreference.defaultSpringDateRange
            let diff = range.lowerBound.timeIntervalSince(range.upperBound)
            
            // Have to set the correct year for the particular range cus default is 1993
            var comps = DateComponents()
            comps.year = self.year
            comps.minute = cal.component(.minute, from: range.lowerBound)
            comps.hour = cal.component(.hour, from: range.lowerBound)
            comps.second = cal.component(.second, from: range.lowerBound)
            comps.day = cal.component(.day, from: range.lowerBound)
            comps.month = cal.component(.month, from: range.lowerBound)
            comps.calendar = Calendar.current
            return cal.date(from: comps)!.addingTimeInterval(diff/2)
        }
    }
    var latestStart: Date {
        get {
            let cal = Calendar.current
            let range = (self.title!.lowercased() == "fall") ?
                AppPreference.defaultFallDateRange : AppPreference.defaultSpringDateRange
            let diff = range.lowerBound.timeIntervalSince(range.upperBound)
            
            // Have to set the correct year for the particular range cus default is 1993
            var comps = DateComponents()
            comps.year = self.year
            comps.minute = cal.component(.minute, from: range.lowerBound)
            comps.hour = cal.component(.hour, from: range.lowerBound)
            comps.second = cal.component(.second, from: range.lowerBound)
            comps.day = cal.component(.day, from: range.lowerBound)
            comps.month = cal.component(.month, from: range.lowerBound)
            comps.calendar = Calendar.current
            return cal.date(from: comps)!.addingTimeInterval(-diff/2)
        }
    }
    var earliestEnd: Date {
        get {
            let cal = Calendar.current
            let range = (self.title!.lowercased() == "fall") ?
                AppPreference.defaultFallDateRange : AppPreference.defaultSpringDateRange
            let diff = range.lowerBound.timeIntervalSince(range.upperBound)
            
            // Have to set the correct year for the particular range cus default is 1993
            var comps = DateComponents()
            comps.year = self.year
            comps.minute = cal.component(.minute, from: range.upperBound)
            comps.hour = cal.component(.hour, from: range.upperBound)
            comps.second = cal.component(.second, from: range.upperBound)
            comps.day = cal.component(.day, from: range.upperBound)
            comps.month = cal.component(.month, from: range.upperBound)
            comps.calendar = Calendar.current
            return cal.date(from: comps)!.addingTimeInterval(diff/2)
        }
    }
    var latestEnd: Date {
        get {
            let cal = Calendar.current
            let range = (self.title!.lowercased() == "fall") ?
                AppPreference.defaultFallDateRange : AppPreference.defaultSpringDateRange
            let diff = range.lowerBound.timeIntervalSince(range.upperBound)
            
            // Have to set the correct year for the particular range cus default is 1993
            var comps = DateComponents()
            comps.year = self.year
            comps.minute = cal.component(.minute, from: range.upperBound)
            comps.hour = cal.component(.hour, from: range.upperBound)
            comps.second = cal.component(.second, from: range.upperBound)
            comps.day = cal.component(.day, from: range.upperBound)
            comps.month = cal.component(.month, from: range.upperBound)
            comps.calendar = Calendar.current
            return cal.date(from: comps)!.addingTimeInterval(-diff/2)
        }
    }
    
    /// Set to false whenever a TimeSlot is added, removed, or updated under
    /// the root Semester object. This ensures that validation will not be
    /// calculated on a Semester that has been previously validated without
    /// changes to its Courses' TimeSlots.
    var needsValidate = true
    
    // Note: about the object model and function names.
    // create'Object' returns a new object.
    // produce'Object' returns an object that already exists or a new object if it doesn't.
    
    // MARK: - Creating/Retrieving/Producing Objects
    
    /// Creates and returns a new persistent Course object. Can never have the same title as another
    /// course.
    @discardableResult public func createCourse() -> Course {
        
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: managedObjectContext!) as! Course
        
        let color = NSEntityDescription.insertNewObject(forEntityName: "Color", into: managedObjectContext!) as! Color
        let nextColor = nextColorAvailable().usingColorSpace(.sRGB)!
        color.red = Float(nextColor.redComponent)
        color.green = Float(nextColor.greenComponent)
        color.blue = Float(nextColor.blueComponent)
        newCourse.color = color
        
        newCourse.title = "Untitled \(nextCourseNumberAvailable())"
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
    
    /// Returns the semester (or quarter) that contains the date parameter provided. If semester is not found, it will
    /// return nil unless createIfNecessary is true in which case a new Semester object will be created and returned.
    static func produceSemester(during date: Date, createIfNecessary: Bool) -> Semester? {
        // Fetch semesters in persistent store. Return if found else create new if specified.
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            let foundSemesters = semesters.filter({
                $0.start!.compare(date) == .orderedAscending && $0.end!.compare(date) == .orderedDescending
            });
            if foundSemesters.count != 0 {
                // The following corrects for when duplicate semesters are found,
                // it will choose the semester that has the most course data and
                // delete the empty semester. This glitch most likely occurs when
                // setting custom semester start dates. If there is a gap in time,
                // it will create a default semester on top of the custom date semester.
                var returnSemester: Semester!
                for foundSemester in foundSemesters {
                    if returnSemester == nil {
                        returnSemester = foundSemester
                    } else if (foundSemester.courses!.count > returnSemester.courses!.count){
                        // Remove empty duplicate semesters
                        if (returnSemester.courses!.count == 0) {
                            let appDelegate = NSApplication.shared.delegate as! AppDelegate
                            appDelegate.managedObjectContext.delete(returnSemester)
                        }
                        returnSemester = foundSemester
                    }
                }
                // This semester already present in store so return it
                return returnSemester!
            }
            if createIfNecessary {
                // Create semester since it wasn't found
                let newSemester = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
                
                let semInfo = Semester.bounds(for: date)
                newSemester.start = semInfo.range.lowerBound
                newSemester.end = semInfo.range.upperBound
                newSemester.title = semInfo.title
                return newSemester
            } else {
                return nil
            }
        } catch { fatalError("Failed to fetch semesters: \(error)") }
    }
    static func produceSemester(titled: String, in year: Int) -> Semester? {
        // Fetch semesters in persistent store. Return if found else create new if specified.
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            if let foundSemester = semesters.filter({ $0.year == year && $0.title! == titled }).first {
                // This semester already present in store so return it
                return foundSemester
            } else {
                return nil
            }
        } catch { fatalError("Failed to fetch semesters: \(error)") }
        return nil
    }
    
    /// Returns the next semester (or quarter) of the target - creating a new Semester object if necessary.
    func proceeding() -> Semester {
        let semEndDate = self.end!.addingTimeInterval(60*60*24*7)
        return Semester.produceSemester(during: semEndDate, createIfNecessary: true)!
    }
    /// Returns the previous semester (or quarter) of the target - creating a new Semester object if necessary.
    func preceeding() -> Semester {
        let semStartDate = self.start!.addingTimeInterval(-60*60*24*7)
        return Semester.produceSemester(during: semStartDate, createIfNecessary: true)!
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
    
    /// Returns the earliest course to occur within the next 60 (default, user adjustable app preference) minutes.
    /// Returns nil if no courses are happening for the receiving semester within the futureAlertTimeMinutes time span.
    public func futureTimeSlot() -> TimeSlot? {
        // Get app preference value
        let alertTimespan = AppPreference.futureAlertTimeMinutes
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
                
                if weekday == time.weekday && minuteOfDay >= Int(time.startMinute) - alertTimespan && minuteOfDay < time.startMinute {
                    // Course approaching within timespan. Check if its earlier than previous find
                    if soonest == nil || time.startMinute < soonest.startMinute {
                        soonest = time
                    }
                }
            }
        }
        return soonest
    }
    
    /// Will return true if the target semester is before the passed semester.
    public func isEarlier(than semester: Semester) -> Bool {
        if self.year < semester.year {
            return true
        }
        if self.year == semester.year {
            if self.title!.lowercased() == "spring" && semester.title!.lowercased() == "fall" {
                return true
            }
        }
        return false
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
        if self.courses!.count == 0 {
            self.valid = false
        }
        
        // All code should check if semester needs validation before calling validateSchedule
        needsValidate = false
        return self.valid
    }
    
    // MARK: - Course Creation Helper Functions
    
    /// Return the first number available in the semester for untitled courses.
    public func nextCourseNumberAvailable() -> Int {
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
    
    // MARK: - Semester Creation Helper Functions
    
    /// Returns a tuple with a date range that encapsulates the given date object based on
    /// semester/quarter default start and end dates and the title typically associated with
    /// the semester range (e.g. "Fall" or "Spring").
    private static func bounds(for date: Date) -> (range: ClosedRange<Date>, title: String) {
        
        let yrParam = Calendar.current.component(.year, from: date)
        let cal = Calendar.current
        
        let defaultFallRange = AppPreference.defaultFallDateRange
        var defaultFallRangeStartComponents = DateComponents()
        defaultFallRangeStartComponents.year = yrParam
        defaultFallRangeStartComponents.minute = cal.component(.minute, from: defaultFallRange.lowerBound)
        defaultFallRangeStartComponents.hour = cal.component(.hour, from: defaultFallRange.lowerBound)
        defaultFallRangeStartComponents.second = cal.component(.second, from: defaultFallRange.lowerBound)
        defaultFallRangeStartComponents.day = cal.component(.day, from: defaultFallRange.lowerBound)
        defaultFallRangeStartComponents.month = cal.component(.month, from: defaultFallRange.lowerBound)
        defaultFallRangeStartComponents.calendar = Calendar.current
        let defaultFallStart = cal.date(from: defaultFallRangeStartComponents)!
        let defaultFallEnd = defaultFallStart.addingTimeInterval(60*60*24*182)
        
        if defaultFallStart.compare(date) == .orderedAscending && defaultFallEnd.compare(date) == .orderedDescending {
            return (defaultFallStart...defaultFallEnd, "Fall")
        } else {

            let defaultSpringRange = AppPreference.defaultSpringDateRange
            var defaultSpringRangeStartComponents = DateComponents()
            defaultSpringRangeStartComponents.year = yrParam
            defaultSpringRangeStartComponents.minute = cal.component(.minute, from: defaultSpringRange.lowerBound)
            defaultSpringRangeStartComponents.hour = cal.component(.hour, from: defaultSpringRange.lowerBound)
            defaultSpringRangeStartComponents.second = cal.component(.second, from: defaultSpringRange.lowerBound)
            defaultSpringRangeStartComponents.day = cal.component(.day, from: defaultSpringRange.lowerBound)
            defaultSpringRangeStartComponents.month = cal.component(.month, from: defaultSpringRange.lowerBound)
            defaultSpringRangeStartComponents.calendar = Calendar.current
            let defaultSpringStart = cal.date(from: defaultSpringRangeStartComponents)!
            let defaultSpringEnd = defaultSpringStart.addingTimeInterval(60*60*24*182)
            
            return (defaultSpringStart...defaultSpringEnd, "Spring")
        }
    }
    
    public static func cleanEmptySemesters() {
        // Fetch semesters in persistent store. Return if found else create new.
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            for sem in semesters {
                if sem.courses!.count == 0 {
                    appDelegate.managedObjectContext.delete( sem )
                }
            }
            appDelegate.saveAction(self)
        } catch { fatalError("Failed to fetch semesters: \(error)") }
        
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
    }
}
