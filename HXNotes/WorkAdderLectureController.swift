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
    weak var workBox: HXWorkBox!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        textField_title.stringValue = workBox.work!.title!
        if workBox.work!.date == nil {
            datePicker.dateValue = Date()
        } else {
            datePicker.dateValue = workBox.work!.date!
        }
        
        datePicker.minDate = Date().addingTimeInterval(TimeInterval(60))
    }
    
    @IBAction func action_textFieldEdit(_ sender: NSButton) {
        NSApp.keyWindow?.makeFirstResponder(textField_title)
    }
    @IBOutlet weak var textField_title: NSTextField!
    @IBOutlet weak var datePicker: NSDatePicker!
    
    @IBAction func action_close(_ sender: NSButton) {
        owner.notifyCloseWorkDetails()
    }
    
    @IBAction func action_fieldTitle(_ sender: NSTextField) {
        let title = sender.stringValue.trimmingCharacters(in: .whitespaces)
        workBox.work!.title = title
        
        owner.notifyRenamed(work: workBox.work!)
    }
    @IBAction func action_delete(_ sender: NSButton) {
        owner.notifyDelete(work: workBox.work!)
    }
    
    @IBOutlet weak var radioWeekly: NSButton!
    @IBOutlet weak var radioDaily: NSButton!
    @IBAction func radioOccurring(_ sender: NSButton) {
    }
    
    @IBAction func toggleReoccurring(_ sender: NSButton) {
        if sender.state == NSOnState {
            radioWeekly.isEnabled = true
            radioDaily.isEnabled = true
        } else {
            radioWeekly.isEnabled = false
            radioDaily.isEnabled = false
        }
    }
    
    @IBOutlet weak var radioLecture: NSButton!
    @IBOutlet weak var radioOnline: NSButton!
    @IBAction func radioTurnIn(_ sender: NSButton) {
    }
    
    @IBAction func toggleTurnIn(_ sender: NSButton) {
        if sender.state == NSOnState {
            radioLecture.isEnabled = true
            radioOnline.isEnabled = true
        } else {
            radioLecture.isEnabled = false
            radioOnline.isEnabled = false
        }
    }
    
    @IBAction func action_datePicker(_ sender: NSDatePicker) {
        print("Datepicker")
        workBox.work!.date = sender.dateValue
        
        owner.notifyDated(work: workBox.work!)
    }
    
    
}
