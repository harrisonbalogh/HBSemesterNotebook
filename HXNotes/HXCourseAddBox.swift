//
//  HXCourseAddBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/31/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseAddBox: NSView {
    
    /// Return a new instance of a HXCourseAddBox based on the nib template.
    static func instance(target: AnyObject?, action: Selector?) -> HXCourseAddBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseAddBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseAddBox}).first as? HXCourseAddBox {
            newBox.initialize(target: target, action: action)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var addCourseButton: NSButton!
    
    func initialize(target: AnyObject?, action: Selector?) {
        
        addCourseButton.target = target
        addCourseButton.action = action

    }
}
