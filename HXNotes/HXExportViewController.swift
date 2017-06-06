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
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Do view setup here.
        if HXExportViewController.lastDestinationUsed == "" {
            HXExportViewController.lastDestinationUsed = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first!
        }
        
        label_path.stringValue = HXExportViewController.lastDestinationUsed
        
        // If owned by a LectureVC
        if let parent = self.parent as? LectureViewController {
            
            label_lectureSelection.stringValue = "selected lecture"
            
            textField_name.stringValue = parent.lecture.course!.title! + " Lecture \(parent.lecture.number) - \(parent.lecture.course!.semester!.year!.year) \(parent.lecture.course!.semester!.title!.capitalized)"
            
            // If owned by a TopbarVC
        } else if let parent = self.parent as? TopbarViewController {
            
            label_lectureSelection.stringValue = "all lectures"
            
            textField_name.stringValue = parent.masterViewController.sidebarViewController.selectedCourse.title! + " Lectures - \(parent.masterViewController.sidebarViewController.selectedCourse.semester!.title!.capitalized) \(parent.masterViewController.sidebarViewController.selectedCourse.semester!.year!.year)"
            
        }
    }
    
    @IBAction func action_close(_ sender: NSButton) {
        if let parent = self.parent as? LectureViewController {
            parent.isExporting = false
        } else if let parent = self.parent as? TopbarViewController {
            parent.masterViewController.isExporting = false
        }
    }
    @IBAction func action_confirm(_ sender: NSButton) {
        action_inputField(textField_name) // make sure name is formatted properly
        var url = URL(fileURLWithPath: self.label_path.stringValue)
        url.appendPathComponent("/" + textField_name.stringValue + ".rtfd")
        if let parent = self.parent as? LectureViewController {
            print("Executing export of \(parent.label_lectureTitle.stringValue) to \(url)")
            parent.owner.exportLecture(from: parent, to: url)
        } else if let parent = self.parent as? TopbarViewController {
            print("Executing export of all lectures to \(url)")
            parent.masterViewController.export(to: url)
        }
    }
    @IBAction func action_select(_ sender: NSButton) {
        if let parent = self.parent as? LectureViewController {
            parent.isExporting = false
            parent.owner.masterViewController.isExporting = true
        } else if let parent = self.parent as? TopbarViewController {
            parent.masterViewController.isExporting = false
            parent.masterViewController.notifyExport()
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
            if let parent = self.parent as? LectureViewController {
                textField_name.stringValue = parent.lecture.course!.title! + " Lecture \(parent.lecture.number) - \(parent.lecture.course!.semester!.year!.year) \(parent.lecture.course!.semester!.title!.capitalized)"
            } else if let parent = self.parent as? TopbarViewController {
                textField_name.stringValue = parent.masterViewController.sidebarViewController.selectedCourse.title! + " Lectures - \(parent.masterViewController.sidebarViewController.selectedCourse.semester!.title!.capitalized) \(parent.masterViewController.sidebarViewController.selectedCourse.semester!.year!.year)"
            }
        } else {
            textField_name.stringValue = input
        }
    }
}
