//
//  ExamAdderViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class ExamAdderViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    weak var owner: CoursePageViewController!
    weak var examBox: HXExamBox!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        textField_title.stringValue = examBox.test!.title!
        if examBox.test.date == nil {
            datePicker.dateValue = Date()
        } else {
            datePicker.dateValue = examBox.test!.date!
        }
        
    }
    
    @IBAction func action_textFieldEdit(_ sender: NSButton) {
        NSApp.keyWindow?.makeFirstResponder(textField_title)
    }
    @IBOutlet weak var textField_title: NSTextField!
    @IBOutlet weak var datePicker: NSDatePicker!
    
    @IBAction func action_close(_ sender: NSButton) {
        owner.notifyCloseTestDetails()
    }
    
    @IBAction func action_fieldTitle(_ sender: NSTextField) {
        let title = sender.stringValue.trimmingCharacters(in: .whitespaces)
        examBox.test!.title = title
        
        owner.notifyRenamed(test: examBox.test!)
    }
    
    @IBAction func action_delete(_ sender: NSButton) {
        owner.notifyDelete(test: examBox.test!)
    }
    
    @IBOutlet weak var radioWeekly: NSButton!
    @IBOutlet weak var radioDaily: NSButton!
    @IBAction func radioReoccurring(_ sender: NSButton) {
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
    @IBAction func radioLocation(_ sender: NSButton) {
        
    }
    @IBAction func toggleLocation(_ sender: NSButton) {
        if sender.state == NSOnState {
            radioLecture.isEnabled = true
            radioOnline.isEnabled = true
        } else {
            radioLecture.isEnabled = false
            radioOnline.isEnabled = false
        }
    }
    
    
    @IBAction func action_datePicker(_ sender: NSDatePicker) {
        examBox.test!.date = sender.dateValue
        
        owner.notifyDated(test: examBox.test!)
    }
}
