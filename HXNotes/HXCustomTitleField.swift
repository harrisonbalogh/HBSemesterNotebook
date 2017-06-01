//
//  HXCustomTitleField.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/26/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCustomTitleField: NSTextField {

    var parentController: LectureViewController!
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        Swift.print("CustomTitle gaining focus.")
        parentController.notifyCustomTitleFocus(true)
        return true
    }
//    override func resignFirstResponder() -> Bool {
//        super.resignFirstResponder()
//        Swift.print("notifyCustomTitle man... false!")
//        parentController.notifyCustomTitleFocus(false)
//        return true
//    }    
}
