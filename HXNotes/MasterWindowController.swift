//
//  MasterWindowController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/1/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MasterWindowController: NSWindowController {
    
    @IBOutlet weak var timelineButton_discloseTimeline: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window!.titleVisibility = NSWindowTitleVisibility.hidden
        
        
    }
    
    @IBAction func action_discloseTimeline(_ sender: Any) {
        if let controller = self.contentViewController as? MasterViewController {
            controller.discloseTimeline(timelineButton_discloseTimeline.state)
        }
    }
}
