//
//  SplitViewContent.swift
//  HXNotes
//
//  Created by Harrison Balogh on 9/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SplitViewContent: NSView {
    
    override func printView(_ sender: Any?) {
        let printInfo = NSPrintInfo()
        printInfo.bottomMargin = 0
        printInfo.topMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true
        printInfo.orientation = .landscape
        printInfo.scalingFactor = 0.8
        
        let printOp = NSPrintOperation(view: self, printInfo: printInfo)
        printOp.canSpawnSeparateThread = true
        
        printOp.runModal(for: NSApp.keyWindow!, delegate: nil, didRun: nil, contextInfo: nil)
    }
    
}
