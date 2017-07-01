//
//  HXAbsentLectureBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/26/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXAbsentLectureBox: NSBox {

    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance() -> HXAbsentLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXAbsentLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXAbsentLectureBox}).first as? HXAbsentLectureBox {
            return newBox
        }
        return nil
    }
}
