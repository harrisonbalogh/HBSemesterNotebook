//
//  SchedulerViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/8/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerViewController: NSViewController {

    @IBOutlet weak var scheduleBox: HXScheduleBox!
    
    private var editingSemester: Semester! {
        didSet {
            if editingSemester != nil {
                clearTimeSlots()
                loadTimeSlots()
            }
        }
    }
    
    func initialize(with semester: Semester) {
        
        editingSemester = semester
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        scheduleBox.initialize()
    }
    
    // MARK: - Adding TimeSlots
    
    ///
    private func clearTimeSlots() {
        scheduleBox.clearTimeSlotVisuals()
        scheduleBox.needsDisplay = true
    }
    
    ///
    private func loadTimeSlots() {
        if editingSemester != nil {
            for case let course as Course in editingSemester.courses! {
                for case let timeSlot as TimeSlot in course.timeSlots! {
                    if timeSlot.weekday != -1 {
                        scheduleBox.addTimeSlotVisual(timeSlot)
                    }
                }
            }
        }
        scheduleBox.needsDisplay = true
    }
    
    // MARK: - Notifiers
    
    /// Simply clears and redraws all timeslots. Handles removing and adding
    /// of timeslots
    func notifyTimeSlotChange() {
        clearTimeSlots()
        loadTimeSlots()
    }
}