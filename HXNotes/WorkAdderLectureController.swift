//
//  WorkAdderLectureController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class WorkAdderLectureController: NSViewController {
    
    var schedulingDelegate: SchedulingDelegate?
    var selectionDelegate: SelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    weak var workBox: CourseWorkBox!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if workBox.work!.customTitle {
            textField_title.stringValue = workBox.work!.title!
        } else if !workBox.work.completed {
            textField_title.placeholderString = workBox.work!.title!
        }
        
        if workBox.work.completed {
            completeButton.isEnabled = false
            textField_title.isEditable = false
            descriptionTextView.isEditable = false
            buttonCustomDue.isEnabled = false
            buttonLectureDue.isEnabled = false
            datePicker.isEnabled = false
            timePicker.isEnabled = false
            textField_title.placeholderString = "Untitled Work"
        }
        
        let selectedCourse = workBox.work!.course!

        let nextTimeSlotIndex = selectedCourse.nextTimeSlotIndex()
        let lecCount = selectedCourse.timeSlots!.count
        
        for t in 0..<lecCount {
            let timeSlot = selectedCourse.timeSlots!.array[(t + nextTimeSlotIndex) % lecCount] as! TimeSlot
            let newBox = HXLectureTimeBox.instance(from: timeSlot, with: self)!
            lectureTimeStackView.addArrangedSubview(newBox)
            newBox.widthAnchor.constraint(equalTo: lectureTimeStackView.widthAnchor).isActive = true
            
            guard let selectedTime = workBox.work!.turnIn else { continue }
            
            if timeSlot == selectedTime {
                newBox.select()
            }
        }
        
        if workBox.work!.date != nil {
            
            if workBox.work!.turnIn == nil {
                
                trailingStackConstraint.constant = self.view.bounds.width
                datePicker.dateValue = workBox.work!.date!
                timePicker.dateValue = workBox.work!.date!
            }
        }
        
        datePicker.minDate = workBox.work.course?.semester?.start
        datePicker.maxDate = workBox.work.course?.semester?.end
        timePicker.minDate = datePicker.minDate
        timePicker.maxDate = datePicker.maxDate
        
        descriptionTextView.string = workBox.work!.content!
        
        NotificationCenter.default.addObserver(self, selector: #selector(action_descriptionUpdate),
                                               name: .NSTextDidChange, object: descriptionTextView)
    }
    @IBOutlet weak var completeButton: NSButton!
    @IBAction func action_complete(_ sender: NSButton) {
        workBox.work!.completed = true
        schedulingDelegate?.schedulingUpdatedWork()
    }
    
    @IBOutlet weak var textField_title: NSTextField!
    @IBAction func action_titleField(_ sender: NSTextField) {
        if workBox == nil {
            return
        }
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        // If user leaves the title box empty, a name will be generated...
        if text == "" {
            // ... based on work's due date
            if workBox.work!.date == nil {
                
                workBox.work!.title! = workBox.work!.course!.nextWorkTitleAvailable(with: "Undated Work ")
                
            } else {
                
                workBox.work!.title! = "Placeholder"
                
                // Adjust if work is due today
                let weekday = Calendar.current.component(.weekday, from: Date())
                let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
                let weekdayWork = Calendar.current.component(.weekday, from: workBox.work!.date!)
                let minuteOfDayWork = Calendar.current.component(.hour, from: workBox.work!.date!) * 60 + Calendar.current.component(.minute, from: workBox.work!.date!)
                
                var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                if weekday == weekdayWork && minuteOfDay < minuteOfDayWork {
                    ENGLISH_DAYS[weekday] = "Today"
                }
                let day = ENGLISH_DAYS[weekdayWork]
                
                workBox.work!.title! = workBox.work!.course!.nextWorkTitleAvailable(with: "\(day) Work ")
                
            }
            
            sender.placeholderString = workBox.work!.title!
            workBox.work!.customTitle = false
        } else {
            workBox.work!.customTitle = true
            workBox.work!.title! = text
        }
        
        workBox.labelWork.stringValue = workBox.work.title!
    }
    
    @IBOutlet weak var trailingStackConstraint: NSLayoutConstraint!
    @IBOutlet weak var lectureTimeStackView: NSStackView!
    
    @IBOutlet weak var buttonCustomDue: NSButton!
    @IBAction func customDueButton(_ sender: NSButton) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        trailingStackConstraint.animator().constant = self.view.bounds.width
        NSAnimationContext.endGrouping()
    }
    @IBOutlet weak var buttonLectureDue: NSButton!
    @IBAction func lectureDueButton(_ sender: NSButton) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        trailingStackConstraint.animator().constant = 0
        NSAnimationContext.endGrouping()
    }
    
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet weak var timePicker: NSDatePicker!
    @IBOutlet weak var toggleReoccurring: NSButton!

    @IBAction func action_close(_ sender: NSButton) {
        selectionDelegate?.isEditing(workBox: nil)
    }
    
    @IBAction func action_delete(_ sender: NSButton) {
        schedulingDelegate?.schedulingRemove(workBox: workBox)
    }
    
    @IBAction func action_datePicker(_ sender: NSDatePicker) {
        
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        workBox.work!.turnIn = nil
        
        if sender == datePicker {
            
            var dateComponents = Calendar.current.dateComponents(in: .current, from: datePicker.dateValue)
            dateComponents.hour = Calendar.current.component(.hour, from: timePicker.dateValue)
            dateComponents.minute = Calendar.current.component(.minute, from: timePicker.dateValue)
            let calDate = Calendar.current.date(from: dateComponents)!
            
            timePicker.dateValue = calDate
        }
        
        workBox.work!.date = timePicker.dateValue
        
        generateWorkTitle()
        
        let date = Date()
        
        let day = Calendar.current.component(.day, from: workBox.work.date!)
        let month = Calendar.current.component(.month, from: workBox.work.date!)
        let dayToday = Calendar.current.component(.day, from: date)
        let monthToday = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: workBox.work.date!)
        let minuteOfDay = Calendar.current.component(.hour, from: workBox.work.date!) * 60 + Calendar.current.component(.minute, from: workBox.work.date!)
        let minuteOfDayToday = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
        if monthToday == month && dayToday == day && minuteOfDayToday < minuteOfDay {
            workBox.labelDate.stringValue = HXTimeFormatter.formatTime(Int16(minuteOfDay))
        } else {
            workBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
        }
    }
    
    @IBOutlet var descriptionTextView: NSTextView!
    func action_descriptionUpdate() {
        workBox.work!.content = descriptionTextView.string
    }
    
    // MARK: Convenience Methods
    
    func generateWorkTitle() {
        if !workBox.work!.customTitle {
            workBox.work!.title! = "Placeholder"
            
            // Adjust if work is due today
            let weekday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            let weekdayWork = Calendar.current.component(.weekday, from: workBox.work!.date!)
            let minuteOfDayWork = Calendar.current.component(.hour, from: workBox.work!.date!) * 60 + Calendar.current.component(.minute, from: workBox.work!.date!)
            
            var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            if weekday == weekdayWork && minuteOfDay < minuteOfDayWork {
                ENGLISH_DAYS[weekday] = "Today"
            }
            let day = ENGLISH_DAYS[weekdayWork]
            
            workBox.work!.title! = workBox.work!.course!.nextWorkTitleAvailable(with: "\(day) Work ")
            textField_title.placeholderString = workBox.work!.title!
        }
    }
    
    // MARK: - Notifiers
    
    ///
    func notifyLectureTimeSelected(_ timeSlotBox: HXLectureTimeBox) {
        if workBox.work.completed {
            return
        }
        
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        workBox.work!.turnIn = timeSlotBox.timeSlot
        
        // Calculating date from today's date to next lecture time slot selected...
        
        let date = Date()
        let cal = Calendar.current
        
        let weekday = cal.component(.weekday, from: date)
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let minuteOfDay = hour * 60 + minute
        
        let toWeekday = Int(timeSlotBox.timeSlot.weekday)
        let toHour = Int(timeSlotBox.timeSlot.startMinute / 60)
        let toMinute = Int(timeSlotBox.timeSlot.startMinute % 60)
        let toMinuteOfDay = toHour * 60 + toMinute

        var dueDate = date
        if weekday < toWeekday {
            
            // Add days (to seconds)
            dueDate = dueDate.addingTimeInterval(TimeInterval((toWeekday - weekday) * 24 * 60 * 60))
            // Add hours and minutes difference for rest of today time to target day time
            dueDate = dueDate.addingTimeInterval(TimeInterval(toMinuteOfDay - minuteOfDay) * 60)
            
        } else if weekday == toWeekday && minuteOfDay < toMinuteOfDay && timeSlotBox != (lectureTimeStackView.arrangedSubviews.last as! HXLectureTimeBox) {
            
            // Add difference in hours and minutes
            dueDate = dueDate.addingTimeInterval(TimeInterval(toMinuteOfDay - minuteOfDay) * 60)
            
        } else {
            
            // Roll over to next week
            dueDate = dueDate.addingTimeInterval(TimeInterval(((toWeekday + 7) - weekday) * 24 * 60 * 60))
            // Add hours and minutes difference for rest of today time to target day time
            dueDate = dueDate.addingTimeInterval(TimeInterval(toMinuteOfDay - minuteOfDay) * 60)
            
        }
        
        workBox.work!.date = dueDate
        
        generateWorkTitle()
        
        workBox.labelWork.stringValue = workBox.work!.title!
        
        print("due date is: \(Calendar.current.component(.day, from: dueDate))")
        
        let day = Calendar.current.component(.day, from: workBox.work.date!)
        let month = Calendar.current.component(.month, from: workBox.work.date!)
        let year = Calendar.current.component(.year, from: workBox.work.date!)
        if toWeekday == weekday && minuteOfDay < toMinuteOfDay  && minuteOfDay < toMinuteOfDay && timeSlotBox != (lectureTimeStackView.arrangedSubviews.last as! HXLectureTimeBox)  {
            workBox.labelDate.stringValue = HXTimeFormatter.formatTime(Int16(toMinuteOfDay))
        } else {
            workBox.labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
        }
    }
    
}
