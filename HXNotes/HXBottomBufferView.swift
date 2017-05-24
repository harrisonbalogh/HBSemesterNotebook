//
//  HXBottomBufferView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/21/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXBottomBufferView: NSBox {
    
    var owner: EditorViewController!
    
    func initialize(owner: EditorViewController) {
        self.owner = owner
    }
    
    override func mouseDown(with event: NSEvent) {
        owner.bottomBufferClicked()
    }
}
