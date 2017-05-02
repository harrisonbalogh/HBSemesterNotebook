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
    var timelineTopConstraint: NSLayoutConstraint!
    
    var timelineViewController: TimelineViewController!
    var calendarViewController: CalendarViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelineTopConstraint = container_timeline.topAnchor.constraint(equalTo: self.view.topAnchor)
        timelineTopConstraint.isActive = true
        
        let strybrd = NSStoryboard.init(name: "Main", bundle: nil)
        if let newController = strybrd.instantiateController(withIdentifier: "CalendarID") as? CalendarViewController {
            calendarViewController = newController
            self.addChildViewController(calendarViewController)
            calendarViewController.masterViewController = self
        }
    }
    
    override func viewDidAppear() {
        if let timelineVC = self.childViewControllers.filter({$0.className == "HXNotes.TimelineViewController"}).first as? TimelineViewController {
            self.timelineViewController = timelineVC
            self.timelineViewController.masterViewController = self
        }
    }
    
    /**
     Notifies MasterViewController from TimelineViewController
     that user has landed on a year.

     - parameters:
        - year: The year as an Int selected in Timeline
     
    */
    func selectedYear(_ year: Int) {
        
    }
    func clearYear() {
        if calendarViewController.view.superview != nil {
            calendarViewController.view.removeFromSuperview()
        }
    }
    func editSemester(_ semester: String) {
        container_content.addSubview(calendarViewController.view)
        calendarViewController.view.frame = container_content.bounds
        calendarViewController.view.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
    }
    func closeCalendar() {
        if calendarViewController.view.superview != nil {
            calendarViewController.view.removeFromSuperview()
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
