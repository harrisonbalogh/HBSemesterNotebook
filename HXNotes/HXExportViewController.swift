//
//  HXExportViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/4/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXExportViewController: NSViewController {
    
    static var lastDestinationUsed: String = ""
    
    @IBOutlet weak var label_lectureSelection: NSTextField!
    @IBOutlet weak var label_path: NSTextField!
    @IBOutlet weak var textField_name: NSTextField!
    @IBOutlet weak var button_confirm: NSButton!
    @IBOutlet weak var label_error: NSTextField!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Do view setup here.
        if HXExportViewController.lastDestinationUsed == "" {
            HXExportViewController.lastDestinationUsed = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        }
        
        label_path.stringValue = HXExportViewController.lastDestinationUsed
        
        // If owned by a LectureVC
        if let parent = self.parent as? LectureCollectionViewItem {
            
            label_lectureSelection.stringValue = "selected lecture"
            
            textField_name.stringValue = parent.lecture.course!.title! + " Lecture \(parent.lecture.number) - \(parent.lecture.course!.semester!.year) \(parent.lecture.course!.semester!.title!.capitalized)"
            
            // If owned by a TopbarVC
        } else if let parent = self.parent as? EditorViewController {
            
            label_lectureSelection.stringValue = "all lectures"
            
            textField_name.stringValue = parent.selectedCourse.title! + " Lectures - \(parent.selectedCourse.semester!.title!.capitalized) \(parent.selectedCourse.semester!.year)"
            
        }
        
        // Listen to textField changing to update confirm button
        NotificationCenter.default.addObserver(self, selector: #selector(HXExportViewController.textField_textChange),
                                               name: .NSControlTextDidChange, object: textField_name)
    }
    /// Check if the text in the name field is appropriate for saving a file.
    func textField_textChange() {
        let input = textField_name.stringValue.trimmingCharacters(in: .whitespaces)
        if input.contains("/") || input.contains(".") || input == "" || input.contains(":") {
            button_confirm.isEnabled = false
            if input.contains("/") {
                label_error.stringValue = "Cannot contain '/'"
            }
            if input.contains(".") {
                label_error.stringValue = "Cannot contain '.'"
            }
            if input.contains(":") {
                label_error.stringValue = "Cannot contain ':'"
            }
            if input == "" {
                label_error.stringValue = "Empty file name."
            }
        } else {
            button_confirm.isEnabled = true
            label_error.stringValue = ""
        }
    }
    
    @IBAction func action_close(_ sender: NSButton) {
        if let parent = self.parent as? LectureCollectionViewItem {
            parent.isExporting = false
        } else if let parent = self.parent as? EditorViewController {
            parent.isExporting = false
        }
    }
    @IBAction func action_confirm(_ sender: NSButton) {
        action_inputField(textField_name) // make sure name is formatted properly
        var url = URL(fileURLWithPath: self.label_path.stringValue)
        url.appendPathComponent("/" + textField_name.stringValue + ".rtfd")
        if let parent = self.parent as? LectureCollectionViewItem {
            parent.export(to: url)
        } else if let parent = self.parent as? EditorViewController {
            parent.export(to: url)
        }
    }
    @IBAction func action_select(_ sender: NSButton) {
        if let parent = self.parent as? LectureCollectionViewItem {
            parent.isExporting = false
            parent.owner.isExporting = true
        } else if let parent = self.parent as? EditorViewController {
            parent.isExporting = false
            if parent.lectureFocused != nil {
                parent.lectureFocused.isExporting = true
            }
        }
    }
    @IBAction func action_path(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
//        openPanel.nameFieldStringValue
        openPanel.prompt = "Select"
        
        openPanel.beginSheetModal(for: NSApp.keyWindow!, completionHandler: {result in
            if result == NSFileHandlingPanelOKButton {
                self.label_path.stringValue = openPanel.url!.absoluteString
                HXExportViewController.lastDestinationUsed = openPanel.url!.path
            }
        })
    }
    @IBAction func action_inputField(_ sender: NSTextField) {
        let input = textField_name.stringValue.trimmingCharacters(in: .whitespaces)
        
        // Check if it has content
        if input == "" {
            // If owned by a LectureVC
            if let parent = self.parent as? LectureCollectionViewItem {
                textField_name.stringValue = parent.lecture.course!.title! + " Lecture \(parent.lecture.number) - \(parent.lecture.course!.semester!.year) \(parent.lecture.course!.semester!.title!.capitalized)"
            } else if let parent = self.parent as? EditorViewController {
                textField_name.stringValue = parent.selectedCourse.title! + " Lectures - \(parent.selectedCourse.semester!.title!.capitalized) \(parent.selectedCourse.semester!.year)"
            }
        } else {
            textField_name.stringValue = input
        }
        textField_textChange()
    }
}
