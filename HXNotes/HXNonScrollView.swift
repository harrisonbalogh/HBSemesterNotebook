//
//  HXNonScrollView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/14/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXNonScrollView: NSScrollView {
    
    var parentController: LectureViewController!
    
    override func scrollWheel(with event: NSEvent) {
        parentController.notifyTextViewScrolling(with: event)
    }
}
