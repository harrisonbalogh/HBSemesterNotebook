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
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_TRASH     = "timeslot_button_trash"
    let ID_LABEL_WEEKDAY    = "timeslot_weekday_label"
    let ID_PICKER_START     = "timeslot_picker_start"
    let ID_PICKER_STOP      = "timeslot_picker_stop"
    let ID_STEPPER_WEEKDAY  = "timeslot_stepper_weekday"
    // Elements of course box
    var buttonTrash: NSButton!
    var timeSlot: TimeSlot!
    var editBox: HXCourseEditBox!
    var labelWeekday: NSTextField!
    var pickerStart: NSDatePicker!
    var pickerStop: NSDatePicker!
    var stepperDay: NSStepper!
    
    private func initialize(with timeSlot: TimeSlot, for editBox: HXCourseEditBox) {
        self.timeSlot = timeSlot
        self.editBox = editBox
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case ID_BUTTON_TRASH:
                buttonTrash = v as! NSButton
            case ID_LABEL_WEEKDAY:
                labelWeekday = v as! NSTextField
            case ID_PICKER_START:
                pickerStart = v as! NSDatePicker
            case ID_PICKER_STOP:
                pickerStop = v as! NSDatePicker
            case ID_STEPPER_WEEKDAY:
                stepperDay = v as! NSStepper
            default: continue
            }
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
        
        // Initialize button functionality
        buttonTrash.target = self
        buttonTrash.action = #selector(self.removeTimeSlotBox)
        
        stepperDay.target = self
        stepperDay.action = #selector(self.action_stepper)
        
        // Initialize NSDatePicker actions
        pickerStart.target = self
        pickerStart.action = #selector(self.action_pickerStart)
        pickerStop.target = self
        pickerStop.action = #selector(self.action_pickerStop)
        
        editBox.notifyTimeSlotChange()
    }
    
    func action_pickerStart() {
        let minuteComponent = NSCalendar.current.component(.minute, from: pickerStart.dateValue)
        let hourComponent = NSCalendar.current.component(.hour, from: pickerStart.dateValue)
        let startTime = Int16(hourComponent * 60 + minuteComponent)
        var stopTime: Int16!
        let timeSlotLength = timeSlot.stopMinuteOfDay - timeSlot.startMinuteOfDay
        
        // Check if new start time is passed old stop time
        if startTime > timeSlot.stopMinuteOfDay - 5 {
            // Try pushing back stop time
            if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: startTime, to: startTime + timeSlotLength) {
                stopTime = startTime + timeSlotLength
            }
        } else {
            if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: startTime, to: timeSlot.stopMinuteOfDay) {
                stopTime = timeSlot.stopMinuteOfDay
            }
        }
        
        if stopTime != nil {
            timeSlot.stopMinuteOfDay = stopTime
            timeSlot.startMinuteOfDay = startTime
            editBox.notifyTimeSlotChange()
            // Update pickerStop
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            var components = calendar.components([.hour, .minute], from: Date())
            let hourStop = Int(timeSlot.stopMinuteOfDay / 60)
            let minuteStop = Int(timeSlot.stopMinuteOfDay % 60)
            components.hour = hourStop
            components.minute = minuteStop
            pickerStop.dateValue = calendar.date(from: components)!
            
        } else {
            // Unavailable, reset pickerStart
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            var components = calendar.components([.hour, .minute], from: Date())
            let hourStart = Int(timeSlot.startMinuteOfDay / 60)
            let minuteStart = Int(timeSlot.startMinuteOfDay % 60)
            components.hour = hourStart
            components.minute = minuteStart
            pickerStart.dateValue = calendar.date(from: components)!
        }
    }
    func action_pickerStop() {
        let minuteComponent = NSCalendar.current.component(.minute, from: pickerStop.dateValue)
        let hourComponent = NSCalendar.current.component(.hour, from: pickerStop.dateValue)
        let stopTime = Int16(hourComponent * 60 + minuteComponent)
        var startTime: Int16!
        let timeSlotLength = timeSlot.stopMinuteOfDay - timeSlot.startMinuteOfDay

        // Check if new stop time is before old start time
        if timeSlot.startMinuteOfDay > stopTime - 5 {
            // Try pushing forward start time
            if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: stopTime - timeSlotLength, to: stopTime) {
                startTime = stopTime - timeSlotLength
            }
        } else {
            if timeSlot.validateTimeSlot(on: timeSlot.weekday, from: timeSlot.startMinuteOfDay, to: stopTime) {
                startTime = timeSlot.startMinuteOfDay
            }
        }
        
        if startTime != nil {
            timeSlot.stopMinuteOfDay = stopTime
            timeSlot.startMinuteOfDay = startTime
            editBox.notifyTimeSlotChange()
            // Update pickerStart
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            var components = calendar.components([.hour, .minute], from: Date())
            let hourStart = Int(timeSlot.startMinuteOfDay / 60)
            let minuteStart = Int(timeSlot.startMinuteOfDay % 60)
            components.hour = hourStart
            components.minute = minuteStart
            pickerStart.dateValue = calendar.date(from: components)!
            
        } else {
            // Unavailable, reset pickerStop
            let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
            var components = calendar.components([.hour, .minute], from: Date())
            let hourStop = Int(timeSlot.stopMinuteOfDay / 60)
            let minuteStop = Int(timeSlot.stopMinuteOfDay % 60)
            components.hour = hourStop
            components.minute = minuteStop
            pickerStop.dateValue = calendar.date(from: components)!
        }
    }
    
    func action_stepper() {
        if timeSlot.validateTimeSlot(on: Int16(stepperDay.intValue), from: timeSlot.startMinuteOfDay, to: timeSlot.stopMinuteOfDay) {
            // Available timeslot
            labelWeekday.stringValue = DAY_NAMES[Int(stepperDay.intValue)]
            timeSlot.weekday = Int16(stepperDay.intValue)
            editBox.notifyTimeSlotChange()
        } else {
            // Unavailable, reset it to previous value
            stepperDay.intValue = Int32(Int(timeSlot.weekday))
        }
    }
    
    func removeTimeSlotBox() {
        self.removeFromSuperview()
        editBox.removeTimeSlot(timeSlot)
    }
}
