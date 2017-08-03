//
//  MenuBarPopover.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/14/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MenuBarPopover: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func action_quitButton(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
}
