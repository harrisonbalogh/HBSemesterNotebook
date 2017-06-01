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
    
    func initialize(target: AnyObject?, action: Selector?) {
        
        // Initialize child elements
        for v in self.subviews {
            switch v.identifier! {
            case "add_button_id":
                (v as! NSButton).target = target
                (v as! NSButton).action = action
            default: continue
            }
        }
    }
}
