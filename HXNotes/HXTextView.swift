//
//  HXTextView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXTextView: NSTextView {

    weak var parentController: LectureEditorViewController!
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
//        parentController.notifyTextViewFocus(true)
        parentController.notifyContentFocus(is: true)
        return true
    }
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
//        parentController.notifyTextViewFocus(false)
        parentController.notifyContentFocus(is: false)
        return true
    }
    
}
