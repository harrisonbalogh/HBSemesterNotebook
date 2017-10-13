//
//  DocumentsScrollView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 10/7/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class DocumentsScrollView: NSScrollView {
    
    var documentDropDelegate: DocumentsDropDelegate?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        if let files = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String] {
            
            for file in files {
                documentDropDelegate?.dropDocument(at: file)
            }
        }
        
        return true
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        NSCursor.dragCopy().set()
        return NSDragOperation.copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        Swift.print("DraggingExited")
        NSCursor.pop()
    }
    
}
