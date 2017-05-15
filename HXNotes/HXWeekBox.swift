//
//  HXWeekBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/10/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXWeekBox: NSBox {
    
    /// Return a new instance of a HXWeekBox based on the nib template.
    static func instance(withNumber num: Int) -> HXWeekBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXWeekDividerBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXWeekBox}).first as? HXWeekBox {
            newBox.initialize(weekNumber: num)
            return newBox
        }
        return nil
    }

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
