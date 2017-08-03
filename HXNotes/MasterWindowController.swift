//
//  MasterWindowController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/1/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MasterWindowController: NSWindowController {
    
    weak var masterViewController: MasterViewController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window!.titleVisibility = .hidden
        self.window!.titlebarAppearsTransparent = true
        self.window!.styleMask.insert(.fullSizeContentView)
        self.window!.contentView?.wantsLayer = true
        
        
        if let mVC = self.contentViewController as? MasterViewController {
            masterViewController = mVC
        }
    }
    

    @IBAction func actionTemp_sidebar(_ sender: NSButton) {
        if sender.state == NSOnState {
            masterViewController.sideBarShown(true)
        } else {
            masterViewController.sideBarShown(false)
        }
    }
    
}
