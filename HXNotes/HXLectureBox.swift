//
//  HXLectureBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXLectureBox: NSBox {
    
    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE      = "lecture_label_title"
    let ID_LABEL_DATE       = "lecture_label_date"
    // Elements of course box
    var labelTitle: NSButton!
    var labelDate: NSTextField!
    
    func initialize(lectureNuber: Int, withDate: String) {
        
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
    }
    
}
