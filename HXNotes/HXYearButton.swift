//
//  HXYearButton.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXYearButton: NSButton {
    
    private(set) var selected = false
    
    required init(withYear year: Int) {
        super.init(frame: .zero)
        
        self.tag = year
        self.title = "\(year)"
        self.isBordered = false
        self.alphaValue = 0.5
        
        self.widthAnchor.constraint(equalToConstant: 68).isActive = true
        self.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func select() {
        selected = true
        self.font = NSFont.boldSystemFont(ofSize: 12)
        self.alphaValue = 1
    }
    
    func deselect() {
        selected = false
        self.font = NSFont.systemFont(ofSize: 12)
        self.alphaValue = 0.5
    }
}
