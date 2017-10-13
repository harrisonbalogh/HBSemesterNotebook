//
//  MasterWindowController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/1/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MasterWindowController: NSWindowController, NSWindowDelegate {
    
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
        
        self.window?.delegate = self
    }
    
    var retainWasSidebarOnly = false
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        retainWasSidebarOnly = masterViewController.isSidebarOnly
        masterViewController.isSidebarOnly = false
        masterViewController.sidebarOnlyButton.isHidden = true
        masterViewController.sidebarOnlyButton.isEnabled = false
        masterViewController.collapseTitlebar()
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        masterViewController.sidebarOnlyButton.isHidden = false
        masterViewController.sidebarOnlyButton.isEnabled = true
        masterViewController.revealTitlebar()
    }
    func windowDidExitFullScreen(_ notification: Notification) {
        masterViewController.isSidebarOnly = retainWasSidebarOnly
    }
}
