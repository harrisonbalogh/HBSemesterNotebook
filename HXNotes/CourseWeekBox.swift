//
//  SchedulerWeekBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseWeekBox: NSBox {

    /// Return a new instance of a HXWeekBox based on the nib template.
    static func instance(with number: Int) -> CourseWeekBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "CourseWeekBox"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseWeekBox}).first as? CourseWeekBox {
            newBox.initialize(with: number)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTitle: NSTextField!
    
    func initialize(with number: Int) {
        labelTitle.stringValue = "Week \(number)"
    }
    
}
