//
//  TestAdderLectureController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class TestAdderViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    weak var owner: CoursePageViewController!
    weak var testBox: CourseTestBox!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if testBox.test!.customTitle {
            textField_title.stringValue = testBox.test!.title!
        } else {
            textField_title.placeholderString = testBox.test!.title!
        }
        
        let nextTimeSlotIndex = owner.sidebarVC.selectedCourse.nextTimeSlotIndex()
        let lecCount = owner.sidebarVC.selectedCourse.timeSlots!.count
        
        for t in 0..<lecCount {
            let timeSlot = owner.sidebarVC.selectedCourse.timeSlots!.array[(t + nextTimeSlotIndex) % lecCount] as! TimeSlot
            let newBox = HXLectureTimeBox.instance(from: timeSlot, with: self)!
            lectureTimeStackView.addArrangedSubview(newBox)
            newBox.widthAnchor.constraint(equalTo: lectureTimeStackView.widthAnchor).isActive = true
            
            guard let selectedTime = testBox.test!.location else { continue }
            
            if timeSlot == selectedTime {
                newBox.select()
            }
        }
        
        if testBox.test!.date != nil {
            
            if testBox.test!.location == nil {
                
                trailingStackConstraint.constant = self.view.bounds.width
                datePicker.dateValue = testBox.test!.date!
                timePicker.dateValue = testBox.test!.date!
            }
        }
        
        datePicker.minDate = Date().addingTimeInterval(TimeInterval(60))
        timePicker.minDate = Date().addingTimeInterval(TimeInterval(60))
        
        descriptionTextView.string = testBox.test!.content!
        
        NotificationCenter.default.addObserver(self, selector: #selector(action_descriptionUpdate),
                                               name: .NSTextDidChange, object: descriptionTextView)
    }
    @IBOutlet weak var completeButton: NSButton!
    @IBAction func action_complete(_ sender: NSButton) {
        testBox.test!.completed = true
        owner.loadTests()
    }
    
    @IBOutlet weak var textField_title: NSTextField!
    @IBAction func action_titleField(_ sender: NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        // If user leaves the title box empty, a name will be generated...
        if text == "" {
            // ... based on tests' due date
            if testBox.test!.date == nil {
                
                testBox.test!.title! = testBox.test!.course!.nextTestTitleAvailable(with: "Undated Test ")
                
            } else {
                
                testBox.test!.title! = "Placeholder"
                
                // Adjust if test is due today
                let weekday = Calendar.current.component(.weekday, from: Date())
                let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
                let weekdayTest = Calendar.current.component(.weekday, from: testBox.test!.date!)
                let minuteOfDayTest = Calendar.current.component(.hour, from: testBox.test!.date!) * 60 + Calendar.current.component(.minute, from: testBox.test!.date!)
                
                var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                if weekday == weekdayTest && minuteOfDay < minuteOfDayTest {
                    ENGLISH_DAYS[weekday] = "Today"
                }
                let day = ENGLISH_DAYS[weekdayTest]
                
                testBox.test!.title! = testBox.test!.course!.nextTestTitleAvailable(with: "\(day) Test ")
                
            }
            
            sender.placeholderString = testBox.test!.title!
            testBox.test!.customTitle = false
        } else {
            testBox.test!.customTitle = true
            testBox.test!.title! = text
        }
        
        owner.notifyRenamed(test: testBox.test!)
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
        owner.notifyCloseTestDetails()
    }
    
    @IBAction func action_delete(_ sender: NSButton) {
        owner.notifyDelete(test: testBox.test!)
    }
    
    @IBAction func action_datePicker(_ sender: NSDatePicker) {
        
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        testBox.test!.location = nil
        
        if sender == datePicker {
            timePicker.dateValue = datePicker.dateValue
        }
        
        testBox.test!.date = timePicker.dateValue
        
        generateTestTitle()
        
        owner.notifyDated(test: testBox.test!)
    }
    
    @IBOutlet var descriptionTextView: NSTextView!
    func action_descriptionUpdate() {
        testBox.test!.content = descriptionTextView.string
    }
    
    // MARK: Convenience Methods
    
    func generateTestTitle() {
        if !testBox.test!.customTitle {
            testBox.test!.title! = "Placeholder"
            
            // Adjust if test is due today
            let weekday = Calendar.current.component(.weekday, from: Date())
            let minuteOfDay = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
            let weekdayTest = Calendar.current.component(.weekday, from: testBox.test!.date!)
            let minuteOfDayTest = Calendar.current.component(.hour, from: testBox.test!.date!) * 60 + Calendar.current.component(.minute, from: testBox.test!.date!)
            
            var ENGLISH_DAYS = ["","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            if weekday == weekdayTest && minuteOfDay < minuteOfDayTest {
                ENGLISH_DAYS[weekday] = "Today"
            }
            let day = ENGLISH_DAYS[weekdayTest]
            
            testBox.test!.title! = testBox.test!.course!.nextTestTitleAvailable(with: "\(day) Test ")
            textField_title.placeholderString = testBox.test!.title!
            
            owner.notifyRenamed(test: testBox.test!)
        }
    }
    
    // MARK: - Notifiers
    
    ///
    func notifyLectureTimeSelected(_ timeSlot: TimeSlot) {
        for case let view as HXLectureTimeBox in lectureTimeStackView.arrangedSubviews {
            view.deselect()
        }
        testBox.test!.location = timeSlot
        
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
        
        testBox.test!.date = dueDate
        
        generateTestTitle()
        
        owner.notifyDated(test: testBox.test!)
    }
    
}
