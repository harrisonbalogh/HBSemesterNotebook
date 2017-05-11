//
//  HXWeekBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/10/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXWeekBox: NSBox {

    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE = "week_label_title"
    // Elements of course box
    var labelTitle: NSTextField!
    
    func initialize(weekNumber: Int) {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelTitle = v as! NSTextField
            default: continue
            }
        }
        
        labelTitle.stringValue = "Week \(weekNumber)"
    }
    
}
