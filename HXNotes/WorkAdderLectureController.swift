//
//  WorkAdderLectureController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class WorkAdderLectureController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    weak var owner: CoursePageViewController!
    weak var workBox: CourseWorkBox!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if workBox.work!.customTitle {
            textField_title.stringValue = workBox.work!.title!
        } else {
            textField_title.placeholderString = workBox.work!.title!
        }
        
        let nextTimeSlotIndex = owner.sidebarVC.selectedCourse.nextTimeSlotIndex()
        let lecCount = owner.sidebarVC.selectedCourse.timeSlots!.count
        
        for t in 0..<lecCount {
            let timeSlot = owner.sidebarVC.selectedCourse.timeSlots!.array[(t + nextTimeSlotIndex) % lecCount] as! TimeSlot
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
        
        datePicker.minDate = Date().addingTimeInterval(TimeInterval(60))
        timePicker.minDate = Date().addingTimeInterval(TimeInterval(60))
        
        descriptionTextView.string = workBox.work!.content!
        
        NotificationCenter.default.addObserver(self, selector: #selector(action_descriptionUpdate),
                                               name: .NSTextDidChange, object: descriptionTextView)
    }
    @IBOutlet weak var completeButton: NSButton!
    @IBAction func action_complete(_ sender: NSButton) {
        workBox.work!.completed = true
        owner.loadWork()
    }
    
    @IBOutlet weak var textField_title: NSTextField!
    @IBAction func action_titleField(_ sender: NSTextField) {
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
        
        owner.notifyRenamed(work: workBox.work!)
    }
    
    @IBOutlet weak var trailingStackConstraint: NSLayoutConstraint!
    @IBOutlet weak var lectureTimeStackView: NSStackView!
    @IBAction func customDueButton(_ sender: NSButton) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        trailingStackConstraint.animator().constant = self.view.bounds.width
        NSAnimationContext.endGrouping()
    }
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
        owner.notifyCloseWorkDetails()
    }
    
    @IBAction func action_delete(_ sender: NSButton) {
        owner.notifyDelete(work: workBox.work!)
    }
    
    @IBAction func action_datePicker(_ sender: NSDatePicker) {
        
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        workBox.work!.turnIn = nil
        
        if sender == datePicker {
            timePicker.dateValue = datePicker.dateValue
        }
        
        workBox.work!.date = timePicker.dateValue
        
        generateWorkTitle()
        
        owner.notifyDated(work: workBox.work!)
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
            
            owner.notifyRenamed(work: workBox.work!)
        }
    }
    
    // MARK: - Notifiers
    
    ///
    func notifyLectureTimeSelected(_ timeSlot: TimeSlot) {
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        workBox.work!.turnIn = timeSlot
        
        // Calculating date from today's date to next lecture time slot selected...
        
        let date = Date()
        let cal = Calendar.current
        
        let weekday = cal.component(.weekday, from: date)
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let minuteOfDay = hour * 60 + minute
        
        let toWeekday = Int(timeSlot.weekday)
        let toHour = Int(timeSlot.startMinute / 60)
        let toMinute = Int(timeSlot.startMinute % 60)
        let toMinuteOfDay = toHour * 60 + toMinute

        var dueDate = date
        if weekday < toWeekday {
            
            // Add days (to seconds)
            dueDate = dueDate.addingTimeInterval(TimeInterval((toWeekday - weekday) * 24 * 60 * 60))
            // Add hours and minutes difference for rest of today time to target day time
            dueDate = dueDate.addingTimeInterval(TimeInterval(toMinuteOfDay - minuteOfDay) * 60)
            
        } else if weekday == toWeekday && minuteOfDay < toMinuteOfDay {
            
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
        
        owner.notifyDated(work: workBox.work!)
    }
    
}
