//
//  CourseLabel.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseLabel: NSTextField {
    
    override func mouseDown(with event: NSEvent) {
        self.isSelectable = true
        self.isEditable = true
        self.becomeFirstResponder()
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Override drag
    }
    
}
