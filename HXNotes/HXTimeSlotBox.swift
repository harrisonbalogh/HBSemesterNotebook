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

    weak var timeSlot: TimeSlot!
    weak var editBox: HXCourseEditBox!
    
    @IBOutlet weak var buttonTrash: NSButton!
    @IBOutlet weak var pickerStart: NSDatePicker!
    @IBOutlet weak var pickerStop: NSDatePicker!
    @IBOutlet weak var stepperDay: NSStepper!
    @IBOutlet weak var labelWeekday: NSTextField!
    
    @IBOutlet weak var stepperDayWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var trashButtonWidthConstraint: NSLayoutConstraint!
    
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
        
        let hourStart = Int(timeSlot.startMinuteOfDay / 60)
        let minuteStart = Int(timeSlot.startMinuteOfDay % 60)
        let hourStop = Int(timeSlot.stopMinuteOfDay / 60)
        let minuteStop = Int(timeSlot.stopMinuteOfDay % 60)
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var components = calendar.components([.hour, .minute], from: Date())
        
        components.hour = hourStart
        components.minute = minuteStart
        pickerStart.dateValue = calendar.date(from: components)!
        
        components.hour = hourStop
        components.minute = minuteStop
        pickerStop.dateValue = calendar.date(from: components)!
        
        if timeSlot.weekday == -1 {
            labelWeekday.stringValue = "No Space!"
            stepperDay.isEnabled = false
        } else {
            labelWeekday.stringValue = DAY_NAMES[Int(timeSlot.weekday)]
            stepperDay.intValue = Int32(timeSlot.weekday)
        }
        
        if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: timeSlot.startMinuteOfDay, to: timeSlot.stopMinuteOfDay) {
            timeSlot.valid = true
        } else {
            timeSlot.valid = false
        }
        
        editBox.notifyTimeSlotChange()
    }
    
    
    @IBAction func action_pickerStart(_ sender: Any) {
        let minuteComponent = NSCalendar.current.component(.minute, from: pickerStart.dateValue)
        let hourComponent = NSCalendar.current.component(.hour, from: pickerStart.dateValue)
        let startTime = Int16(hourComponent * 60 + minuteComponent)
        var stopTime: Int16!
        let timeSlotLength = timeSlot.stopMinuteOfDay - timeSlot.startMinuteOfDay
        
        // Check if new start time is passed old stop time
        if startTime > timeSlot.stopMinuteOfDay - 5 {
            stopTime = startTime + timeSlotLength
        } else {
            stopTime = timeSlot.stopMinuteOfDay
        }
        
        timeSlot.stopMinuteOfDay = stopTime
        timeSlot.startMinuteOfDay = startTime
        
        // Update pickerStop
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var components = calendar.components([.hour, .minute], from: Date())
        let hourStop = Int(timeSlot.stopMinuteOfDay / 60)
        let minuteStop = Int(timeSlot.stopMinuteOfDay % 60)
        components.hour = hourStop
        components.minute = minuteStop
        pickerStop.dateValue = calendar.date(from: components)!
        
        //        if stopTime != nil {
        //
        //        } else {
        //            // Unavailable, reset pickerStart
        //            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        //            var components = calendar.components([.hour, .minute], from: Date())
        //            let hourStart = Int(timeSlot.startMinuteOfDay / 60)
        //            let minuteStart = Int(timeSlot.startMinuteOfDay % 60)
        //            components.hour = hourStart
        //            components.minute = minuteStart
        //            pickerStart.dateValue = calendar.date(from: components)!
        //        }
        
        if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: startTime, to: stopTime) {
            timeSlot.valid = true
        } else {
            timeSlot.valid = false
        }
        
        editBox.notifyTimeSlotChange()
    }
    
    
    @IBAction func action_pickerStop(_ sender: Any) {
        let minuteComponent = NSCalendar.current.component(.minute, from: pickerStop.dateValue)
        let hourComponent = NSCalendar.current.component(.hour, from: pickerStop.dateValue)
        let stopTime = Int16(hourComponent * 60 + minuteComponent)
        var startTime: Int16!
        let timeSlotLength = timeSlot.stopMinuteOfDay - timeSlot.startMinuteOfDay
        
        // Check if new stop time is before old start time
        if timeSlot.startMinuteOfDay > stopTime - 5 {
            startTime = stopTime - timeSlotLength
        } else {
            startTime = timeSlot.startMinuteOfDay
        }
        
        timeSlot.stopMinuteOfDay = stopTime
        timeSlot.startMinuteOfDay = startTime
        
        // Update pickerStart
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        var components = calendar.components([.hour, .minute], from: Date())
        let hourStart = Int(timeSlot.startMinuteOfDay / 60)
        let minuteStart = Int(timeSlot.startMinuteOfDay % 60)
        components.hour = hourStart
        components.minute = minuteStart
        pickerStart.dateValue = calendar.date(from: components)!
        
        if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: startTime, to: stopTime) {
            timeSlot.valid = true
        } else {
            timeSlot.valid = false
        }
        
        editBox.notifyTimeSlotChange()
    }
    
    @IBAction func action_stepper(_ sender: Any) {
        // Available timeslot
        labelWeekday.stringValue = DAY_NAMES[Int(stepperDay.intValue)]
        timeSlot.weekday = Int16(stepperDay.intValue)
        
        
        if timeSlot.validateTimeSlot(on: Int16(stepperDay.intValue), from: timeSlot.startMinuteOfDay, to: timeSlot.stopMinuteOfDay) {
            timeSlot.valid = true
        } else {
            timeSlot.valid = false
        }
        
        editBox.notifyTimeSlotChange()
        
        //        if timeSlot.validateTimeSlot(on: Int16(stepperDay.intValue), from: timeSlot.startMinuteOfDay, to: timeSlot.stopMinuteOfDay) {
        //            // Available timeslot
        //            labelWeekday.stringValue = DAY_NAMES[Int(stepperDay.intValue)]
        //            timeSlot.weekday = Int16(stepperDay.intValue)
        //            editBox.notifyTimeSlotChange()
        //            timeSlot.course!.sortTimeSlots()
        //        } else {
        //            // Unavailable, reset it to previous value
        //            stepperDay.intValue = Int32(Int(timeSlot.weekday))
        //        }
    }

    @IBAction func removeTimeSlotBox(_ sender: Any) {
        self.removeFromSuperview()
        editBox.removeTimeSlot(timeSlot)
    }
}
