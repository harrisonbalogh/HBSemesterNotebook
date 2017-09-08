//
//  SchedulerDrawTimeButton.swift
//  HXNotes
//
//  Created by Harrison Balogh on 9/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SchedulerDrawTimeButton: NSButton {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if !NSGraphicsContext.current()!.isDrawingToScreen {
            let bezPath = NSBezierPath(rect: NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
            NSColor.white.setFill()
            bezPath.fill()
        }
    }
    
}
