//
//  HXLectureLedger.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXLectureLedger: NSBox {
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(withNumber num: Int, withDate date: String, owner: EditorViewController) -> HXLectureLedger! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureLedger", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureLedger}).first as? HXLectureLedger {
            newBox.initialize(lectureNuber: num, withDate: date, owner: owner)
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
    
    var parentController: EditorViewController!
    
    func initialize(lectureNuber: Int, withDate: String, owner: EditorViewController) {
        
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
        
        labelTitle.title = "Lecture \(lectureNuber)"
        
        labelDate.stringValue = withDate
        
        self.parentController = owner
        
        labelTitle.target = self
        labelTitle.action = #selector(HXLectureLedger.action_clickLecture)
    }
    
    func action_clickLecture() {
        parentController.scrollToLecture(labelTitle.title)
    }
    
    func focusVisuals(_ focus: Bool) {
        if focus {
            
        } else {
            
        }
    }
}
