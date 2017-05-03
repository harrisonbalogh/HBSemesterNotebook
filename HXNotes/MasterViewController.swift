//
//  MasterViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/24/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Darwin

class MasterViewController: NSViewController {
    
    @IBOutlet weak var container_content: NSView!
    @IBOutlet weak var container_timeline: NSView!
    // Reference timeline top constraint to hide/show this container
    var timelineTopConstraint: NSLayoutConstraint!
    
    // Children controllers
    var timelineViewController: TimelineViewController!
    // The following 2 controllers fill container_content as is needed
    var calendarViewController: CalendarViewController!
    var editorViewController: EditorViewController!
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // Object models informed by TimelineViewController
    var yearSelected: Year!
    var semesterSelected: Semester!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelineTopConstraint = container_timeline.topAnchor.constraint(equalTo: self.view.topAnchor)
        timelineTopConstraint.isActive = true
    }
    
    override func viewDidAppear() {
        if let timelineVC = self.childViewControllers.filter({$0.className == "HXNotes.TimelineViewController"}).first as? TimelineViewController {
            self.timelineViewController = timelineVC
            self.timelineViewController.masterViewController = self
        }
    }
    
     /// Notifies MasterViewController from TimelineViewController that user has landed on a year.
    func selectedYear(_ year: Int) {
        // Try fetching this year in persistent store
        let yearFetch = NSFetchRequest<Year>(entityName: "Year")
        do {
            let years = try appDelegate.managedObjectContext.fetch(yearFetch) as [Year]
            if let foundYear = years.filter({$0.year == Int16(year)}).first {
                // This year already present in store so load
                yearSelected = foundYear
            } else {
                // Create year since it wasn't found
                let newYear = NSEntityDescription.insertNewObject(forEntityName: "Year", into: appDelegate.managedObjectContext) as! Year
                newYear.year = Int16(year)
                yearSelected = newYear
            }
        } catch { fatalError("Failed to fetch years: \(error)") }
    }
    
    /// Notifies MasterViewController from TimelineViewCotnroler that user has selected a semester.
    func selectSemester(_ semester: String) {
        // Try fetching this semester:year in persistent store
        let semesterFetch = NSFetchRequest<Semester>(entityName: "Semester")
        do {
            let semesters = try appDelegate.managedObjectContext.fetch(semesterFetch) as [Semester]
            if let foundSemester = semesters.filter({$0.title == semester && $0.year == yearSelected}).first {
                // This semester already present in store so load
                semesterSelected = foundSemester
            } else {
                // Create semester since it wasn't found
                let newSemester = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
                newSemester.title = semester
                newSemester.year = yearSelected
                semesterSelected = newSemester
            }
        } catch { fatalError("Failed to fetch semesters: \(error)")}
        
        var foundCoursesForSemester = false
        // Check if courses are present for this semester:year
        let courseFetch = NSFetchRequest<Course>(entityName: "Course")
        do {
            let courses = try appDelegate.managedObjectContext.fetch(courseFetch) as [Course]
            if courses.filter({$0.semester == semesterSelected}).count > 0 {
                // Check if courses exist in this semester
                foundCoursesForSemester = true
            }
        } catch { fatalError("Failed to fetch times: \(error)") }
        
        if foundCoursesForSemester {
            popCalendar()
            popEditor()
            
            pushEditor()
        } else {
            popCalendar()
            popEditor()
            
            pushCalendar()
        }
        
    }
    
    func pushCalendar() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "CalendarID") as? CalendarViewController {
            calendarViewController = newController
            self.addChildViewController(calendarViewController)
            container_content.addSubview(calendarViewController.view)
            calendarViewController.masterViewController = self
            calendarViewController.view.frame = container_content.bounds
            calendarViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
            calendarViewController.thisYear = yearSelected
            calendarViewController.thisSemester = semesterSelected
            calendarViewController.loadCourses()
        }
    }
    func pushEditor() {
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "EditorID") as? EditorViewController {
            editorViewController = newController
            self.addChildViewController(editorViewController)
            container_content.addSubview(editorViewController.view)
            editorViewController.view.frame = container_content.bounds
            editorViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        }
    }
    func popCalendar() {
        if calendarViewController != nil {
            if calendarViewController.view.superview != nil {
                calendarViewController.view.removeFromSuperview()
                calendarViewController.removeFromParentViewController()
            }
        }
        
    }
    func popEditor() {
        if editorViewController != nil {
            if editorViewController.view.superview != nil {
                editorViewController.view.removeFromSuperview()
                editorViewController.removeFromParentViewController()
            }
        }
    }
    
    func discloseTimeline(_ state: Int) {
        if state == NSOnState {
            timelineTopConstraint.constant = 0
            
        } else if state == NSOffState {
            timelineTopConstraint.constant = -105
        }
    }
}
