//
//  HXFindViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/4/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXFindViewController: NSViewController {
    
    static var lastFindUsed: String = ""
    
    @IBOutlet weak var label_lectureSelection: NSTextField!
    @IBOutlet weak var textField_find: NSTextField!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // If owned by a LectureVC
        if self.parent is LectureViewController {
            
            label_lectureSelection.stringValue = "selected lecture."
            textField_find.stringValue = HXFindViewController.lastFindUsed

        // If owned by a TopbarVC
        } else if self.parent is TopbarViewController {
            
            label_lectureSelection.stringValue = "all lectures."
            textField_find.stringValue = HXFindViewController.lastFindUsed
            HXFindViewController.lastFindUsed = ""
            
        }
    }
    
    @IBAction func action_close(_ sender: NSButton) {
        if let parent = self.parent as? LectureViewController {
            parent.isFinding = false
        } else if let parent = self.parent as? TopbarViewController {
            parent.masterViewController.isFinding = false
        }
    }
    @IBAction func action_right(_ sender: NSButton) {
    }
    @IBAction func action_left(_ sender: NSButton) {
    }
    @IBAction func action_select(_ sender: NSButton) {
        if let parent = self.parent as? LectureViewController {
            HXFindViewController.lastFindUsed = textField_find.stringValue
            parent.isFinding = false
            parent.owner.masterViewController.isFinding = true
        } else if let parent = self.parent as? TopbarViewController {
            parent.masterViewController.isFinding = false
        }
    }
    @IBAction func action_textField(_ sender: NSTextField) {
    }
}
