//
//  HXTextView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXTextView: NSTextView {

    var parentController: LectureViewController!
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        parentController.notifyTextViewFocus(true)
        return true
    }
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        parentController.notifyTextViewFocus(false)
        return true
    }
}
