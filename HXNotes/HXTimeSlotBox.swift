//
//  HXTimeSlotBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXTimeSlotBox: NSView {
    
    let DAY_NAMES = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    weak var timeSlot: TimeSlot!
    weak var editBox: HXCourseEditBox!
    
    @IBOutlet weak var buttonTrash: NSButton!
    @IBOutlet weak var pickerStart: NSDatePicker!
    @IBOutlet weak var pickerStop: NSDatePicker!
    @IBOutlet weak var stepperDay: NSStepper!
    @IBOutlet weak var labelWeekday: NSTextField!
    
    @IBOutlet weak var stepperDayWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var trashButtonWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Instance & Initialize
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with timeSlot: TimeSlot, for editBox: HXCourseEditBox) -> HXTimeSlotBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXTimeSlotBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXTimeSlotBox}).first as? HXTimeSlotBox {
            newBox.initialize(with: timeSlot, for: editBox)
            return newBox
        }
        return nil
    }
    
    private func initialize(with timeSlot: TimeSlot, for editBox: HXCourseEditBox) {
        self.timeSlot = timeSlot
        self.editBox = editBox
        
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
        
        var dateComp = DateComponents()
        dateComp.weekday = Int(timeSlot.weekday)
        dateComp.hour = Int(timeSlot.startMinute / 60)
        dateComp.minute = Int(timeSlot.startMinute % 60)
        pickerStart.dateValue = Calendar.current.date(from: dateComp)!
        dateComp.hour = Int(timeSlot.stopMinute / 60)
        dateComp.minute = Int(timeSlot.stopMinute % 60)
        pickerStop.dateValue = Calendar.current.date(from: dateComp)!
        
        labelWeekday.stringValue = DAY_NAMES[Int(timeSlot.weekday)]
        stepperDay.intValue = Int32(timeSlot.weekday)
        
        editBox.notifyTimeSlotChange()
    }
    
    // MARK: - UI Handlers
    
    @IBAction func action_pickerStart(_ sender: Any) {
        let cal = Calendar.current
        let newStart = cal.component(.hour, from: pickerStart.dateValue) * 60 + cal.component(.minute, from: pickerStart.dateValue)
        
        if Int(newStart) > timeSlot.stopMinute - 5 {
            // Shift pickerStop if pickerStart is being set to a time later than pickerStop
            // add timeslot's previous length to pickerStop and timeSlot.stop
            var dateComp = DateComponents()
            dateComp.hour = Int((newStart + (timeSlot.stopMinute - timeSlot.startMinute)) / 60)
            dateComp.minute = Int((newStart + (timeSlot.stopMinute - timeSlot.startMinute)) % 60)
            pickerStop.dateValue = cal.date(from: dateComp)!
            timeSlot.stopMinute = Int16(newStart + Int(timeSlot.stopMinute - timeSlot.startMinute))
        }
        
        timeSlot.startMinute = Int16(newStart)
        editBox.notifyTimeSlotChange()
    }
    
    
    @IBAction func action_pickerStop(_ sender: Any) {
        let cal = Calendar.current
        let newStop = cal.component(.hour, from: pickerStop.dateValue) * 60 + cal.component(.minute, from: pickerStop.dateValue)
        
        if Int16(newStop) < timeSlot.startMinute + 5 {
            // Shift pickerStart if pickerStop is being set to a time earlier than pickerStart
            // decrease timeslot's previous length to pickerStart and start
            var dateComp = DateComponents()
            dateComp.hour = Int((newStop - (timeSlot.stopMinute - timeSlot.startMinute)) / 60)
            dateComp.minute = Int((newStop - (timeSlot.stopMinute - timeSlot.startMinute)) % 60)
            pickerStart.dateValue = cal.date(from: dateComp)!
            timeSlot.startMinute = Int16(newStop - (timeSlot.stopMinute - timeSlot.startMinute))
        }
        
        timeSlot.stopMinute = Int16(newStop)
        editBox.notifyTimeSlotChange()
    }
    
    @IBAction func action_stepper(_ sender: Any) {
        // Available timeslot
        labelWeekday.stringValue = DAY_NAMES[Int(stepperDay.intValue)]
        timeSlot.weekday = Int16(stepperDay.intValue)
        editBox.notifyTimeSlotChange()
    }

    @IBAction func removeTimeSlotBox(_ sender: Any) {
        self.removeFromSuperview()
        editBox.removeTimeSlot(timeSlot)
    }
}
