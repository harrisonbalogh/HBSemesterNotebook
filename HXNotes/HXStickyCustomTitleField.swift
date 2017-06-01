//
//  HXStickycustomTitleField.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/29/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXStickyCustomTitleField: NSTextField {

    var parentController: EditorViewController!
    
    var isFocused = false
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        isFocused = true
        Swift.print("StickyHeaderCustomTitle gaining focus.")
        parentController.notifyCustomTitleStartEditing()
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        isFocused = false
        Swift.print("StickyHeaderCustomTitle losing focus.")
        return true
    }
}
