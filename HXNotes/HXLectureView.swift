//
//  HXLectureView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/14/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXLectureView: NSViewController {
    
    /// Return a new instance of a HXWeekBox based on the nib template.
    static func instance(withNumber num: Int) -> HXWeekBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXWeekDividerBox", owner: LectureViewController(), topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXWeekBox}).first as? HXWeekBox {
            newBox.initialize(weekNumber: num)
            return newBox
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
