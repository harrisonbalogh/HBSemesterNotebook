//
//  HXResizingTextView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/12/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXResizingTextView: NSTextView {
    
    var parentController: LectureViewController!
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        parentController.notifyTextChange()
    }
}
