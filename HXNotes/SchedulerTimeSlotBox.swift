//
//  HXTimeSlotBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerTimeSlotBox: NSView {
    
    var schedulingDelegate: SchedulingDelegate?
    
    let DAY_NAMES = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    weak var timeSlot: TimeSlot!
    
    @IBOutlet weak var buttonTrash: NSButton!
    @IBOutlet weak var pickerStart: NSDatePicker!
    @IBOutlet weak var pickerStop: NSDatePicker!
    @IBOutlet weak var stepperDay: NSStepper!
    @IBOutlet weak var labelWeekday: NSTextField!
    
    @IBOutlet weak var stepperDayWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var trashButtonWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Instance & Initialize
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with timeSlot: TimeSlot) -> SchedulerTimeSlotBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "SchedulerTimeSlotBox"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SchedulerTimeSlotBox}).first as? SchedulerTimeSlotBox {
            newBox.initialize(with: timeSlot)
            return newBox
        }
        return nil
    }
    
    private func initialize(with timeSlot: TimeSlot) {
        self.timeSlot = timeSlot
        
        if timeSlot.course!.lectures!.count > 0 {
            buttonTrash.isEnabled = false
            buttonTrash.isHidden = true
            pickerStart.isEnabled = false
            pickerStop.isEnabled = false
            stepperDay.isEnabled = false
            stepperDay.isHidden = true
            stepperDayWidthConstraint.constant = 0
            trashButtonWidthConstraint.constant = 0
        }
        
        var dateComp = Calendar.current.dateComponents([.year, .month, .day], from: pickerStart.dateValue)
        dateComp.weekday = Int(timeSlot.weekday)
        dateComp.hour = Int(timeSlot.startMinute / 60)
        dateComp.minute = Int(timeSlot.startMinute % 60)
        pickerStart.dateValue = Calendar.current.date(from: dateComp)!
        dateComp.hour = Int(timeSlot.stopMinute / 60)
        dateComp.minute = Int(timeSlot.stopMinute % 60)
        pickerStop.dateValue = Calendar.current.date(from: dateComp)!
        
        labelWeekday.stringValue = DAY_NAMES[Int(timeSlot.weekday)]
        stepperDay.intValue = Int32(timeSlot.weekday)
    }
    
    // MARK: - UI Handlers
    
    @IBAction func action_pickerStart(_ sender: Any) {
        let cal = Calendar.current
        let newStart = cal.component(.hour, from: pickerStart.dateValue) * 60 + cal.component(.minute, from: pickerStart.dateValue)
        
        if Int(newStart) > timeSlot.stopMinute - 5 {
            // Shift pickerStop if pickerStart is being set to a time later than pickerStop
            // add timeslot's previous length to pickerStop and timeSlot.stop
            var dateComp = Calendar.current.dateComponents([.year, .month, .day], from: pickerStart.dateValue)
            dateComp.hour = Int((newStart + (Int(timeSlot.stopMinute) - Int(timeSlot.startMinute))) / 60)
            dateComp.minute = Int((newStart + (Int(timeSlot.stopMinute) - Int(timeSlot.startMinute))) % 60)
            pickerStop.dateValue = cal.date(from: dateComp)!
            timeSlot.stopMinute = Int16(newStart + Int(timeSlot.stopMinute - timeSlot.startMinute))
        }
        
        timeSlot.startMinute = Int16(newStart)
        Swift.print("schedulingDelegate: \(String(describing: schedulingDelegate))")
        schedulingDelegate?.schedulingUpdatedTimeSlot()
    }
    
    @IBAction func action_pickerStop(_ sender: Any) {
        let cal = Calendar.current
        let newStop = cal.component(.hour, from: pickerStop.dateValue) * 60 + cal.component(.minute, from: pickerStop.dateValue)
        
        if Int16(newStop) < timeSlot.startMinute + 5 {
            // Shift pickerStart if pickerStop is being set to a time earlier than pickerStart
            // decrease timeslot's previous length to pickerStart and start
            var dateComp = Calendar.current.dateComponents([.year, .month, .day], from: pickerStart.dateValue)
            dateComp.hour = Int((newStop - (Int(timeSlot.stopMinute) - Int(timeSlot.startMinute))) / 60)
            dateComp.minute = Int((newStop - (Int(timeSlot.stopMinute) - Int(timeSlot.startMinute))) % 60)
            pickerStart.dateValue = cal.date(from: dateComp)!
            timeSlot.startMinute = Int16(Int16(newStop) - (timeSlot.stopMinute - timeSlot.startMinute))
        }
        
        timeSlot.stopMinute = Int16(newStop)
        schedulingDelegate?.schedulingUpdatedTimeSlot()
    }
    
    @IBAction func action_stepper(_ sender: Any) {
        // Available timeslot
        labelWeekday.stringValue = DAY_NAMES[Int(stepperDay.intValue)]
        timeSlot.weekday = Int16(stepperDay.intValue)
        schedulingDelegate?.schedulingUpdatedTimeSlot()
    }
    
    @IBAction func removeTimeSlotBox(_ sender: Any) {
        self.removeFromSuperview()
        schedulingDelegate?.schedulingRemove(timeSlot: timeSlot)
    }
}
