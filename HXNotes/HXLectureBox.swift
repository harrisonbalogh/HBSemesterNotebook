//
//  HXLectureLedger.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//
    
import Cocoa

class HXLectureBox: NSBox {
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(numbered number: Int16, dated date: String, owner: SidebarViewController) -> HXLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureBox}).first as? HXLectureBox {
            newBox.initialize(numbered: Int(number), dated: date, owner: owner)
            return newBox
        }
        return nil
    }
    
    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE      = "lecture_label_title"
    let ID_LABEL_DATE       = "lecture_label_date"
    // Elements of course box
    var labelTitle: NSButton!
    var labelDate: NSTextField!
    
    var parentController: SidebarViewController!
    
    func initialize(numbered number: Int, dated date: String, owner: SidebarViewController) {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelTitle = v as! NSButton
            case ID_LABEL_DATE:
                labelDate = v as! NSTextField
            default: continue
            }
        }
        
        labelTitle.title = "Lecture \(number)"
        
        labelDate.stringValue = date
        
        self.parentController = owner
        
        labelTitle.target = self
        labelTitle.action = #selector(HXLectureBox.action_clickLecture)
    }
    
    func action_clickLecture() {
        
        parentController.select(lecture: labelTitle.title)
    }
    
    func focus() {
        labelTitle.isBordered = true
    }
    
    func unfocus() {
        labelTitle.isBordered = false
    }
}
