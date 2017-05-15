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
    static func instance(withNumber num: Int, withDate date: String) -> HXLectureLedger! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureLedger", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureLedger}).first as? HXLectureLedger {
            newBox.initialize(lectureNuber: num, withDate: date)
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
