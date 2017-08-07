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
        Bundle.main.loadNibNamed("HXWeekBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXWeekBox}).first as? HXWeekBox {
            newBox.initialize(weekNumber: num)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTitle: NSTextField!
    
    func initialize(weekNumber: Int) {
        
        labelTitle.stringValue = "Week \(weekNumber)"
    }
    
}
